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
    """
    Distribui um valor em n parcelas iguais sem erros de arredondamento.
    
    Implementa uma distribuição de valores que garante:
    1. Todas as parcelas exceto a última têm o mesmo valor (arredondado para 2 casas decimais)
    2. A última parcela compensa qualquer diferença de arredondamento
    3. A soma exata de todas as parcelas é igual ao valor total original
    """
    if n_installments <= 0:
        return []
    
    if n_installments == 1:
        return [total_value]
        
    # Valor por parcela com precisão alta para cálculos intermediários
    base_value = total_value / n_installments
    
    # Arredondar para 2 casas decimais para as n-1 primeiras parcelas
    parcels = [round(base_value, 2) for _ in range(n_installments - 1)]
    
    # Calcular o valor da última parcela para compensar diferenças de arredondamento
    last_parcel = round(total_value - sum(parcels), 2)
    parcels.append(last_parcel)
    
    # Verificação de garantia (a soma deve ser exatamente igual ao total)
    assert abs(sum(parcels) - total_value) < 0.0001, "Erro na distribuição de valores"
    
    return parcels

def needs_installment_update(conn, transaction_id, total_value, total_fees) -> bool:
    """
    Verifica se as parcelas de uma transação precisam ser atualizadas baseado no valor total.
    
    Retorna True se:
    1. Não existirem parcelas para a transação
    2. A soma das parcelas existentes for diferente do valor total da transação
    3. O número de parcelas existentes for insuficiente
    
    A verificação leva em conta uma margem de tolerância para erros de arredondamento.
    """
    query = """
        SELECT 
            COUNT(*) as parcelas_count,
            COALESCE(SUM(creditcard_installments_base_value), 0) as soma_base,
            COALESCE(SUM(creditcard_installments_fees_taxes), 0) as soma_taxas
        FROM transactions.creditcard_installments
        WHERE creditcard_installments_transaction_id = %s
    """
    
    query_total_count = """
        SELECT creditcard_transactions_installment_count
        FROM transactions.creditcard_transactions
        WHERE creditcard_transactions_id = %s
    """
    
    with conn.cursor() as cur:
        # Verificar parcelas existentes
        cur.execute(query, (transaction_id,))
        result = cur.fetchone()
        parcelas_count, soma_base, soma_taxas = result
        
        # Verificar número total esperado de parcelas
        cur.execute(query_total_count, (transaction_id,))
        total_count_result = cur.fetchone()
        if total_count_result is None:
            # Transação não encontrada
            logger.warning(f"Transação {transaction_id} não encontrada ao verificar necessidade de atualização.")
            return False
        
        total_expected_count = total_count_result[0]
        
        # Se não existem parcelas, precisa criar
        if parcelas_count == 0:
            return True
        
        # Se o número de parcelas é insuficiente, precisa completar
        if parcelas_count < total_expected_count:
            return True
        
        # Margem de tolerância para erros de arredondamento (1 centavo por parcela)
        tolerance = 0.01 * parcelas_count
        
        # Verificar diferença entre valor total e soma das parcelas
        value_difference = abs(total_value - soma_base)
        fees_difference = abs(total_fees - soma_taxas)
        
        # Se a diferença for maior que a tolerância, precisa atualizar
        if value_difference > tolerance or fees_difference > tolerance:
            logger.info(f"Transação {transaction_id} precisa de atualização. " 
                       f"Diferença de valor: {value_difference}, diferença de taxas: {fees_difference}")
            return True
        
        return False

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
          AND (
              -- Transações que não têm parcelas ou têm número insuficiente
              NOT EXISTS (
                  SELECT 1 
                  FROM transactions.creditcard_installments ci
                  WHERE ci.creditcard_installments_transaction_id = ct.creditcard_transactions_id
                  GROUP BY ci.creditcard_installments_transaction_id
                  HAVING COUNT(*) = ct.creditcard_transactions_installment_count
              )
              OR 
              -- Transações que têm diferença de valor entre a soma das parcelas e o valor total
              EXISTS (
                  SELECT 1
                  FROM (
                      SELECT 
                          COUNT(*) as parcelas_count,
                          COALESCE(SUM(ci.creditcard_installments_base_value), 0) as soma_base,
                          COALESCE(SUM(ci.creditcard_installments_fees_taxes), 0) as soma_taxas
                      FROM transactions.creditcard_installments ci
                      WHERE ci.creditcard_installments_transaction_id = ct.creditcard_transactions_id
                      GROUP BY ci.creditcard_installments_transaction_id
                  ) as sums
                  WHERE 
                      sums.parcelas_count = ct.creditcard_transactions_installment_count
                      AND (
                          ABS(sums.soma_base - ct.creditcard_transactions_base_value) > (0.01 * sums.parcelas_count)
                          OR ABS(sums.soma_taxas - ct.creditcard_transactions_fees_taxes) > (0.01 * sums.parcelas_count)
                      )
              )
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
          AND (
              -- Transações que não têm parcelas ou têm número insuficiente
              NOT EXISTS (
                  SELECT 1 
                  FROM transactions.creditcard_installments ci
                  WHERE ci.creditcard_installments_transaction_id = ct.creditcard_transactions_id
                  GROUP BY ci.creditcard_installments_transaction_id
                  HAVING COUNT(*) = ct.creditcard_transactions_installment_count
              )
              OR 
              -- Transações que têm diferença de valor entre a soma das parcelas e o valor total
              EXISTS (
                  SELECT 1
                  FROM (
                      SELECT 
                          COUNT(*) as parcelas_count,
                          COALESCE(SUM(ci.creditcard_installments_base_value), 0) as soma_base,
                          COALESCE(SUM(ci.creditcard_installments_fees_taxes), 0) as soma_taxas
                      FROM transactions.creditcard_installments ci
                      WHERE ci.creditcard_installments_transaction_id = ct.creditcard_transactions_id
                      GROUP BY ci.creditcard_installments_transaction_id
                  ) as sums
                  WHERE 
                      sums.parcelas_count = ct.creditcard_transactions_installment_count
                      AND (
                          ABS(sums.soma_base - ct.creditcard_transactions_base_value) > (0.01 * sums.parcelas_count)
                          OR ABS(sums.soma_taxas - ct.creditcard_transactions_fees_taxes) > (0.01 * sums.parcelas_count)
                      )
              )
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
    Busca faturas existentes para os períodos necessários.
    
    Em vez de criar faturas automaticamente, apenas identifica quais já existem e 
    alerta sobre as ausentes. Isso garante que parcelas só serão associadas a faturas
    previamente criadas e configuradas corretamente.
    
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
            creditcard_invoices_id,
            creditcard_invoices_status
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
        
        # Determinar quais faturas estão ausentes
        missing_periods = [p for p in periods_to_check if p not in invoices_map]
        
        if missing_periods:
            missing_info = ", ".join([f"Cartão: {p[0]}, Período: {p[1]}-{p[2]:02d}" for p in missing_periods[:5]])
            if len(missing_periods) > 5:
                missing_info += f" e mais {len(missing_periods) - 5} períodos"
                
            logger.warning(f"Não foram encontradas {len(missing_periods)} faturas necessárias: {missing_info}. "
                          f"Execute o script manage_invoices.py para criar as faturas ausentes.")
    
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
    
    # Calcular valores por parcela (distribuição proporcional)
    base_values = distribute_value(total_value, total_installments)
    
    # Distribuir as taxas (se houver)
    fees_values = []
    if total_fees > 0:
        fees_values = distribute_value(total_fees, total_installments)
    else:
        fees_values = [0] * total_installments
    
    # Descrição base para as parcelas
    transaction_desc = transaction['creditcard_transactions_description'] or "Compra parcelada"
    
    installments_to_create = []
    
    # Primeiro, verificar se todas as faturas necessárias existem
    all_invoices_exist = True
    missing_invoice_periods = []
    
    for i in range(1, total_installments + 1):
        if i in transaction_existing:
            continue  # Pular se já existe
            
        months_to_add = i - 1
        target_date = date(initial_year, initial_month_num, 1) + relativedelta(months=months_to_add)
        
        # Verificar se existe fatura para este período
        period_key = (transaction['creditcard_transactions_user_card_id'], target_date.year, target_date.month)
        
        if period_key not in invoices:
            all_invoices_exist = False
            missing_invoice_periods.append(f"{target_date.year}-{target_date.month:02d}")
    
    # Se faltam faturas, registrar o problema
    if not all_invoices_exist:
        missing_periods_str = ", ".join(missing_invoice_periods[:5])
        if len(missing_invoice_periods) > 5:
            missing_periods_str += f" e mais {len(missing_invoice_periods) - 5} períodos"
            
        logger.warning(f"Transação {transaction_id}: faltam faturas para os períodos {missing_periods_str}. "
                     f"Parcelas não serão criadas para estes períodos.")
    
    # Criar cada parcela que ainda não existe (e que tenha fatura)
    for i in range(1, total_installments + 1):
        # Pular se a parcela já existe
        if i in transaction_existing:
            continue
        
        # Calcular mês e ano desta parcela
        months_to_add = i - 1  # Parcela 1 é no mês inicial
        target_date = date(initial_year, initial_month_num, 1) + relativedelta(months=months_to_add)
        
        target_month_enum = get_month_enum_from_date(target_date)
        target_year = target_date.year
        
        # Determinar o valor desta parcela
        base_value = base_values[i-1]
        fees_value = fees_values[i-1]
        
        # Gerar descrição específica para esta parcela
        observations = f"{transaction_desc} - Parcela {i}/{total_installments}"
        
        # Obter ID da fatura para este período
        period_key = (transaction['creditcard_transactions_user_card_id'], target_year, target_date.month)
        invoice_id = invoices.get(period_key)
        
        # Se não temos uma fatura, pulamos esta parcela
        if not invoice_id:
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
            # Verificar se a parcela já existe
            if i+1 in existing_installments.get(tx['creditcard_transactions_id'], {}):
                continue
                
            target_date = date(initial_year, initial_month_num, 1) + relativedelta(months=i)
            period_key = (card_id, target_date.year, target_date.month)
            
            # Armazenar informação do período
            if period_key not in required_invoice_periods:
                required_invoice_periods[period_key] = {
                    'card_id': card_id,
                    'year': target_date.year,
                    'month': target_date.month
                }
    
    # Buscar faturas existentes para todos os períodos necessários
    invoices_map = find_or_create_invoices(conn, required_invoice_periods)
    
    # Preparar todas as parcelas para inserção
    all_installments_to_create = []
    
    for tx in batch_transactions:
        # Verificar se esta transação precisa de atualização de parcelas
        if not needs_installment_update(conn, 
                                      tx['creditcard_transactions_id'], 
                                      tx['creditcard_transactions_base_value'], 
                                      tx['creditcard_transactions_fees_taxes']):
            continue
            
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