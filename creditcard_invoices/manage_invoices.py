import os
import psycopg2
import psycopg2.extras
import random
import logging
import math
from datetime import datetime, timedelta, date
from dateutil.relativedelta import relativedelta
import pytz
import holidays
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

lookahead_months = 24
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

def generate_invoice_id() -> str:
    """Gera um ID único no formato NNN-NNN-NNN-NNN-NNN-F."""
    parts = [f"{random.randint(0, 999):03d}" for _ in range(5)]
    return "-".join(parts) + "-F"

def is_business_day(target_date: date, holidays_obj) -> bool:
    """Verifica se a data é um dia útil (não fim de semana nem feriado)."""
    if target_date.weekday() >= 5:
        return False
    if target_date in holidays_obj:
        return False
    return True

def get_next_business_day(target_date: date, holidays_obj) -> date:
    """Retorna a data fornecida ou o próximo dia útil subsequente."""
    adjusted_date = target_date
    while not is_business_day(adjusted_date, holidays_obj):
        adjusted_date += timedelta(days=1)
    return adjusted_date

def calculate_invoice_dates(card_details: dict, target_year: int, target_month: int, last_closing_date, holidays_obj) -> dict:
    """
    Calcula as datas de abertura, fechamento e vencimento de uma fatura.
    """
    due_day = card_details['user_creditcards_due_day']
    days_between_due_closing = card_details['user_creditcards_closing_day']
    postpone = card_details.get('creditcards_postpone_due_date_to_business_day', True)

    try:
        nominal_due_date = date(target_year, target_month, due_day)
    except ValueError:
        last_day_of_month = (date(target_year, target_month, 1) + relativedelta(months=1) - timedelta(days=1)).day
        logger.warning(f"Dia de vencimento {due_day} inválido para {target_year}-{target_month:02d} para user_card {card_details['user_creditcards_id']}. Usando último dia: {last_day_of_month}.")
        nominal_due_date = date(target_year, target_month, last_day_of_month)

    effective_due_date = get_next_business_day(nominal_due_date, holidays_obj)
    reference_date_for_closing = effective_due_date if postpone else nominal_due_date
    closing_date = reference_date_for_closing - timedelta(days=days_between_due_closing)

    if last_closing_date:
        opening_date = last_closing_date + timedelta(days=1)
    else:
        estimated_previous_closing = closing_date - relativedelta(months=1)
        opening_date = estimated_previous_closing + timedelta(days=1)

    return {
        "opening": opening_date,
        "closing": closing_date,
        "due": effective_due_date
    }

# --- Operações com o banco de dados ---

def fetch_all_card_ids(conn) -> list:
    """Busca todos os IDs de cartões de crédito dos usuários."""
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute("SELECT user_creditcards_id FROM public.user_creditcards ORDER BY user_creditcards_id;")
        rows = cur.fetchall()
    return [row['user_creditcards_id'] for row in rows]

def fetch_card_details(cursor, card_ids_batch: list) -> list:
    """Busca detalhes dos cartões de crédito de um lote."""
    if not card_ids_batch:
        return []
    try:
        query = """
            SELECT
                uc.user_creditcards_id,
                uc.user_creditcards_user_id,
                uc.user_creditcards_creditcard_id,
                uc.user_creditcards_closing_day,
                uc.user_creditcards_due_day,
                uc.user_creditcards_status,
                cc.creditcards_postpone_due_date_to_business_day
            FROM public.user_creditcards uc
            JOIN public.creditcards cc ON uc.user_creditcards_creditcard_id = cc.creditcards_id
            WHERE uc.user_creditcards_id = ANY(%s);
        """
        cursor.execute(query, (list(card_ids_batch),))
        return cursor.fetchall()
    except psycopg2.Error as e:
        logger.error(f"Erro ao buscar detalhes do lote de user_creditcards: {e}")
        return []

