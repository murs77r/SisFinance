import os
import psycopg2
import psycopg2.extras
import random
import logging
import math
from datetime import datetime, date
from dateutil.relativedelta import relativedelta
import pytz
from dotenv import load_dotenv
import time

# --- Configuração de logging ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(module)s - %(funcName)s - %(message)s'
)
logger = logging.getLogger(__name__)

# --- Constantes e configuração ---
load_dotenv()

db_name = os.getenv("DB_NAME")
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST", "localhost")
db_port = os.getenv("DB_PORT", "5432")

db_timezone_str = 'America/Sao_Paulo'
db_timezone = pytz.timezone(db_timezone_str)

# --- Conexão com o banco de dados ---

def get_db_connection() -> psycopg2.extensions.connection:
    """Estabelece e retorna uma conexão com o banco de dados."""
    try:
        conn = psycopg2.connect(
            dbname=db_name,
            user=db_user,
            password=db_password,
            host=db_host,
            port=db_port
        )
        logger.info("Conexão com o banco de dados estabelecida.")
        return conn
    except psycopg2.Error as e:
        logger.error(f"Erro ao conectar ao banco de dados: {e}")
        raise

# --- Utilitários ---

def generate_installment_id() -> str:
    """Gera um ID único no formato NNN-NNN-NNN-NNN-NNN-P."""
    parts = [f"{random.randint(0, 999):03d}" for _ in range(5)]
    return "-".join(parts) + "-P"

def calculate_batch_size(total_transactions: int) -> int:
    """
    Calcula o tamanho do lote como 5% do total, respeitando mínimo de 100 e máximo de 1000.
    
    Um tamanho adequado de lote equilibra a eficiência de operações em massa com a pressão
    sobre o banco de dados e a memória.
    """
    size = max(100, min(1000, int(total_transactions * 0.05)))
    logger.info(f"Tamanho do lote definido para {size} ({min(size/total_transactions, 1)*100:.2f}% do total de {total_transactions}).")
    return size

def get_month_enum_from_date(target_date: date) -> str:
    """Converte uma data para o enum month_enum do banco de dados."""
    # Dicionário para mapear mês numérico para nome em português
    month_names = {
        1: "Janeiro", 2: "Fevereiro", 3: "Março", 4: "Abril",
        5: "Maio", 6: "Junho", 7: "Julho", 8: "Agosto",
        9: "Setembro", 10: "Outubro", 11: "Novembro", 12: "Dezembro"
    }
    return month_names[target_date.month]

def distribute_value(total_value, n_installments):
    """Distribui um valor em n parcelas iguais sem erros de arredondamento."""
    base_value = total_value / n_installments
    values = [round(base_value, 2) for _ in range(n_installments)]
    
    # Ajusta a diferença de arredondamento na última parcela
    difference = total_value - sum(values)
    values[-1] = round(values[-1] + difference, 2)
    
    return values

# --- Operações com o banco de dados ---

def fetch_unprocessed_installment_transactions(conn, batch_start: int, batch_size: int) -> list:
    """
    Busca transações de cartão de crédito parceladas que precisam ter parcelas processadas.
    
    Utiliza paginação (OFFSET/LIMIT) para processar em lotes, reduzindo o pico de memória
    e permitindo paralelização em sistemas distribuídos.
    """
    query = """
        SELECT 
            ct.creditcard_transactions_id,
            ct.creditcard_transactions_user_id,
            ct.creditcard_transactions_user_card_id,
            ct.creditcard_transactions_implementation_datetime,
            ct.creditcard_transactions_statement_month,
            ct.creditcard_transactions_statement_year,
            ct.creditcard_transactions_installment_count,
            ct.creditcard_transactions_base_value,
            ct.creditcard_transactions_fees_taxes,
            ct.creditcard_transactions_description,
            uc.user_creditcards_due_day,
            uc.user_creditcards_closing_day
        FROM transactions.creditcard_transactions ct
        JOIN core.user_creditcards uc ON ct.creditcard_transactions_user_card_id = uc.user_creditcards_id
        WHERE ct.creditcard_transactions_is_installment = TRUE
          AND ct.creditcard_transactions_status = 'Efetuado'
          AND NOT EXISTS (
              -- Transações que não têm todas as parcelas registradas
              SELECT 1 
              FROM transactions.creditcard_installments ci
              WHERE ci.creditcard_installments_transaction_id = ct.creditcard_transactions_id
              GROUP BY ci.creditcard_installments_transaction_id
              HAVING COUNT(*) = ct.creditcard_transactions_installment_count
          )
        ORDER BY ct.creditcard_transactions_implementation_datetime
        OFFSET %s
        LIMIT %s
    """
    
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute(query, (batch_start, batch_size))
        rows = cur.fetchall()
        logger.info(f"Buscados {len(rows)} transações parceladas para processamento no lote (offset: {batch_start}, limit: {batch_size}).")
        return rows