def fetch_existing_invoices(cursor, card_ids_batch: list, start_period_str: str, end_period_str: str) -> dict:
    """Busca faturas existentes para o lote de cartões no período."""
    invoices = {}
    if not card_ids_batch:
        return invoices
    try:
        query = """
            SELECT
                creditcard_invoices_id,
                creditcard_invoices_user_creditcard_id,
                creditcard_invoices_statement_period,
                creditcard_invoices_opening_date,
                creditcard_invoices_closing_date,
                creditcard_invoices_due_date,
                creditcard_invoices_status,
                creditcard_invoices_amount,
                creditcard_invoices_file_url
            FROM public.creditcard_invoices
            WHERE creditcard_invoices_user_creditcard_id = ANY(%s)
              AND creditcard_invoices_statement_period >= %s
              AND creditcard_invoices_statement_period <= %s;
        """
        cursor.execute(query, (list(card_ids_batch), start_period_str, end_period_str))
        for row in cursor.fetchall():
            key = (row['creditcard_invoices_user_creditcard_id'], row['creditcard_invoices_statement_period'])
            invoices[key] = row
        return invoices
    except psycopg2.Error as e:
        logger.error(f"Erro ao buscar faturas existentes do lote: {e}")
        return {}

def execute_db_changes(cursor, inserts: list, updates: list, deletes: set, now_brt: datetime):
    """Executa operações de inserção, atualização e exclusão em lote no banco de dados."""
    try:
        if deletes:
            delete_query = "DELETE FROM public.creditcard_invoices WHERE creditcard_invoices_id = ANY(%s);"
            cursor.execute(delete_query, (list(deletes),))
            logger.info(f"{cursor.rowcount} faturas marcadas para exclusão (serão efetivadas no commit).")

        if inserts:
            insert_query = """
                INSERT INTO public.creditcard_invoices (
                    creditcard_invoices_id, creditcard_invoices_user_creditcard_id,
                    creditcard_invoices_user_id, creditcard_invoices_creation_datetime,
                    creditcard_invoices_opening_date, creditcard_invoices_closing_date,
                    creditcard_invoices_due_date, creditcard_invoices_statement_period,
                    creditcard_invoices_amount, creditcard_invoices_paid_amount,
                    creditcard_invoices_payment_date, creditcard_invoices_status,
                    creditcard_invoices_file_url, creditcard_invoices_last_update
                ) VALUES %s;
            """
            values_to_insert = [
                (
                    inv['creditcard_invoices_id'], inv['creditcard_invoices_user_creditcard_id'],
                    inv['creditcard_invoices_user_id'], inv['creditcard_invoices_creation_datetime'],
                    inv['creditcard_invoices_opening_date'], inv['creditcard_invoices_closing_date'],
                    inv['creditcard_invoices_due_date'], inv['creditcard_invoices_statement_period'],
                    inv['creditcard_invoices_amount'], inv['creditcard_invoices_paid_amount'],
                    inv['creditcard_invoices_payment_date'], inv['creditcard_invoices_status'],
                    inv['creditcard_invoices_file_url'], inv['creditcard_invoices_last_update']
                ) for inv in inserts
            ]
            psycopg2.extras.execute_values(cursor, insert_query, values_to_insert)
            logger.info(f"{len(values_to_insert)} faturas marcadas para inserção.")

        if updates:
            update_query = """
                UPDATE public.creditcard_invoices AS inv
                SET
                    creditcard_invoices_opening_date = data.opening_dt,
                    creditcard_invoices_closing_date = data.closing_dt,
                    creditcard_invoices_due_date = data.due_dt,
                    creditcard_invoices_last_update = data.last_updt
                FROM (VALUES %s) AS data(invoice_id, opening_dt, closing_dt, due_dt, last_updt)
                WHERE inv.creditcard_invoices_id = data.invoice_id
                  AND inv.creditcard_invoices_status = 'Aberta'::public.invoice_status
                  AND inv.creditcard_invoices_file_url IS NULL;
            """
            values_to_update = [
                (
                    upd['creditcard_invoices_id'],
                    upd['creditcard_invoices_opening_date'],
                    upd['creditcard_invoices_closing_date'],
                    upd['creditcard_invoices_due_date'],
                    now_brt
                ) for upd in updates
            ]
            psycopg2.extras.execute_values(cursor, update_query, values_to_update, template="(%s, %s, %s, %s, %s)")
            logger.info(f"{len(values_to_update)} faturas marcadas para atualização.")

    except psycopg2.Error as e:
        logger.error(f"Erro durante a preparação das operações de banco no lote: {e}")
        raise