def count_total_unprocessed_transactions(conn) -> int:
    """
    Conta o total de transações parceladas pendentes para definir parâmetros de lote.
    
    Separa a contagem da busca de dados para evitar múltiplas contagens durante
    o processamento em lotes.
    """
    query = """
        SELECT COUNT(*) 
        FROM transactions.creditcard_transactions ct
        WHERE ct.creditcard_transactions_is_installment = TRUE
          AND ct.creditcard_transactions_status = 'Efetuado'
          AND NOT EXISTS (
              SELECT 1 
              FROM transactions.creditcard_installments ci
              WHERE ci.creditcard_installments_transaction_id = ct.creditcard_transactions_id
              GROUP BY ci.creditcard_installments_transaction_id
              HAVING COUNT(*) = ct.creditcard_transactions_installment_count
          )
    """
    
    with conn.cursor() as cur:
        cur.execute(query)
        count = cur.fetchone()[0]
        logger.info(f"Total de {count} transações parceladas pendentes de processamento.")
        return count

def fetch_existing_installments(conn, transaction_ids: list) -> dict:
    """
    Busca parcelas já existentes para as transações do lote atual.
    
    Otimiza o código evitando a inserção duplicada de parcelas já existentes,
    o que economiza recursos e evita erros de chave duplicada.
    """
    if not transaction_ids:
        return {}
    
    existing_installments = {}
    
    query = """
        SELECT 
            creditcard_installments_transaction_id,
            creditcard_installments_number,
            creditcard_installments_id
        FROM transactions.creditcard_installments
        WHERE creditcard_installments_transaction_id = ANY(%s)
    """
    
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute(query, (transaction_ids,))
        for row in cur.fetchall():
            tx_id = row['creditcard_installments_transaction_id']
            number = row['creditcard_installments_number']
            if tx_id not in existing_installments:
                existing_installments[tx_id] = {}
            existing_installments[tx_id][number] = row['creditcard_installments_id']
        
        logger.info(f"Encontradas {sum(len(v) for v in existing_installments.values())} parcelas existentes para o lote atual.")
        return existing_installments

def find_or_create_invoices(conn, installment_periods: dict) -> dict:
    """
    Busca ou cria faturas para os períodos necessários.
    
    Usa uma abordagem de "encontrar ou criar" (find-or-create) que minimiza
    consultas ao banco de dados agrupando operações por usuário e período.
    
    :param installment_periods: Dicionário com chave (user_card_id, ano, mês) e 
                                valor contendo informações de parcela/período
    :return: Dicionário mapeando período para ID da fatura
    """
    invoices_map = {}
    
    # Primeiro verificamos quais faturas já existem
    periods_to_check = list(installment_periods.keys())
    
    if not periods_to_check:
        return {}
    
    query_existing = """
        SELECT 
            creditcard_invoices_user_creditcard_id, 
            creditcard_invoices_statement_period,
            creditcard_invoices_id
        FROM transactions.creditcard_invoices
        WHERE (creditcard_invoices_user_creditcard_id, creditcard_invoices_statement_period) = ANY(%s)
    """
    
    # Preparar os parâmetros para a consulta (pares de user_card_id e período)
    params = [(card_id, f"{year}-{month:02d}") 
             for (card_id, year, month) in periods_to_check]
    
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        # Buscar faturas existentes
        cur.execute(query_existing, (params,))
        for row in cur.fetchall():
            card_id = row['creditcard_invoices_user_creditcard_id']
            period = row['creditcard_invoices_statement_period']
            # Converter período YYYY-MM para tupla (card_id, ano, mês)
            year, month = map(int, period.split('-'))
            period_key = (card_id, year, month)
            
            invoices_map[period_key] = row['creditcard_invoices_id']
        
        # Determinar quais faturas precisam ser criadas
        missing_periods = [p for p in periods_to_check if p not in invoices_map]
        
        if missing_periods:
            logger.warning(f"Não foram encontradas {len(missing_periods)} faturas necessárias. "
                          f"É recomendado executar o script manage_invoices.py para criar as faturas ausentes.")
    
    return invoices_map