# --- Lógica de negócio ---

def calculate_batch_size(total_cards: int) -> int:
    """Calcula o tamanho do lote como 5% do total, respeitando mínimo de 250 e máximo de 1250."""
    size = max(250, min(1250, int(total_cards * 0.05)))
    logger.info(f"Tamanho do lote definido para {size} ({min(size/total_cards,1)*100:.2f}% do total de {total_cards}).")
    return size

def prepare_holidays(now_brt: datetime, months_ahead: int):
    """Prepara e retorna objeto de feriados nacionais para o período de interesse."""
    current_year = now_brt.year
    years_for_holidays = list(range(current_year - 1, current_year + (months_ahead // 12) + 2))
    br_holidays = holidays.BR(years=years_for_holidays)
    logger.info(f"Cache de feriados preparado para anos: {years_for_holidays}")
    return br_holidays

def prepare_changes_for_batch(
    card_details_batch: list,
    existing_invoices: dict,
    start_period_dt: date,
    now_brt: datetime,
    months_ahead: int,
    br_holidays
):
    """Processa um lote de cartões e determina as mudanças necessárias em faturas."""
    inserts_batch = []
    updates_batch_dict = {}
    deletes_batch_set = set()

    for card in card_details_batch:
        card_id = card['user_creditcards_id']
        user_id = card['user_creditcards_user_id']
        is_active = card['user_creditcards_status']

        if not is_active:
            for key, invoice_data in existing_invoices.items():
                inv_card_id, _ = key
                if inv_card_id == card_id:
                    due_date_obj = invoice_data.get('creditcard_invoices_due_date')
                    amount = invoice_data.get('creditcard_invoices_amount', 0.00)
                    if due_date_obj and due_date_obj > now_brt.date() and math.isclose(amount or 0.00, 0.0, abs_tol=0.01):
                        deletes_batch_set.add(invoice_data['creditcard_invoices_id'])
            continue

        last_closing_date = None
        past_periods = sorted([
            p for uc_id, p in existing_invoices.keys()
            if uc_id == card_id and p < start_period_dt.strftime('%Y-%m')
        ])
        if past_periods:
            last_period_key = (card_id, past_periods[-1])
            last_closing_date = existing_invoices[last_period_key].get('creditcard_invoices_closing_date')

        curr_period_date = start_period_dt
        for _ in range(months_ahead):
            target_year = curr_period_date.year
            target_month = curr_period_date.month
            statement_period = curr_period_date.strftime('%Y-%m')

            try:
                calculated_dates = calculate_invoice_dates(
                    card, target_year, target_month, last_closing_date, br_holidays
                )
                opening_dt = calculated_dates["opening"]
                closing_dt = calculated_dates["closing"]
                due_dt = calculated_dates["due"]

                if closing_dt:
                    last_closing_date = closing_dt

            except Exception as e:
                logger.error(f"Erro no cálculo de datas para user_card {card_id} período {statement_period}: {e}")
                curr_period_date += relativedelta(months=1)
                continue

            invoice_key = (card_id, statement_period)
            existing_invoice_data = existing_invoices.get(invoice_key)

            if existing_invoice_data is None:
                new_id = generate_invoice_id()
                inserts_batch.append({
                    'creditcard_invoices_id': new_id,
                    'creditcard_invoices_user_creditcard_id': card_id,
                    'creditcard_invoices_user_id': user_id,
                    'creditcard_invoices_creation_datetime': now_brt,
                    'creditcard_invoices_opening_date': opening_dt,
                    'creditcard_invoices_closing_date': closing_dt,
                    'creditcard_invoices_due_date': due_dt,
                    'creditcard_invoices_statement_period': statement_period,
                    'creditcard_invoices_amount': 0.00,
                    'creditcard_invoices_paid_amount': 0.00,
                    'creditcard_invoices_payment_date': due_dt,
                    'creditcard_invoices_status': 'Aberta',
                    'creditcard_invoices_file_url': None,
                    'creditcard_invoices_last_update': now_brt
                })
            else:
                status_val = existing_invoice_data.get('creditcard_invoices_status')
                if (str(status_val) == 'Aberta'
                        and existing_invoice_data.get('creditcard_invoices_file_url') is None
                        and (existing_invoice_data.get('creditcard_invoices_opening_date') != opening_dt or
                             existing_invoice_data.get('creditcard_invoices_closing_date') != closing_dt or
                             existing_invoice_data.get('creditcard_invoices_due_date') != due_dt)):
                    invoice_id_to_update = existing_invoice_data['creditcard_invoices_id']
                    if invoice_id_to_update not in updates_batch_dict:
                        updates_batch_dict[invoice_id_to_update] = {
                            'creditcard_invoices_id': invoice_id_to_update,
                            'creditcard_invoices_opening_date': opening_dt,
                            'creditcard_invoices_closing_date': closing_dt,
                            'creditcard_invoices_due_date': due_dt,
                            'creditcard_invoices_last_update': now_brt
                        }
            curr_period_date += relativedelta(months=1)

    return inserts_batch, list(updates_batch_dict.values()), deletes_batch_set

def process_batches(
    conn,
    all_card_ids: list,
    batch_size: int,
    months_ahead: int,
    br_holidays,
    now_brt: datetime
):
    """Processa todos os lotes de cartões, realizando as operações de faturas necessárias."""
    start_period_dt = now_brt.replace(day=1).date()
    end_period_dt = (start_period_dt + relativedelta(months=months_ahead - 1))
    start_period_str = start_period_dt.strftime('%Y-%m')
    end_period_str = end_period_dt.strftime('%Y-%m')
    logger.info(f"Período de análise das faturas: {start_period_str} a {end_period_str}")

    total_batches = (len(all_card_ids) + batch_size - 1) // batch_size

    for batch_index, start in enumerate(range(0, len(all_card_ids), batch_size), start=1):
        t0 = time.time()
        batch_ids = all_card_ids[start:start + batch_size]
        logger.info(f"Processando lote {batch_index}/{total_batches} de cartões (tamanho: {len(batch_ids)})...")

        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            card_details = fetch_card_details(cur, batch_ids)
            if not card_details:
                logger.warning(f"Nenhum detalhe encontrado para o lote de user_card_ids: {batch_ids}")
                continue

            existing_invoices = fetch_existing_invoices(cur, batch_ids, start_period_str, end_period_str)
            inserts, updates, deletes = prepare_changes_for_batch(
                card_details, existing_invoices, start_period_dt, now_brt, months_ahead, br_holidays
            )

            if inserts or updates or deletes:
                execute_db_changes(cur, inserts, updates, deletes, now_brt)
                logger.info(f"Mudanças para o lote {batch_index} preparadas para commit.")
            else:
                logger.info(f"Nenhuma mudança necessária para o lote {batch_index}.")

        conn.commit()
        logger.info(f"Lote {batch_index} commitado com sucesso em {time.time() - t0:.2f}s.")

    logger.info("Todos os lotes foram processados.")

# --- Execução principal ---

def main():
    """Função principal que executa o processo de gerenciamento de faturas."""
    logger.info("Iniciando script de gerenciamento de faturas...")
    conn = None
    try:
        conn = get_db_connection()
        now_brt = datetime.now(db_timezone)

        all_card_ids = fetch_all_card_ids(conn)
        total_cards = len(all_card_ids)
        if total_cards == 0:
            logger.info("Nenhum cartão encontrado para processar.")
            return

        batch_size = calculate_batch_size(total_cards)
        br_holidays = prepare_holidays(now_brt, lookahead_months)

        process_batches(
            conn,
            all_card_ids,
            batch_size,
            lookahead_months,
            br_holidays,
            now_brt
        )

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