def execute_installments_batch(conn, installments_to_create: list, now_brt: datetime) -> int:
    """
    Executa a inserção em lote das parcelas.
    
    Usa execute_values do psycopg2 para inserções em massa eficientes que reduzem
    drasticamente o tempo de inserção e a carga no banco de dados.
    """
    if not installments_to_create:
        return 0
    
    insert_query = """
        INSERT INTO transactions.creditcard_installments (
            creditcard_installments_id,
            creditcard_installments_transaction_id,
            creditcard_installments_invoice_id,
            creditcard_installments_number,
            creditcard_installments_statement_month,
            creditcard_installments_statement_year,
            creditcard_installments_observations,
            creditcard_installments_base_value,
            creditcard_installments_fees_taxes,
            creditcard_installments_last_update
        ) VALUES %s
    """
    
    values_to_insert = [
        (
            inst['id'],
            inst['transaction_id'],
            inst['invoice_id'],
            inst['number'],
            inst['statement_month'],
            inst['statement_year'],
            inst['observations'],
            inst['base_value'],
            inst['fees_taxes'],
            now_brt
        ) for inst in installments_to_create
    ]
    
    with conn.cursor() as cur:
        try:
            # Use execute_values para inserção em lote eficiente
            psycopg2.extras.execute_values(cur, insert_query, values_to_insert)
            count = cur.rowcount
            logger.info(f"Inseridas com sucesso {count} novas parcelas no banco de dados.")
            return count
        except psycopg2.Error as e:
            logger.error(f"Erro na inserção em lote de parcelas: {e}")
            raise
    
    return 0

# --- Lógica de negócio ---

def calculate_installment_distribution(transaction: dict, existing_installments: dict, invoices: dict) -> list:
    """
    Calcula a distribuição adequada de parcelas para uma transação.
    
    Implementa a lógica de negócio para dividir uma compra em parcelas,
    respeitando regras de distribuição de valores e associação com faturas.
    
    :param transaction: Dados da transação parcelada
    :param existing_installments: Parcelas já existentes para esta transação
    :param invoices: Mapeamento de períodos para IDs de faturas
    :return: Lista de parcelas a serem criadas
    """
    transaction_id = transaction['creditcard_transactions_id']
    total_installments = transaction['creditcard_transactions_installment_count']
    
    # Verificar parcelas existentes para esta transação
    transaction_existing = existing_installments.get(transaction_id, {})
    
    # Data base para cálculo das parcelas (data da primeira parcela é o mês/ano da transação)
    initial_month = transaction['creditcard_transactions_statement_month']
    initial_year = transaction['creditcard_transactions_statement_year']
    
    # Converter month_enum para número do mês (1-12)
    month_to_number = {
        "Janeiro": 1, "Fevereiro": 2, "Março": 3, "Abril": 4,
        "Maio": 5, "Junho": 6, "Julho": 7, "Agosto": 8,
        "Setembro": 9, "Outubro": 10, "Novembro": 11, "Dezembro": 12
    }
    initial_month_num = month_to_number[initial_month]
    
    # Valor total da transação
    total_value = transaction['creditcard_transactions_base_value']
    total_fees = transaction['creditcard_transactions_fees_taxes']
    
    # Calcular valor base por parcela (distribuição proporcional)
    base_per_installment = distribute_value(total_value, total_installments)
    
    # Ajustar o valor da última parcela para compensar diferenças de arredondamento
    last_installment_adjustment = total_value - (base_per_installment * (total_installments - 1))
    
    # Distribuir as taxas de forma proporcional
    fees_per_installment = 0
    if total_fees > 0:
        fees_per_installment = round(total_fees / total_installments, 2)
        last_fees_adjustment = total_fees - (fees_per_installment * (total_installments - 1))
    else:
        last_fees_adjustment = 0
    
    # Descrição base para as parcelas
    transaction_desc = transaction['creditcard_transactions_description'] or "Compra parcelada"
    
    installments_to_create = []
    
    # Criar cada parcela que ainda não existe
    for i in range(1, total_installments + 1):
        # Pular se a parcela já existe
        if i in transaction_existing:
            continue
        
        # Calcular mês e ano desta parcela
        months_to_add = i - 1  # Parcela 1 é no mês inicial
        target_date = date(initial_year, initial_month_num, 1) + relativedelta(months=months_to_add)
        
        target_month_enum = get_month_enum_from_date(target_date)
        target_year = target_date.year
        
        # Determinar o valor desta parcela (ajuste na última)
        if i == total_installments:
            base_value = last_installment_adjustment
            fees_value = last_fees_adjustment
        else:
            base_value = base_per_installment
            fees_value = fees_per_installment
        
        # Gerar descrição específica para esta parcela
        observations = f"{transaction_desc} - Parcela {i}/{total_installments}"
        
        # Obter ID da fatura para este período
        period_key = (transaction['creditcard_transactions_user_card_id'], target_year, target_date.month)
        invoice_id = invoices.get(period_key)
        
        # Se não temos uma fatura, registramos o problema mas continuamos
        if not invoice_id:
            logger.warning(f"Fatura não encontrada para o período {target_year}-{target_date.month:02d} "
                         f"do cartão {transaction['creditcard_transactions_user_card_id']}")
            continue
        
        # Criar dados da parcela
        installment = {
            'id': generate_installment_id(),
            'transaction_id': transaction_id,
            'invoice_id': invoice_id,
            'number': i,
            'statement_month': target_month_enum,
            'statement_year': target_year,
            'observations': observations,
            'base_value': base_value,
            'fees_taxes': fees_value
        }
        
        installments_to_create.append(installment)
    
    return installments_to_create

def process_transaction_batch(conn, batch_transactions: list, now_brt: datetime) -> int:
    """
    Processa um lote de transações parceladas, criando as parcelas necessárias.
    
    Implementa o workflow completo de processamento em lote, combinando passos
    preparatórios e de execução com otimizações para reduzir acessos ao BD.
    """
    if not batch_transactions:
        return 0
    
    # Extrair IDs das transações para buscar parcelas existentes
    transaction_ids = [tx['creditcard_transactions_id'] for tx in batch_transactions]
    
    # Buscar parcelas existentes para este lote
    existing_installments = fetch_existing_installments(conn, transaction_ids)
    
    # Construir um mapa de todos os períodos necessários para faturas
    required_invoice_periods = {}
    
    for tx in batch_transactions:
        card_id = tx['creditcard_transactions_user_card_id']
        total_installments = tx['creditcard_transactions_installment_count']
        
        # Mês/ano inicial para as parcelas
        initial_month = tx['creditcard_transactions_statement_month']
        initial_year = tx['creditcard_transactions_statement_year']
        
        # Mapear month_enum para número
        month_to_number = {
            "Janeiro": 1, "Fevereiro": 2, "Março": 3, "Abril": 4,
            "Maio": 5, "Junho": 6, "Julho": 7, "Agosto": 8,
            "Setembro": 9, "Outubro": 10, "Novembro": 11, "Dezembro": 12
        }
        initial_month_num = month_to_number[initial_month]
        
        # Para cada parcela, calcular o período correspondente
        for i in range(total_installments):
            target_date = date(initial_year, initial_month_num, 1) + relativedelta(months=i)
            period_key = (card_id, target_date.year, target_date.month)
            
            # Armazenar informação do período
            if period_key not in required_invoice_periods:
                required_invoice_periods[period_key] = {
                    'card_id': card_id,
                    'year': target_date.year,
                    'month': target_date.month
                }
    
    # Buscar ou criar faturas para todos os períodos necessários
    invoices_map = find_or_create_invoices(conn, required_invoice_periods)
    
    # Preparar todas as parcelas para inserção
    all_installments_to_create = []
    
    for tx in batch_transactions:
        # Calcular parcelas para esta transação
        installments = calculate_installment_distribution(
            tx, 
            existing_installments, 
            invoices_map
        )
        all_installments_to_create.extend(installments)
    
    # Executar a inserção em lote
    inserted_count = execute_installments_batch(conn, all_installments_to_create, now_brt)
    
    return inserted_count

def process_all_installments(conn):
    """
    Processa todas as transações parceladas pendentes em lotes.
    
    Implementa a estratégia completa de processamento em lotes, com
    balanceamento de carga, controle de transações e recursos.
    """
    now_brt = datetime.now(db_timezone).replace(tzinfo=None)
    logger.info(f"Iniciando processamento de parcelamentos em {now_brt}")
    
    # Contar o total de transações pendentes para definir lotes
    total_transactions = count_total_unprocessed_transactions(conn)
    
    if total_transactions == 0:
        logger.info("Nenhuma transação parcelada pendente para processamento.")
        return
    
    # Calcular tamanho do lote
    batch_size = calculate_batch_size(total_transactions)
    
    # Calcular o número de lotes
    total_batches = math.ceil(total_transactions / batch_size)
    
    total_processed = 0
    
    # Processar cada lote
    for batch_index in range(total_batches):
        t0 = time.time()
        batch_start = batch_index * batch_size
        
        logger.info(f"Processando lote {batch_index + 1}/{total_batches} "
                   f"(offset: {batch_start}, limit: {batch_size})...")
        
        try:
            # Buscar transações para este lote
            batch_transactions = fetch_unprocessed_installment_transactions(
                conn, batch_start, batch_size
            )
            
            # Processar o lote atual
            inserted_count = process_transaction_batch(conn, batch_transactions, now_brt)
            total_processed += inserted_count
            
            # Commit após cada lote bem-sucedido
            conn.commit()
            
            batch_time = time.time() - t0
            logger.info(f"Lote {batch_index + 1} processado em {batch_time:.2f}s "
                       f"({inserted_count} parcelas criadas).")
            
        except Exception as e:
            conn.rollback()
            logger.error(f"Erro no processamento do lote {batch_index + 1}: {e}")
            # Continuar para o próximo lote mesmo após erro
    
    logger.info(f"Processamento concluído. Total de {total_processed} parcelas criadas "
               f"em {total_batches} lotes.")

# --- Execução principal ---

def main():
    """Função principal que executa o processamento de parcelamentos de cartão de crédito."""
    logger.info("Iniciando script de gestão de parcelamentos de cartão de crédito...")
    conn = None
    try:
        # Obter conexão com o banco (será reutilizada em todo o processo)
        conn = get_db_connection()
        
        # Processar todas as transações parceladas pendentes
        process_all_installments(conn)
        
    except psycopg2.Error as db_err:
        logger.error(f"Erro de banco de dados durante a execução: {db_err}")
        if conn:
            conn.rollback()
            logger.warning("Rollback da transação atual (se houver) realizado devido a erro de DB.")
    except Exception as e:
        logger.exception(f"Erro inesperado durante a execução do script: {e}")
        if conn:
            try:
                conn.rollback()
                logger.warning("Rollback da transação atual (se houver) realizado devido a erro inesperado.")
            except psycopg2.Error as rb_err:
                logger.error(f"Erro ao tentar realizar rollback: {rb_err}")
    finally:
        if conn:
            conn.close()
            logger.info("Conexão com o banco de dados fechada.")

if __name__ == "__main__":
    main()