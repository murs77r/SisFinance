-- =============================================================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS "SisFinance"
-- =============================================================================
-- Proprietário Padrão dos Objetos: "SisFinance-adm"
-- Schema Padrão: public

-- =============================================================================
-- PARTE 1: CRIAÇÃO DO BANCO DE DADOS
-- =============================================================================
DROP DATABASE IF EXISTS "SisFinance" WITH (FORCE);


CREATE DATABASE "SisFinance"
    WITH
    OWNER = "SisFinance-adm"
    ENCODING = 'UTF8'
    LC_COLLATE = 'pt_BR.UTF-8' 
    LC_CTYPE = 'pt_BR.UTF-8'   
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE "SisFinance"
    IS 'Banco de dados para o sistema de controle financeiro pessoal SisFinance, abrangendo todas as funcionalidades de gestão de contas, transações, cartões de crédito e recorrências.';

-- =============================================================================
-- FASE 0: LIMPEZA COMPLETA DE OBJETOS EXISTENTES DENTRO DO BANCO
-- =============================================================================

-- 0.1: Remover Triggers e Função
DROP TRIGGER IF EXISTS trigger_prevent_users_pk_update ON public.users;
COMMENT ON TRIGGER trigger_prevent_users_pk_update ON public.users IS 'Trigger para impedir atualização da PK em users (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_categories_pk_update ON public.categories;
COMMENT ON TRIGGER trigger_prevent_categories_pk_update ON public.categories IS 'Trigger para impedir atualização da PK em categories (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_proceedings_pk_update ON public.proceedings_saldo;
COMMENT ON TRIGGER trigger_prevent_proceedings_pk_update ON public.proceedings_saldo IS 'Trigger para impedir atualização da PK em proceedings_saldo (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_fin_inst_pk_update ON public.financial_institutions;
COMMENT ON TRIGGER trigger_prevent_fin_inst_pk_update ON public.financial_institutions IS 'Trigger para impedir atualização da PK em financial_institutions (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_acc_types_pk_update ON public.account_types;
COMMENT ON TRIGGER trigger_prevent_acc_types_pk_update ON public.account_types IS 'Trigger para impedir atualização da PK em account_types (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_inst_acc_pk_update ON public.institution_accounts;
COMMENT ON TRIGGER trigger_prevent_inst_acc_pk_update ON public.institution_accounts IS 'Trigger para impedir atualização da PK em institution_accounts (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_operators_pk_update ON public.operators;
COMMENT ON TRIGGER trigger_prevent_operators_pk_update ON public.operators IS 'Trigger para impedir atualização da PK em operators (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_user_acc_pk_update ON public.user_accounts;
COMMENT ON TRIGGER trigger_prevent_user_acc_pk_update ON public.user_accounts IS 'Trigger para impedir atualização da PK em user_accounts (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_uapix_pk_update ON public.user_accounts_pix_keys;
COMMENT ON TRIGGER trigger_prevent_uapix_pk_update ON public.user_accounts_pix_keys IS 'Trigger para impedir atualização da PK em user_accounts_pix_keys (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_recurr_saldo_pk_update ON public.recurrence_saldo;
COMMENT ON TRIGGER trigger_prevent_recurr_saldo_pk_update ON public.recurrence_saldo IS 'Trigger para impedir atualização da PK em recurrence_saldo (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_trans_saldo_pk_update ON public.transactions_saldo;
COMMENT ON TRIGGER trigger_prevent_trans_saldo_pk_update ON public.transactions_saldo IS 'Trigger para impedir atualização da PK em transactions_saldo (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_internal_transfers_pk_update ON public.internal_transfers;
COMMENT ON TRIGGER trigger_prevent_internal_transfers_pk_update ON public.internal_transfers IS 'Trigger para impedir atualização da PK em internal_transfers (será recriado).';
DROP TRIGGER IF EXISTS trigger_sync_internal_transfer ON public.internal_transfers;
COMMENT ON TRIGGER trigger_sync_internal_transfer ON public.internal_transfers IS 'Trigger para sincronizar internal_transfers com transactions_saldo (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_cc_pk_update ON public.creditcards;
COMMENT ON TRIGGER trigger_prevent_cc_pk_update ON public.creditcards IS 'Trigger para impedir atualização da PK em creditcards (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_user_cc_pk_update ON public.user_creditcards;
COMMENT ON TRIGGER trigger_prevent_user_cc_pk_update ON public.user_creditcards IS 'Trigger para impedir atualização da PK em user_creditcards (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_cc_invoice_pk_update ON public.creditcard_invoices;
COMMENT ON TRIGGER trigger_prevent_cc_invoice_pk_update ON public.creditcard_invoices IS 'Trigger para impedir atualização da PK em creditcard_invoices (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_recurr_cc_pk_update ON public.recurrence_creditcard;
COMMENT ON TRIGGER trigger_prevent_recurr_cc_pk_update ON public.recurrence_creditcard IS 'Trigger para impedir atualização da PK em recurrence_creditcard (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_cctrans_pk_update ON public.creditcard_transactions;
COMMENT ON TRIGGER trigger_prevent_cctrans_pk_update ON public.creditcard_transactions IS 'Trigger para impedir atualização da PK em creditcard_transactions (será recriado).';
DROP TRIGGER IF EXISTS trigger_prevent_ccinstall_pk_update ON public.creditcard_installments;
COMMENT ON TRIGGER trigger_prevent_ccinstall_pk_update ON public.creditcard_installments IS 'Trigger para impedir atualização da PK em creditcard_installments (será recriado).';

DROP FUNCTION IF EXISTS public.prevent_generic_pk_update();
COMMENT ON FUNCTION public.prevent_generic_pk_update() IS 'Função de Trigger genérica que impede a atualização de PKs (será recriada).';
DROP FUNCTION IF EXISTS public.prevent_transactions_pk_update_conditional();
COMMENT ON FUNCTION public.prevent_transactions_pk_update_conditional() IS 'Função de Trigger para PK de transactions_saldo (será recriada).';
DROP FUNCTION IF EXISTS public.check_operation_proceeding_compatibility(public.operation, character varying);
COMMENT ON FUNCTION public.check_operation_proceeding_compatibility(public.operation, character varying) IS 'Função de validação para CHECK constraint (será recriada).';
DROP FUNCTION IF EXISTS public.check_operation_category_compatibility(public.operation, character varying);
COMMENT ON FUNCTION public.check_operation_category_compatibility(public.operation, character varying) IS 'Função de validação para CHECK constraint (será recriada).';
DROP FUNCTION IF EXISTS public.check_procedure_category_compatibility_cc(public.creditcard_transaction_procedure, character varying);
COMMENT ON FUNCTION public.check_procedure_category_compatibility_cc(public.creditcard_transaction_procedure, character varying) IS 'Função de validação para CHECK constraint (será recriada).';
DROP FUNCTION IF EXISTS public.sync_internal_transfer_to_transactions();
COMMENT ON FUNCTION public.sync_internal_transfer_to_transactions() IS 'Função de Trigger para internal_transfers (será recriada).';

-- 0.2: Remover View
DROP VIEW IF EXISTS public.view_user_account_balances;
COMMENT ON VIEW public.view_user_account_balances IS 'Visão de saldos de conta do usuário (será recriada).';

-- 0.3: Remover Tabelas (CASCADE para garantir limpeza)
DROP TABLE IF EXISTS public.creditcard_installments CASCADE;
DROP TABLE IF EXISTS public.creditcard_transactions CASCADE;
DROP TABLE IF EXISTS public.recurrence_creditcard CASCADE;
DROP TABLE IF EXISTS public.creditcard_invoices CASCADE;
DROP TABLE IF EXISTS public.user_creditcards CASCADE;
DROP TABLE IF EXISTS public.creditcards CASCADE;
DROP TABLE IF EXISTS public.internal_transfers CASCADE;
DROP TABLE IF EXISTS public.transactions_saldo CASCADE;
DROP TABLE IF EXISTS public.recurrence_saldo CASCADE;
DROP TABLE IF EXISTS public.user_accounts_pix_keys CASCADE;
DROP TABLE IF EXISTS public.user_accounts CASCADE;
DROP TABLE IF EXISTS public.operators CASCADE;
DROP TABLE IF EXISTS public.institution_accounts CASCADE;
DROP TABLE IF EXISTS public.account_types CASCADE;
DROP TABLE IF EXISTS public.financial_institutions CASCADE;
DROP TABLE IF EXISTS public.proceedings_saldo CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- 0.4: Remover Tipos ENUM (Serão recriados)
DROP TYPE IF EXISTS public.user_type CASCADE;
DROP TYPE IF EXISTS public.user_account_status CASCADE;
DROP TYPE IF EXISTS public.operation CASCADE;
DROP TYPE IF EXISTS public.account_type CASCADE;
DROP TYPE IF EXISTS public.recurrence_status_ai CASCADE;
DROP TYPE IF EXISTS public.recurrence_type CASCADE;
DROP TYPE IF EXISTS public.recurrence_frequency CASCADE;
DROP TYPE IF EXISTS public.status CASCADE;
DROP TYPE IF EXISTS public.payment_method CASCADE;
DROP TYPE IF EXISTS public.creditcard_transaction_procedure CASCADE;
DROP TYPE IF EXISTS public.month_enum CASCADE;
DROP TYPE IF EXISTS public.invoice_status CASCADE;

-- ====================================================================
-- FASE 1: CRIAR TIPOS ENUM
-- ====================================================================
-- Tipo de Usuário
CREATE TYPE public.user_type AS ENUM ('Administrador', 'Usuário');
ALTER TYPE public.user_type OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.user_type IS 'Define os papéis possíveis para um usuário no sistema (Ex: Administrador com acesso total, Usuário com acesso limitado aos seus próprios dados).';

-- Status da Conta do Usuário
CREATE TYPE public.user_account_status AS ENUM ('Ativo', 'Inativo', 'Pendente');
ALTER TYPE public.user_account_status OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.user_account_status IS 'Define os estados possíveis para a conta de um usuário (Ex: Ativo para uso normal, Inativo para suspenso, Pendente para aguardando confirmação).';

-- Operação Financeira (Crédito/Débito)
CREATE TYPE public.operation AS ENUM ('Crédito', 'Débito');
ALTER TYPE public.operation OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.operation IS 'Define a natureza financeira de uma transação, categoria ou recorrência, indicando se representa uma entrada (Crédito) ou saída (Débito) de valor.';

-- Tipo de Conta Financeira
CREATE TYPE public.account_type AS ENUM ('Conta Corrente', 'Conta Poupança', 'Conta de Pagamento', 'Conta de Benefícios', 'Conta de Custódia');
ALTER TYPE public.account_type OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.account_type IS 'Classifica os diferentes tipos de produtos financeiros que um usuário pode possuir ou que uma instituição pode oferecer.';

-- Status da Recorrência (Ativo/Inativo)
CREATE TYPE public.recurrence_status_ai AS ENUM ('Ativo', 'Inativo');
ALTER TYPE public.recurrence_status_ai OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.recurrence_status_ai IS 'Define se um agendamento de recorrência está atualmente ativo (gerando transações) ou inativo (pausado).';

-- Tipo da Recorrência (Determinada/Indeterminada)
CREATE TYPE public.recurrence_type AS ENUM ('Determinado', 'Indeterminado');
ALTER TYPE public.recurrence_type OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.recurrence_type IS 'Define se uma recorrência possui uma data de término específica (Determinada) ou se continua indefinidamente (Indeterminada).';

-- Frequência da Recorrência
CREATE TYPE public.recurrence_frequency AS ENUM ('Semanal', 'Mensal', 'Bimestral', 'Trimestral', 'Semestral', 'Anual');
ALTER TYPE public.recurrence_frequency OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.recurrence_frequency IS 'Define a periodicidade com que uma transação recorrente deve ocorrer.';

-- Status da Transação
CREATE TYPE public.status AS ENUM ('Efetuado', 'Pendente');
ALTER TYPE public.status OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.status IS 'Define o estado de uma transação financeira, indicando se foi concluída (Efetuado) ou está aguardando realização (Pendente).';

-- Método de Pagamento de Fatura de Cartão
CREATE TYPE public.payment_method AS ENUM ('Débito Automático', 'Boleto');
ALTER TYPE public.payment_method OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.payment_method IS 'Define as formas pelas quais uma fatura de cartão de crédito pode ser liquidada.';

-- Procedimento em Fatura de Cartão
CREATE TYPE public.creditcard_transaction_procedure AS ENUM ('Crédito em Fatura', 'Débito em Fatura');
ALTER TYPE public.creditcard_transaction_procedure OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.creditcard_transaction_procedure IS 'Define a natureza de uma transação individual dentro de uma fatura de cartão de crédito (impacto no saldo da fatura).';

-- Meses do Ano
CREATE TYPE public.month_enum AS ENUM ('Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro');
ALTER TYPE public.month_enum OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.month_enum IS 'Enumeração dos meses do ano, utilizada para referência em lançamentos de fatura e parcelas.';

-- Status da Fatura de Cartão
CREATE TYPE public.invoice_status AS ENUM ('Aberta', 'Fechada', 'Paga', 'Paga Parcialmente', 'Vencida');
ALTER TYPE public.invoice_status OWNER TO "SisFinance-adm";
COMMENT ON TYPE public.invoice_status IS 'Representa os diferentes estágios do ciclo de vida de uma fatura de cartão de crédito.';

-- ====================================================================
-- FASE 2: CRIAR FUNÇÕES SQL
-- ====================================================================

-- Função Genérica para Impedir Update de PK
CREATE OR REPLACE FUNCTION public.prevent_generic_pk_update()
RETURNS TRIGGER AS $$
DECLARE
    pk_column_name TEXT;
    old_pk_value TEXT;
    new_pk_value TEXT;
BEGIN
    pk_column_name := TG_ARGV[0];
    EXECUTE format('SELECT ($1).%I::text', pk_column_name) INTO old_pk_value USING OLD;
    EXECUTE format('SELECT ($1).%I::text', pk_column_name) INTO new_pk_value USING NEW;
    IF new_pk_value IS DISTINCT FROM old_pk_value THEN
        RAISE EXCEPTION 'Atualização da chave primária "%" na tabela "%" não é permitida. Valor antigo: %, Valor novo: %',
                        pk_column_name, TG_TABLE_NAME, old_pk_value, new_pk_value;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
ALTER FUNCTION public.prevent_generic_pk_update() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.prevent_generic_pk_update() IS 'Função de Trigger genérica que impede a atualização da coluna de chave primária especificada como argumento. Garante a imutabilidade dos IDs.';

-- Função Específica para PK de transactions_saldo
CREATE OR REPLACE FUNCTION public.prevent_transactions_pk_update_conditional()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.transactions_saldo_id IS DISTINCT FROM OLD.transactions_saldo_id AND
       OLD.transactions_saldo_description LIKE '%Pagamento de Fatura%' THEN
        RAISE EXCEPTION 'Atualização da chave primária "transactions_saldo_id" não é permitida para transações de "Pagamento de Fatura".';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
ALTER FUNCTION public.prevent_transactions_pk_update_conditional() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.prevent_transactions_pk_update_conditional() IS 'Impede a atualização da chave primária na tabela transactions_saldo se a descrição da transação contiver "Pagamento de Fatura", protegendo registros críticos.';

-- Função de Validação Operation/Proceeding (Saldo)
CREATE OR REPLACE FUNCTION public.check_operation_proceeding_compatibility(
    p_operation public.operation,
    p_proceeding_id character varying(50)
)
RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN p_operation = 'Crédito' THEN
            COALESCE((SELECT proceedings_credit FROM public.proceedings_saldo WHERE proceedings_id = p_proceeding_id), FALSE)
        WHEN p_operation = 'Débito' THEN
            COALESCE((SELECT proceedings_debit FROM public.proceedings_saldo WHERE proceedings_id = p_proceeding_id), FALSE)
        ELSE FALSE
    END;
$$;
ALTER FUNCTION public.check_operation_proceeding_compatibility(public.operation, character varying) OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.check_operation_proceeding_compatibility(public.operation, character varying) IS 'Verifica se a natureza da Operação (Crédito/Débito) é compatível com as permissões (credit/debit) do Procedimento de saldo especificado.';

-- Função de Validação Operation/Category (Saldo)
CREATE OR REPLACE FUNCTION public.check_operation_category_compatibility(
    p_operation public.operation,
    p_category_id character varying(50)
)
RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN p_operation = 'Crédito' THEN
            COALESCE((SELECT categories_credit FROM public.categories WHERE categories_id = p_category_id), FALSE)
        WHEN p_operation = 'Débito' THEN
            COALESCE((SELECT categories_debit FROM public.categories WHERE categories_id = p_category_id), FALSE)
        ELSE FALSE
    END;
$$;
ALTER FUNCTION public.check_operation_category_compatibility(public.operation, character varying) OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.check_operation_category_compatibility(public.operation, character varying) IS 'Verifica se a natureza da Operação (Crédito/Débito) é compatível com as permissões (credit/debit) da Categoria especificada.';

-- Função de Validação Procedure CC / Category
CREATE OR REPLACE FUNCTION public.check_procedure_category_compatibility_cc(
    p_procedure public.creditcard_transaction_procedure,
    p_category_id character varying(50)
)
RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN p_procedure = 'Crédito em Fatura' THEN
            COALESCE((SELECT categories_credit FROM public.categories WHERE categories_id = p_category_id), FALSE) -- Crédito na fatura geralmente se alinha com categoria de crédito (ex: estorno de compra)
        WHEN p_procedure = 'Débito em Fatura' THEN
            COALESCE((SELECT categories_debit FROM public.categories WHERE categories_id = p_category_id), FALSE) -- Débito na fatura se alinha com categoria de débito (ex: compra)
        ELSE FALSE
    END;
$$;
ALTER FUNCTION public.check_procedure_category_compatibility_cc(public.creditcard_transaction_procedure, character varying) OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.check_procedure_category_compatibility_cc(public.creditcard_transaction_procedure, character varying) IS 'Verifica se o Procedimento de transação de Cartão de Crédito é compatível com as permissões (credit/debit) da Categoria especificada.';

-- Função do Trigger para internal_transfers
CREATE OR REPLACE FUNCTION public.sync_internal_transfer_to_transactions()
RETURNS TRIGGER AS $$
DECLARE
    v_description TEXT := 'Movimentação entre Contas';
    v_proc_id VARCHAR(50);
    v_cat_id VARCHAR(50);
    v_debit_txn_id VARCHAR(101);
    v_credit_txn_id VARCHAR(101);
    v_proceeding_name TEXT := 'Transferência Interna';
    v_category_name TEXT := 'Transferências Internas';
    v_credit_registration_datetime TIMESTAMP WITH TIME ZONE;
    v_credit_implementation_datetime TIMESTAMP WITH TIME ZONE;
BEGIN
    SELECT proceedings_id INTO v_proc_id FROM public.proceedings_saldo WHERE proceedings_name = v_proceeding_name;
    SELECT categories_id INTO v_cat_id FROM public.categories WHERE categories_name = v_category_name;

    IF v_proc_id IS NULL THEN
        RAISE EXCEPTION 'Procedimento padrão "%" não encontrado na tabela proceedings_saldo. Verifique se foi criado e se o nome está correto na função do trigger.', v_proceeding_name;
    END IF;
    IF v_cat_id IS NULL THEN
        RAISE EXCEPTION 'Categoria padrão "%" não encontrada na tabela categories. Verifique se foi criada e se o nome está correto na função do trigger.', v_category_name;
    END IF;

    IF (TG_OP = 'INSERT') THEN
        v_debit_txn_id := NEW.internal_transfers_id || '-D';
        v_credit_txn_id := NEW.internal_transfers_id || '-C';
        v_credit_registration_datetime := NEW.internal_transfers_registration_datetime + INTERVAL '1 millisecond';
        v_credit_implementation_datetime := NEW.internal_transfers_implementation_datetime + INTERVAL '1 millisecond';

        INSERT INTO public.transactions_saldo (
            transactions_saldo_id, transactions_saldo_user_id, transactions_saldo_user_accounts_id,
            transactions_saldo_operation, transactions_saldo_proceeding_id, transactions_saldo_status,
            transactions_saldo_category_id, transactions_saldo_operator_id, transactions_saldo_description,
            transactions_saldo_observations, transactions_saldo_registration_datetime, transactions_saldo_is_recurrence,
            transactions_saldo_recurrence_id, transactions_saldo_schedule_datetime, transactions_saldo_implementation_datetime,
            transactions_saldo_base_value, transactions_saldo_fees_taxes, transactions_saldo_receipt_image,
            transactions_saldo_relevance_ir, transactions_saldo_last_update
        ) VALUES (
            v_debit_txn_id, NEW.internal_transfers_user_id, NEW.internal_transfers_origin_user_account_id,
            'Débito'::public.operation, v_proc_id, 'Efetuado'::public.status, v_cat_id, NEW.internal_transfers_operator_id, v_description,
            NEW.internal_transfers_observations, NEW.internal_transfers_registration_datetime, FALSE, NULL, NULL, NEW.internal_transfers_implementation_datetime,
            NEW.internal_transfers_base_value, NEW.internal_transfers_fees_taxes, NEW.internal_transfers_receipt_image, FALSE, NEW.internal_transfers_last_update
        );
        INSERT INTO public.transactions_saldo (
            transactions_saldo_id, transactions_saldo_user_id, transactions_saldo_user_accounts_id,
            transactions_saldo_operation, transactions_saldo_proceeding_id, transactions_saldo_status,
            transactions_saldo_category_id, transactions_saldo_operator_id, transactions_saldo_description,
            transactions_saldo_observations, transactions_saldo_registration_datetime, transactions_saldo_is_recurrence,
            transactions_saldo_recurrence_id, transactions_saldo_schedule_datetime, transactions_saldo_implementation_datetime,
            transactions_saldo_base_value, transactions_saldo_fees_taxes, transactions_saldo_receipt_image,
            transactions_saldo_relevance_ir, transactions_saldo_last_update
        ) VALUES (
            v_credit_txn_id, NEW.internal_transfers_user_id, NEW.internal_transfers_destination_user_account_id,
            'Crédito'::public.operation, v_proc_id, 'Efetuado'::public.status, v_cat_id, NEW.internal_transfers_operator_id, v_description,
            NEW.internal_transfers_observations, v_credit_registration_datetime, FALSE, NULL, NULL, v_credit_implementation_datetime,
            NEW.internal_transfers_base_value, 0, NEW.internal_transfers_receipt_image, FALSE, NEW.internal_transfers_last_update
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        v_debit_txn_id := NEW.internal_transfers_id || '-D';
        v_credit_txn_id := NEW.internal_transfers_id || '-C';
        v_credit_registration_datetime := NEW.internal_transfers_registration_datetime + INTERVAL '1 millisecond';
        v_credit_implementation_datetime := NEW.internal_transfers_implementation_datetime + INTERVAL '1 millisecond';

        UPDATE public.transactions_saldo SET
            transactions_saldo_user_id = NEW.internal_transfers_user_id,
            transactions_saldo_user_accounts_id = NEW.internal_transfers_origin_user_account_id,
            transactions_saldo_operator_id = NEW.internal_transfers_operator_id, transactions_saldo_description = v_description,
            transactions_saldo_observations = NEW.internal_transfers_observations, transactions_saldo_registration_datetime = NEW.internal_transfers_registration_datetime,
            transactions_saldo_schedule_datetime = NULL, transactions_saldo_implementation_datetime = NEW.internal_transfers_implementation_datetime,
            transactions_saldo_base_value = NEW.internal_transfers_base_value, transactions_saldo_fees_taxes = NEW.internal_transfers_fees_taxes,
            transactions_saldo_receipt_image = NEW.internal_transfers_receipt_image, transactions_saldo_last_update = NEW.internal_transfers_last_update,
            transactions_saldo_proceeding_id = v_proc_id, transactions_saldo_category_id = v_cat_id
        WHERE transactions_saldo_id = v_debit_txn_id;

        UPDATE public.transactions_saldo SET
            transactions_saldo_user_id = NEW.internal_transfers_user_id,
            transactions_saldo_user_accounts_id = NEW.internal_transfers_destination_user_account_id,
            transactions_saldo_operator_id = NEW.internal_transfers_operator_id, transactions_saldo_description = v_description,
            transactions_saldo_observations = NEW.internal_transfers_observations, transactions_saldo_registration_datetime = v_credit_registration_datetime,
            transactions_saldo_schedule_datetime = NULL, transactions_saldo_implementation_datetime = v_credit_implementation_datetime,
            transactions_saldo_base_value = NEW.internal_transfers_base_value, transactions_saldo_fees_taxes = 0,
            transactions_saldo_receipt_image = NEW.internal_transfers_receipt_image, transactions_saldo_last_update = NEW.internal_transfers_last_update,
            transactions_saldo_proceeding_id = v_proc_id, transactions_saldo_category_id = v_cat_id
        WHERE transactions_saldo_id = v_credit_txn_id;
    ELSIF (TG_OP = 'DELETE') THEN
        v_debit_txn_id := OLD.internal_transfers_id || '-D';
        v_credit_txn_id := OLD.internal_transfers_id || '-C';
        DELETE FROM public.transactions_saldo WHERE transactions_saldo_id = v_debit_txn_id;
        DELETE FROM public.transactions_saldo WHERE transactions_saldo_id = v_credit_txn_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.sync_internal_transfer_to_transactions() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.sync_internal_transfer_to_transactions() IS 'Sincroniza inserções, atualizações e exclusões da tabela internal_transfers para a tabela transactions_saldo, criando/modificando/removendo as transações de débito e crédito correspondentes. Busca IDs de procedimento/categoria e adiciona 1ms aos timestamps da transação de crédito.';

-- ====================================================================
-- FASE 3: CRIAR TABELAS (Ordem de Dependência)
-- ====================================================================

-- Tabela: users
CREATE TABLE public.users (
    users_id character varying(50) NOT NULL,
    users_first_name character varying(100) NOT NULL,
    users_last_name character varying(100) NULL,
    users_profile_picture_url text NULL,
    users_email character varying(255) NOT NULL,
    users_phone character varying(50) NULL,
    users_type public.user_type NOT NULL,
    users_status public.user_account_status NOT NULL DEFAULT 'Ativo',
    users_creation_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    users_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_pkey PRIMARY KEY (users_id),
    CONSTRAINT users_email_key UNIQUE (users_email)
);
ALTER TABLE public.users OWNER to "SisFinance-adm";
COMMENT ON TABLE public.users IS 'Armazena informações sobre os usuários do sistema.';
COMMENT ON COLUMN public.users.users_id IS 'Identificador único e exclusivo para cada usuário (PK, fornecido externamente).';
COMMENT ON COLUMN public.users.users_first_name IS 'Primeiro nome do usuário.';
COMMENT ON COLUMN public.users.users_last_name IS 'Sobrenome(s) do usuário (opcional).';
COMMENT ON COLUMN public.users.users_profile_picture_url IS 'URL para uma imagem de perfil/avatar do usuário (opcional).';
COMMENT ON COLUMN public.users.users_email IS 'Endereço de e-mail principal do usuário (único e obrigatório).';
COMMENT ON COLUMN public.users.users_phone IS 'Número de telefone do usuário (opcional).';
COMMENT ON COLUMN public.users.users_type IS 'Define o papel do usuário no sistema (Administrador ou Usuário), utilizando o tipo ENUM user_type.';
COMMENT ON COLUMN public.users.users_status IS 'Indica o estado atual da conta do usuário (Ativo, Inativo, Pendente), utilizando o tipo ENUM user_account_status. Padrão: Ativo.';
COMMENT ON COLUMN public.users.users_creation_datetime IS 'Data e hora exatas (UTC) em que o registro do usuário foi criado. Preenchido automaticamente no INSERT.';
COMMENT ON COLUMN public.users.users_last_update IS 'Data e hora exatas (UTC) da última modificação manual neste registro de usuário. Preenchido no INSERT, requer atualização manual/via AppSheet em UPDATEs.';

-- Tabela: categories
CREATE TABLE public.categories (
    categories_id character varying(50) NOT NULL,
    categories_name character varying(100) NOT NULL,
    categories_credit boolean NOT NULL DEFAULT false,
    categories_debit boolean NOT NULL DEFAULT false,
    CONSTRAINT categories_pkey PRIMARY KEY (categories_id),
    CONSTRAINT categories_category_name_key UNIQUE (categories_name),
    CONSTRAINT chk_categories_at_least_one_type CHECK (categories_credit IS TRUE OR categories_debit IS TRUE)
);
ALTER TABLE public.categories OWNER to "SisFinance-adm";
COMMENT ON TABLE public.categories IS 'Catálogo de categorias para classificar transações e recorrências, indicando se são aplicáveis a operações de crédito, débito ou ambas.';
COMMENT ON COLUMN public.categories.categories_id IS 'Identificador único da categoria (PK, fornecido externamente).';
COMMENT ON COLUMN public.categories.categories_name IS 'Nome descritivo e único da categoria (Ex: Salário, Moradia).';
COMMENT ON COLUMN public.categories.categories_credit IS 'Flag booleana que indica se esta categoria pode ser associada a operações de Crédito (entrada de valor). Padrão: FALSE.';
COMMENT ON COLUMN public.categories.categories_debit IS 'Flag booleana que indica se esta categoria pode ser associada a operações de Débito (saída de valor). Padrão: FALSE.';
COMMENT ON CONSTRAINT chk_categories_at_least_one_type ON public.categories IS 'Garante que cada categoria seja aplicável a pelo menos um tipo de operação (crédito ou débito).';

-- Tabela: proceedings_saldo
CREATE TABLE public.proceedings_saldo (
    proceedings_id character varying(50) NOT NULL,
    proceedings_name character varying(100) NOT NULL,
    proceedings_credit boolean NOT NULL DEFAULT false,
    proceedings_debit boolean NOT NULL DEFAULT false,
    CONSTRAINT proceedings_saldo_pkey PRIMARY KEY (proceedings_id),
    CONSTRAINT proceedings_saldo_name_key UNIQUE (proceedings_name),
    CONSTRAINT chk_proceedings_saldo_type CHECK (proceedings_credit IS TRUE OR proceedings_debit IS TRUE)
);
ALTER TABLE public.proceedings_saldo OWNER to "SisFinance-adm";
COMMENT ON TABLE public.proceedings_saldo IS 'Catálogo dos métodos ou instrumentos utilizados em transações de saldo (Ex: PIX, Boleto, Compra no Débito).';
COMMENT ON COLUMN public.proceedings_saldo.proceedings_id IS 'Identificador único do procedimento (PK, fornecido externamente).';
COMMENT ON COLUMN public.proceedings_saldo.proceedings_name IS 'Nome descritivo e único do procedimento/método.';
COMMENT ON COLUMN public.proceedings_saldo.proceedings_credit IS 'Flag booleana que indica se este procedimento pode originar uma operação de Crédito. Padrão: FALSE.';
COMMENT ON COLUMN public.proceedings_saldo.proceedings_debit IS 'Flag booleana que indica se este procedimento pode originar uma operação de Débito. Padrão: FALSE.';
COMMENT ON CONSTRAINT chk_proceedings_saldo_type ON public.proceedings_saldo IS 'Garante que cada procedimento seja aplicável a pelo menos um tipo de operação (crédito ou débito).';

-- Tabela: financial_institutions
CREATE TABLE public.financial_institutions (
    financial_institutions_id character varying(50) NOT NULL,
    financial_institutions_name character varying(150) NOT NULL,
    financial_institutions_official_name character varying(255) NOT NULL,
    financial_institutions_clearing_code character varying(10) NULL,
    financial_institutions_logo_url text NULL,
    financial_institutions_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT financial_institutions_pkey PRIMARY KEY (financial_institutions_id),
    CONSTRAINT financial_institutions_name_key UNIQUE (financial_institutions_name)
);
ALTER TABLE public.financial_institutions OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.financial_institutions IS 'Catálogo das instituições financeiras (bancos, fintechs, etc.).';
COMMENT ON COLUMN public.financial_institutions.financial_institutions_id IS 'Identificador único da instituição (PK, fornecido externamente).';
COMMENT ON COLUMN public.financial_institutions.financial_institutions_name IS 'Nome comum ou fantasia da instituição (único).';
COMMENT ON COLUMN public.financial_institutions.financial_institutions_official_name IS 'Nome oficial completo da instituição.';
COMMENT ON COLUMN public.financial_institutions.financial_institutions_clearing_code IS 'Código de compensação bancária (COMPE), se aplicável.';
COMMENT ON COLUMN public.financial_institutions.financial_institutions_logo_url IS 'URL para o logo da instituição (opcional).';
COMMENT ON COLUMN public.financial_institutions.financial_institutions_last_update IS 'Timestamp da criação ou última atualização manual deste registro.';

-- Tabela: account_types
CREATE TABLE public.account_types (
    account_types_id character varying(50) NOT NULL,
    account_types_name public.account_type NOT NULL,
    account_types_description text NULL,
    account_types_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT account_types_pkey PRIMARY KEY (account_types_id),
    CONSTRAINT account_types_name_key UNIQUE (account_types_name)
);
ALTER TABLE public.account_types OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.account_types IS 'Catálogo dos tipos genéricos de contas financeiras (Ex: Conta Corrente, Poupança).';
COMMENT ON COLUMN public.account_types.account_types_id IS 'Identificador único do tipo de conta (PK, fornecido externamente).';
COMMENT ON COLUMN public.account_types.account_types_name IS 'Nome do tipo de conta (ENUM account_type, único).';
COMMENT ON COLUMN public.account_types.account_types_description IS 'Descrição genérica sobre este tipo de conta (opcional).';
COMMENT ON COLUMN public.account_types.account_types_last_update IS 'Timestamp da criação ou última atualização manual deste registro.';

-- Tabela: institution_accounts (Produtos financeiros)
CREATE TABLE public.institution_accounts (
    institution_accounts_id character varying(50) NOT NULL,
    institution_accounts_institution_id character varying(50) NOT NULL,
    institution_accounts_type_id character varying(50) NOT NULL,
    institution_accounts_product_name character varying(150) NULL,
    institution_accounts_processing_info text NULL,
    institution_accounts_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT institution_accounts_pkey PRIMARY KEY (institution_accounts_id),
    CONSTRAINT fk_institution_accounts_institution FOREIGN KEY (institution_accounts_institution_id) REFERENCES public.financial_institutions(financial_institutions_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_institution_accounts_type FOREIGN KEY (institution_accounts_type_id) REFERENCES public.account_types(account_types_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT uq_institution_accounts_inst_type UNIQUE (institution_accounts_institution_id, institution_accounts_type_id)
);
ALTER TABLE public.institution_accounts OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.institution_accounts IS 'Define os "produtos" financeiros específicos oferecidos, ligando uma instituição a um tipo de conta.';
COMMENT ON COLUMN public.institution_accounts.institution_accounts_id IS 'Identificador único do produto financeiro (PK, fornecido externamente). Ex: "bb_cc_ouro".';
COMMENT ON COLUMN public.institution_accounts.institution_accounts_institution_id IS 'Referência à instituição financeira que oferece este produto (FK para financial_institutions).';
COMMENT ON COLUMN public.institution_accounts.institution_accounts_type_id IS 'Referência ao tipo genérico de conta deste produto (FK para account_types).';
COMMENT ON COLUMN public.institution_accounts.institution_accounts_product_name IS 'Nome específico do produto (Ex: "NuConta", "Conta Fácil"), se diferente do tipo genérico (opcional).';
COMMENT ON COLUMN public.institution_accounts.institution_accounts_processing_info IS 'Informações sobre horários/dias de processamento para este produto específico (opcional).';
COMMENT ON COLUMN public.institution_accounts.institution_accounts_last_update IS 'Timestamp da criação ou última atualização manual deste registro.';

-- Tabela: operators
CREATE TABLE public.operators (
    operators_id character varying(50) NOT NULL,
    operators_name character varying(150) NOT NULL,
    operators_user_id character varying(50) NOT NULL,
    operators_priority boolean NOT NULL DEFAULT false,
    operators_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT operators_pkey PRIMARY KEY (operators_id),
    CONSTRAINT operators_operator_name_key UNIQUE (operators_name),
    CONSTRAINT fk_operators_user FOREIGN KEY (operators_user_id) REFERENCES public.users(users_id) ON DELETE RESTRICT ON UPDATE NO ACTION
);
ALTER TABLE public.operators OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.operators IS 'Cadastro de operadores (pessoas ou sistemas) associados a um usuário, responsáveis por registrar transações ou recorrências.';
COMMENT ON COLUMN public.operators.operators_id IS 'Identificador único do operador (PK, fornecido externamente).';
COMMENT ON COLUMN public.operators.operators_name IS 'Nome identificador do operador (único). Ex: "Usuário Principal", "Débito Automático Luz".';
COMMENT ON COLUMN public.operators.operators_user_id IS 'Referência ao usuário do sistema associado a este operador (FK para users.users_id).';
COMMENT ON COLUMN public.operators.operators_priority IS 'Indica se este é o operador prioritário ou padrão para o usuário associado (DEFAULT FALSE).';
COMMENT ON COLUMN public.operators.operators_last_update IS 'Timestamp da criação ou última atualização manual deste registro de operador.';

-- Tabela: user_accounts (Ligação Usuário-Produto)
CREATE TABLE public.user_accounts (
    user_accounts_id character varying(50) NOT NULL,
    user_accounts_user_id character varying(50) NOT NULL,
    user_accounts_institution_account_id character varying(50) NOT NULL,
    user_accounts_financial_institution_type public.account_type NOT NULL,
    user_accounts_agency character varying(10) NULL,
    user_accounts_number character varying(100) NULL,
    user_accounts_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_accounts_pkey PRIMARY KEY (user_accounts_id),
    CONSTRAINT fk_user_accounts_user FOREIGN KEY (user_accounts_user_id) REFERENCES public.users(users_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_user_accounts_account FOREIGN KEY (user_accounts_institution_account_id) REFERENCES public.institution_accounts(institution_accounts_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT uq_user_accounts_user_account UNIQUE (user_accounts_user_id, user_accounts_institution_account_id)
);
ALTER TABLE public.user_accounts OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.user_accounts IS 'Associação entre usuários e os produtos financeiros específicos que eles possuem (Ex: a conta corrente específica do Usuário X no Banco Y).';
COMMENT ON COLUMN public.user_accounts.user_accounts_id IS 'Identificador único da associação usuário-produto (PK, fornecido externamente).';
COMMENT ON COLUMN public.user_accounts.user_accounts_user_id IS 'Referência ao usuário proprietário desta conta (FK para users).';
COMMENT ON COLUMN public.user_accounts.user_accounts_institution_account_id IS 'Referência ao produto financeiro específico que o usuário possui (FK para institution_accounts).';
COMMENT ON COLUMN public.user_accounts.user_accounts_financial_institution_type IS 'Tipo da conta/produto financeiro (ENUM account_type, para referência rápida e facilidade de consulta, denormalizado de institution_accounts).';
COMMENT ON COLUMN public.user_accounts.user_accounts_agency IS 'Número da agência bancária associada a esta conta do usuário, se aplicável (opcional).';
COMMENT ON COLUMN public.user_accounts.user_accounts_number IS 'Número da conta bancária (ou identificador similar) associada a esta conta do usuário, se aplicável (opcional).';
COMMENT ON COLUMN public.user_accounts.user_accounts_last_update IS 'Timestamp da criação ou última atualização manual deste registro de associação.';

-- Tabela: user_accounts_pix_keys
CREATE TABLE public.user_accounts_pix_keys (
    user_accounts_pix_keys_id character varying(50) NOT NULL,
    user_accounts_pix_keys_user_account_id character varying(50) NOT NULL,
    user_accounts_pix_keys_key text NOT NULL,
    user_accounts_pix_keys_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_accounts_pix_keys_pkey PRIMARY KEY (user_accounts_pix_keys_id),
    CONSTRAINT fk_uapix_user_account FOREIGN KEY (user_accounts_pix_keys_user_account_id) REFERENCES public.user_accounts(user_accounts_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT uq_uapix_key_per_account UNIQUE (user_accounts_pix_keys_user_account_id, user_accounts_pix_keys_key)
);
ALTER TABLE public.user_accounts_pix_keys OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.user_accounts_pix_keys IS 'Armazena as chaves PIX individuais associadas a uma conta específica de um usuário (referenciando user_accounts).';
COMMENT ON COLUMN public.user_accounts_pix_keys.user_accounts_pix_keys_id IS 'Identificador único para esta entrada de chave PIX (PK, fornecido externamente).';
COMMENT ON COLUMN public.user_accounts_pix_keys.user_accounts_pix_keys_user_account_id IS 'Referência à associação usuário-conta específica à qual esta chave PIX pertence (FK para user_accounts.user_accounts_id).';
COMMENT ON COLUMN public.user_accounts_pix_keys.user_accounts_pix_keys_key IS 'A chave PIX em si (e-mail, telefone, CPF/CNPJ, chave aleatória).';
COMMENT ON COLUMN public.user_accounts_pix_keys.user_accounts_pix_keys_last_update IS 'Timestamp da criação ou última atualização manual deste registro de chave PIX.';

-- Tabela: recurrence_saldo
CREATE TABLE public.recurrence_saldo (
    recurrence_saldo_id character varying(50) NOT NULL,
    recurrence_saldo_user_id character varying(50) NOT NULL,
    recurrence_saldo_user_account_id character varying(50) NOT NULL,
    recurrence_saldo_operation public.operation NOT NULL,
    recurrence_saldo_proceeding_id character varying(50) NOT NULL,
    recurrence_saldo_category_id character varying(50) NOT NULL,
    recurrence_saldo_operator_id character varying(50) NOT NULL,
    recurrence_saldo_status public.recurrence_status_ai NOT NULL DEFAULT 'Ativo',
    recurrence_saldo_description text,
    recurrence_saldo_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    recurrence_saldo_type public.recurrence_type NOT NULL,
    recurrence_saldo_frequency public.recurrence_frequency NOT NULL,
    recurrence_saldo_due_day integer,
    recurrence_saldo_first_due_date date NOT NULL,
    recurrence_saldo_last_due_date date,
    recurrence_saldo_postpone_to_business_day boolean NOT NULL DEFAULT false,
    recurrence_saldo_base_value numeric(15, 2) NOT NULL,
    recurrence_saldo_fees_taxes numeric(15, 2) NOT NULL DEFAULT 0,
    recurrence_saldo_subtotal numeric(15, 2) GENERATED ALWAYS AS (CASE WHEN recurrence_saldo_operation = 'Crédito' THEN recurrence_saldo_base_value - recurrence_saldo_fees_taxes ELSE recurrence_saldo_base_value + recurrence_saldo_fees_taxes END) STORED,
    recurrence_saldo_total_effective numeric(15, 2) GENERATED ALWAYS AS (CASE WHEN recurrence_saldo_operation = 'Crédito' THEN (recurrence_saldo_base_value - recurrence_saldo_fees_taxes) ELSE ((recurrence_saldo_base_value + recurrence_saldo_fees_taxes) * -1) END) STORED,
    recurrence_saldo_receipt_archive text,
    recurrence_saldo_receipt_image text,
    recurrence_saldo_relevance_ir boolean NOT NULL DEFAULT false,
    recurrence_saldo_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT recurrence_saldo_pkey PRIMARY KEY (recurrence_saldo_id),
    CONSTRAINT fk_recurrence_user FOREIGN KEY (recurrence_saldo_user_id) REFERENCES public.users(users_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_recurrence_user_account FOREIGN KEY (recurrence_saldo_user_account_id) REFERENCES public.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_recurrence_proceeding FOREIGN KEY (recurrence_saldo_proceeding_id) REFERENCES public.proceedings_saldo(proceedings_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_recurrence_category FOREIGN KEY (recurrence_saldo_category_id) REFERENCES public.categories(categories_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_recurrence_operator FOREIGN KEY (recurrence_saldo_operator_id) REFERENCES public.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT chk_recurrence_due_day_range CHECK (recurrence_saldo_due_day IS NULL OR (recurrence_saldo_due_day >= 1 AND recurrence_saldo_due_day <= 31)),
    CONSTRAINT chk_recurrence_due_day_required CHECK (recurrence_saldo_frequency = 'Semanal' OR recurrence_saldo_due_day IS NOT NULL),
    CONSTRAINT chk_recurrence_last_date_logic CHECK (recurrence_saldo_last_due_date IS NULL OR recurrence_saldo_last_due_date >= recurrence_saldo_first_due_date),
    CONSTRAINT chk_recurrence_determined_needs_last_date CHECK (recurrence_saldo_type = 'Indeterminado' OR recurrence_saldo_last_due_date IS NOT NULL),
    CONSTRAINT chk_recurrence_operation_proceeding CHECK (public.check_operation_proceeding_compatibility(recurrence_saldo_operation, recurrence_saldo_proceeding_id))
);
ALTER TABLE public.recurrence_saldo OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.recurrence_saldo IS 'Armazena os modelos/agendamentos de transações financeiras de saldo recorrentes.';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_id IS 'Identificador único da recorrência de saldo (PK, fornecido externamente).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_user_id IS 'Usuário proprietário desta recorrência (FK para users).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_user_account_id IS 'Referência à associação usuário-conta específica afetada pela recorrência (FK para user_accounts).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_operation IS 'Natureza da operação (Crédito ou Débito) das transações geradas por esta recorrência.';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_proceeding_id IS 'Procedimento/método padrão das transações recorrentes (FK para proceedings_saldo).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_category_id IS 'Categoria padrão das transações recorrentes (FK para categories).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_operator_id IS 'Operador padrão associado às transações desta recorrência (FK para operators).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_status IS 'Status atual da recorrência (Ativo ou Inativo).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_description IS 'Descrição padrão para as transações geradas por esta recorrência (opcional).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_registration_datetime IS 'Data e hora de cadastro desta recorrência no sistema.';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_type IS 'Tipo de recorrência (Determinada com data final, ou Indeterminada).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_frequency IS 'Frequência com que a transação deve ocorrer (Semanal, Mensal, etc.).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_due_day IS 'Dia preferencial do mês para vencimento (1-31), obrigatório se a frequência não for Semanal (opcional).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_first_due_date IS 'Data do primeiro vencimento ou da primeira ocorrência desta recorrência.';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_last_due_date IS 'Data do último vencimento ou da última ocorrência (para tipo Determinado) (opcional).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_postpone_to_business_day IS 'Indica se o vencimento, caso caia em dia não útil, deve ser adiado para o próximo dia útil. Padrão: FALSE.';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_base_value IS 'Valor base da transação recorrente.';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_fees_taxes IS 'Valor de taxas ou impostos adicionais da transação recorrente. Padrão: 0.';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_subtotal IS 'Valor calculado: base_value +/- fees_taxes (dependendo da operação). Coluna Gerada.';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_total_effective IS 'Valor efetivo com sinal: subtotal ou -subtotal (dependendo da operação). Coluna Gerada.';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_receipt_archive IS 'Caminho ou identificador para um arquivo de comprovante modelo associado a esta recorrência (opcional).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_receipt_image IS 'Caminho ou identificador para uma imagem de comprovante modelo associada a esta recorrência (opcional).';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_relevance_ir IS 'Indica se as transações geradas por esta recorrência são relevantes para declaração de Imposto de Renda. Padrão: FALSE.';
COMMENT ON COLUMN public.recurrence_saldo.recurrence_saldo_last_update IS 'Timestamp da criação ou última atualização manual deste registro de recorrência.';

-- Tabela: transactions_saldo
CREATE TABLE public.transactions_saldo (
    transactions_saldo_id character varying(50) NOT NULL,
    transactions_saldo_user_id character varying(50) NOT NULL,
    transactions_saldo_user_accounts_id character varying(50) NOT NULL,
    transactions_saldo_operation public.operation NOT NULL,
    transactions_saldo_proceeding_id character varying(50) NOT NULL,
    transactions_saldo_status public.status NOT NULL DEFAULT 'Efetuado',
    transactions_saldo_category_id character varying(50) NOT NULL,
    transactions_saldo_operator_id character varying(50) NOT NULL,
    transactions_saldo_description text,
    transactions_saldo_observations text,
    transactions_saldo_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    transactions_saldo_is_recurrence boolean NOT NULL DEFAULT false,
    transactions_saldo_recurrence_id character varying(50),
    transactions_saldo_schedule_datetime timestamp with time zone,
    transactions_saldo_implementation_datetime timestamp with time zone NOT NULL,
    transactions_saldo_base_value numeric(15, 2) NOT NULL,
    transactions_saldo_fees_taxes numeric(15, 2) NOT NULL DEFAULT 0,
    transactions_saldo_subtotal numeric(15, 2) GENERATED ALWAYS AS (CASE WHEN transactions_saldo_operation = 'Crédito' THEN transactions_saldo_base_value - transactions_saldo_fees_taxes ELSE transactions_saldo_base_value + transactions_saldo_fees_taxes END) STORED,
    transactions_saldo_total_effective numeric(15, 2) GENERATED ALWAYS AS (CASE WHEN transactions_saldo_operation = 'Crédito' THEN (transactions_saldo_base_value - transactions_saldo_fees_taxes) ELSE ((transactions_saldo_base_value + transactions_saldo_fees_taxes) * -1) END) STORED,
    transactions_saldo_receipt_archive text,
    transactions_saldo_receipt_image text,
    transactions_saldo_receipt_url text,
    transactions_saldo_relevance_ir boolean NOT NULL DEFAULT false,
    transactions_saldo_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transactions_saldo_pkey PRIMARY KEY (transactions_saldo_id),
    CONSTRAINT fk_transactions_user FOREIGN KEY (transactions_saldo_user_id) REFERENCES public.users(users_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_user_account FOREIGN KEY (transactions_saldo_user_accounts_id) REFERENCES public.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_proceeding FOREIGN KEY (transactions_saldo_proceeding_id) REFERENCES public.proceedings_saldo(proceedings_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_category FOREIGN KEY (transactions_saldo_category_id) REFERENCES public.categories(categories_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_operator FOREIGN KEY (transactions_saldo_operator_id) REFERENCES public.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_recurrence FOREIGN KEY (transactions_saldo_recurrence_id) REFERENCES public.recurrence_saldo(recurrence_saldo_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT chk_transactions_operation_proceeding CHECK (public.check_operation_proceeding_compatibility(transactions_saldo_operation, transactions_saldo_proceeding_id)),
    CONSTRAINT chk_transactions_operation_category CHECK (public.check_operation_category_compatibility(transactions_saldo_operation, transactions_saldo_category_id)),
    CONSTRAINT chk_transactions_recurrence_logic CHECK ((transactions_saldo_is_recurrence IS FALSE AND transactions_saldo_recurrence_id IS NULL) OR (transactions_saldo_is_recurrence IS TRUE AND transactions_saldo_recurrence_id IS NOT NULL)),
    CONSTRAINT chk_transactions_schedule_status CHECK (transactions_saldo_schedule_datetime IS NULL OR transactions_saldo_status = 'Pendente')
);
ALTER TABLE public.transactions_saldo OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.transactions_saldo IS 'Registros individuais de transações financeiras de saldo (movimentações em contas).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_id IS 'Identificador único da transação de saldo (PK, fornecido externamente).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_user_id IS 'Usuário associado à transação (FK para users).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_user_accounts_id IS 'Referência à associação usuário-conta específica afetada pela transação (FK para user_accounts).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_operation IS 'Natureza da operação (Crédito ou Débito).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_proceeding_id IS 'Procedimento/método utilizado na transação (FK para proceedings_saldo).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_status IS 'Status da transação (Efetuado ou Pendente). Padrão: Efetuado.';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_category_id IS 'Categoria da transação (FK para categories).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_operator_id IS 'Operador que registrou/realizou a transação (FK para operators).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_description IS 'Descrição específica desta transação (opcional).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_observations IS 'Notas ou observações adicionais sobre a transação (opcional).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_registration_datetime IS 'Data e hora de registro da transação no sistema.';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_is_recurrence IS 'Flag booleana indicando se esta transação foi originada de um agendamento de recorrência. Padrão: FALSE.';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_recurrence_id IS 'Referência ao registro de recorrência que gerou esta transação (FK para recurrence_saldo), se aplicável (opcional).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_schedule_datetime IS 'Data e hora em que a transação está/estava agendada para ocorrer (para transações com status Pendente) (opcional).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_implementation_datetime IS 'Data e hora em que a transação foi efetivamente realizada/liquidada no mundo real.';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_base_value IS 'Valor principal da transação.';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_fees_taxes IS 'Taxas/impostos associados a esta transação específica. Padrão: 0.';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_subtotal IS 'Valor calculado: base_value +/- fees_taxes (dependendo da operação). Coluna Gerada.';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_total_effective IS 'Valor efetivo com sinal: subtotal ou -subtotal (dependendo da operação). Coluna Gerada.';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_receipt_archive IS 'Caminho/ID do arquivo de comprovante da transação (opcional).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_receipt_image IS 'Caminho/ID da imagem de comprovante da transação (opcional).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_receipt_url IS 'URL externa para o comprovante da transação (opcional).';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_relevance_ir IS 'Indica se esta transação é relevante para declaração de Imposto de Renda. Padrão: FALSE.';
COMMENT ON COLUMN public.transactions_saldo.transactions_saldo_last_update IS 'Timestamp da criação ou última atualização manual deste registro de transação.';

-- Tabela: internal_transfers
CREATE TABLE public.internal_transfers (
    internal_transfers_id character varying(50) NOT NULL,
    internal_transfers_user_id character varying(50) NOT NULL,
    internal_transfers_origin_user_account_id character varying(50) NOT NULL,
    internal_transfers_destination_user_account_id character varying(50) NOT NULL,
    internal_transfers_operator_id character varying(50) NOT NULL,
    internal_transfers_observations text,
    internal_transfers_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    internal_transfers_implementation_datetime timestamp with time zone NOT NULL,
    internal_transfers_base_value numeric(15, 2) NOT NULL,
    internal_transfers_fees_taxes numeric(15, 2) NOT NULL DEFAULT 0,
    internal_transfers_subtotal numeric(15, 2) GENERATED ALWAYS AS (internal_transfers_base_value - internal_transfers_fees_taxes) STORED,
    internal_transfers_total_effective numeric(15, 2) GENERATED ALWAYS AS (internal_transfers_base_value - internal_transfers_fees_taxes) STORED,
    internal_transfers_receipt_image text,
    internal_transfers_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT internal_transfers_pkey PRIMARY KEY (internal_transfers_id),
    CONSTRAINT fk_inttransf_user FOREIGN KEY (internal_transfers_user_id) REFERENCES public.users(users_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_inttransf_origin FOREIGN KEY (internal_transfers_origin_user_account_id) REFERENCES public.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_inttransf_destination FOREIGN KEY (internal_transfers_destination_user_account_id) REFERENCES public.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_inttransf_operator FOREIGN KEY (internal_transfers_operator_id) REFERENCES public.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT chk_inttransf_different_accounts CHECK (internal_transfers_origin_user_account_id <> internal_transfers_destination_user_account_id),
    CONSTRAINT chk_inttransf_value_vs_fees CHECK (internal_transfers_base_value >= internal_transfers_fees_taxes)
);
ALTER TABLE public.internal_transfers OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.internal_transfers IS 'Registra operações de transferência de fundos entre contas do mesmo usuário, que dispara a criação de duas transações em transactions_saldo.';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_id IS 'Identificador único da operação de transferência (PK, fornecido externamente).';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_user_id IS 'Usuário que realiza a transferência (FK para users).';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_origin_user_account_id IS 'Conta de origem dos fundos para a transferência (FK para user_accounts).';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_destination_user_account_id IS 'Conta de destino dos fundos para a transferência (FK para user_accounts).';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_operator_id IS 'Operador que registrou a transferência (FK para operators).';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_observations IS 'Observações sobre a transferência (opcional).';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_registration_datetime IS 'Data/hora de registro da operação de transferência no sistema.';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_implementation_datetime IS 'Data/hora em que a transferência foi efetivamente realizada.';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_base_value IS 'Valor principal transferido (deve ser positivo).';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_fees_taxes IS 'Taxas associadas à operação de transferência em si (raro em transferências internas). Padrão: 0.';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_subtotal IS 'Valor calculado: base_value - fees_taxes. Coluna Gerada.';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_total_effective IS 'Valor efetivo transferido: base_value - fees_taxes. Coluna Gerada.';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_receipt_image IS 'URL/ID da imagem do comprovante da transferência (opcional).';
COMMENT ON COLUMN public.internal_transfers.internal_transfers_last_update IS 'Timestamp da criação ou última atualização manual deste registro.';

-- Tabela: creditcards
CREATE TABLE public.creditcards (
    creditcards_id character varying(50) NOT NULL,
    creditcards_name character varying(100) NOT NULL,
    creditcards_network character varying(150) NOT NULL,
    creditcards_logo text NULL,
    creditcards_financial_institutions_id character varying(50) NOT NULL,
    creditcards_postpone_due_date_to_business_day boolean NOT NULL DEFAULT true,
    creditcards_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT creditcards_pkey PRIMARY KEY (creditcards_id),
    CONSTRAINT fk_creditcards_financial_institution FOREIGN KEY (creditcards_financial_institutions_id) REFERENCES public.financial_institutions(financial_institutions_id) ON DELETE RESTRICT ON UPDATE NO ACTION
);
ALTER TABLE public.creditcards OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.creditcards IS 'Catálogo dos produtos de cartão de crédito oferecidos pelas instituições financeiras.';
COMMENT ON COLUMN public.creditcards.creditcards_id IS 'Identificador único do produto cartão de crédito (PK, fornecido externamente).';
COMMENT ON COLUMN public.creditcards.creditcards_name IS 'Nome comercial do cartão de crédito (Ex: Platinum, Gold).';
COMMENT ON COLUMN public.creditcards.creditcards_network IS 'Bandeira do cartão (Ex: Visa, Mastercard, Elo).';
COMMENT ON COLUMN public.creditcards.creditcards_logo IS 'URL para a imagem do logo do cartão (opcional).';
COMMENT ON COLUMN public.creditcards.creditcards_financial_institutions_id IS 'Referência à instituição financeira emissora do cartão (FK para financial_institutions).';
COMMENT ON COLUMN public.creditcards.creditcards_postpone_due_date_to_business_day IS 'Indica se o vencimento da fatura é adiado para o próximo dia útil caso caia em dia não útil. Padrão: TRUE.';
COMMENT ON COLUMN public.creditcards.creditcards_last_update IS 'Timestamp da criação ou última atualização manual do registro do cartão.';

-- Tabela: user_creditcards
CREATE TABLE public.user_creditcards (
    user_creditcards_id character varying(50) NOT NULL,
    user_creditcards_user_id character varying(50) NOT NULL,
    user_creditcards_creditcard_id character varying(50) NOT NULL,
    user_creditcards_payment_user_account_id character varying(50) NOT NULL,
    user_creditcards_payment_method public.payment_method NOT NULL,
    user_creditcards_closing_day integer NOT NULL CHECK (user_creditcards_closing_day >= 1 AND user_creditcards_closing_day <= 31),
    user_creditcards_due_day integer NOT NULL CHECK (user_creditcards_due_day >= 1 AND user_creditcards_due_day <= 31),
    user_creditcards_limit numeric(15, 2) NOT NULL DEFAULT 0,
    user_creditcards_status boolean NOT NULL DEFAULT true,
    user_creditcards_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_creditcards_pkey PRIMARY KEY (user_creditcards_id),
    CONSTRAINT fk_usercred_user FOREIGN KEY (user_creditcards_user_id) REFERENCES public.users(users_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_usercred_card FOREIGN KEY (user_creditcards_creditcard_id) REFERENCES public.creditcards(creditcards_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_usercred_payment_account FOREIGN KEY (user_creditcards_payment_user_account_id) REFERENCES public.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT uq_usercred_user_card UNIQUE (user_creditcards_user_id, user_creditcards_creditcard_id)
);
ALTER TABLE public.user_creditcards OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.user_creditcards IS 'Associação entre usuários e os cartões de crédito que possuem, definindo limites, forma de pagamento e status.';
COMMENT ON COLUMN public.user_creditcards.user_creditcards_id IS 'Identificador único da associação usuário-cartão (PK, fornecido externamente).';
COMMENT ON COLUMN public.user_creditcards.user_creditcards_user_id IS 'Referência ao usuário proprietário deste cartão (FK para users).';
COMMENT ON COLUMN public.user_creditcards.user_creditcards_creditcard_id IS 'Referência ao produto cartão de crédito que o usuário possui (FK para creditcards).';
COMMENT ON COLUMN public.user_creditcards.user_creditcards_payment_user_account_id IS 'Referência à conta do usuário (de user_accounts) usada para pagar a fatura deste cartão.';
COMMENT ON COLUMN public.user_creditcards.user_creditcards_payment_method IS 'Forma de pagamento da fatura deste cartão (Débito Automático ou Boleto).';
COMMENT ON COLUMN public.user_creditcards.user_creditcards_closing_day IS 'Dia do mês em que a fatura deste cartão fecha (1-31). Este é o NÚMERO DE DIAS ANTES DO VENCIMENTO.';
COMMENT ON COLUMN public.user_creditcards.user_creditcards_due_day IS 'Dia do mês em que a fatura deste cartão vence (1-31).';
COMMENT ON COLUMN public.user_creditcards.user_creditcards_limit IS 'Limite de crédito do usuário neste cartão. Padrão: 0.';
COMMENT ON COLUMN public.user_creditcards.user_creditcards_status IS 'Status do cartão para este usuário (TRUE = Ativo, FALSE = Desativado/Cancelado). Padrão: TRUE.';
COMMENT ON COLUMN public.user_creditcards.user_creditcards_last_update IS 'Timestamp da criação ou última atualização manual desta associação usuário-cartão.';

-- Tabela: creditcard_invoices
CREATE TABLE public.creditcard_invoices (
    creditcard_invoices_id character varying(50) NOT NULL,
    creditcard_invoices_user_creditcard_id character varying(50) NOT NULL,
    creditcard_invoices_user_id character varying(50) NOT NULL, -- Redundante, mas mantido para conveniência no AppSheet
    creditcard_invoices_creation_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creditcard_invoices_opening_date date NOT NULL,
    creditcard_invoices_closing_date date NOT NULL,
    creditcard_invoices_due_date date NOT NULL,
    creditcard_invoices_statement_period character varying(7) NOT NULL, -- Formato YYYY-MM
    creditcard_invoices_amount numeric(15, 2) NOT NULL DEFAULT 0,
    creditcard_invoices_paid_amount numeric(15, 2) NOT NULL DEFAULT 0,
    creditcard_invoices_payment_date date,
    creditcard_invoices_status public.invoice_status NOT NULL DEFAULT 'Aberta',
    creditcard_invoices_file_url text,
    creditcard_invoices_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT creditcard_invoices_pkey PRIMARY KEY (creditcard_invoices_id),
    CONSTRAINT fk_invoice_usercard FOREIGN KEY (creditcard_invoices_user_creditcard_id) REFERENCES public.user_creditcards(user_creditcards_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_invoice_user FOREIGN KEY (creditcard_invoices_user_id) REFERENCES public.users(users_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT uq_invoice_card_period UNIQUE (creditcard_invoices_user_creditcard_id, creditcard_invoices_statement_period)
);
ALTER TABLE public.creditcard_invoices OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.creditcard_invoices IS 'Representa cada fatura mensal de um cartão de crédito específico do usuário.';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_id IS 'Identificador único da fatura (PK, fornecido externamente).';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_user_creditcard_id IS 'Referência à associação usuário-cartão à qual esta fatura pertence (FK para user_creditcards).';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_user_id IS 'Referência ao usuário proprietário da fatura (FK para users, denormalizado para conveniência).';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_creation_datetime IS 'Data e hora de criação do registro da fatura no sistema.';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_opening_date IS 'Data de início do período de compras desta fatura.';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_closing_date IS 'Data de fechamento para novas compras desta fatura.';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_due_date IS 'Data de vencimento para pagamento desta fatura.';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_statement_period IS 'Período de referência da fatura no formato YYYY-MM (Ex: 2024-01).';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_amount IS 'Valor total da fatura a ser pago. Inicialmente 0, calculado por processo externo/script.';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_paid_amount IS 'Valor efetivamente pago desta fatura. Inicialmente 0.';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_payment_date IS 'Data em que o pagamento (total ou parcial) da fatura foi realizado (opcional).';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_status IS 'Status atual da fatura (Aberta, Fechada, Paga, etc.). Padrão: Aberta.';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_file_url IS 'URL para o arquivo PDF ou imagem da fatura (opcional).';
COMMENT ON COLUMN public.creditcard_invoices.creditcard_invoices_last_update IS 'Timestamp da criação ou última atualização manual do registro da fatura.';

-- Tabela: recurrence_creditcard
CREATE TABLE public.recurrence_creditcard (
    creditcard_recurrence_id character varying(50) NOT NULL,
    creditcard_recurrence_user_id character varying(50) NOT NULL,
    creditcard_recurrence_user_card_id character varying(50) NOT NULL,
    creditcard_recurrence_procedure public.creditcard_transaction_procedure NOT NULL DEFAULT 'Débito em Fatura',
    creditcard_recurrence_category_id character varying(50) NOT NULL,
    creditcard_recurrence_operator_id character varying(50) NOT NULL,
    creditcard_recurrence_status public.recurrence_status_ai NOT NULL DEFAULT 'Ativo',
    creditcard_recurrence_description text,
    creditcard_recurrence_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creditcard_recurrence_type public.recurrence_type NOT NULL,
    creditcard_recurrence_frequency public.recurrence_frequency NOT NULL,
    creditcard_recurrence_due_day integer CHECK (creditcard_recurrence_due_day IS NULL OR (creditcard_recurrence_due_day >= 1 AND creditcard_recurrence_due_day <= 31)),
    creditcard_recurrence_first_due_date date NOT NULL,
    creditcard_recurrence_last_due_date date,
    creditcard_recurrence_postpone_to_business_day boolean NOT NULL DEFAULT false,
    creditcard_recurrence_base_value numeric(15, 2) NOT NULL,
    creditcard_recurrence_fees_taxes numeric(15, 2) NOT NULL DEFAULT 0,
    creditcard_recurrence_subtotal numeric(15, 2) GENERATED ALWAYS AS (creditcard_recurrence_base_value + creditcard_recurrence_fees_taxes) STORED,
    creditcard_recurrence_total_effective numeric(15, 2) GENERATED ALWAYS AS (CASE WHEN creditcard_recurrence_procedure = 'Crédito em Fatura' THEN (creditcard_recurrence_base_value + creditcard_recurrence_fees_taxes) ELSE ((creditcard_recurrence_base_value + creditcard_recurrence_fees_taxes) * -1) END) STORED,
    creditcard_recurrence_receipt_archive text,
    creditcard_recurrence_receipt_image text,
    creditcard_recurrence_receipt_url text,
    creditcard_recurrence_relevance_ir boolean NOT NULL DEFAULT false,
    creditcard_recurrence_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT creditcard_recurrence_pkey PRIMARY KEY (creditcard_recurrence_id),
    CONSTRAINT fk_ccrecur_user FOREIGN KEY (creditcard_recurrence_user_id) REFERENCES public.users(users_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_ccrecur_usercard FOREIGN KEY (creditcard_recurrence_user_card_id) REFERENCES public.user_creditcards(user_creditcards_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_ccrecur_category FOREIGN KEY (creditcard_recurrence_category_id) REFERENCES public.categories(categories_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_ccrecur_operator FOREIGN KEY (creditcard_recurrence_operator_id) REFERENCES public.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT chk_ccrecur_due_day_required CHECK (creditcard_recurrence_frequency = 'Semanal' OR creditcard_recurrence_due_day IS NOT NULL),
    CONSTRAINT chk_ccrecur_last_date_logic CHECK (creditcard_recurrence_last_due_date IS NULL OR creditcard_recurrence_last_due_date >= creditcard_recurrence_first_due_date),
    CONSTRAINT chk_ccrecur_determined_needs_last_date CHECK (creditcard_recurrence_type = 'Indeterminado' OR creditcard_recurrence_last_due_date IS NOT NULL),
    CONSTRAINT chk_ccrecur_procedure_category CHECK (public.check_procedure_category_compatibility_cc(creditcard_recurrence_procedure, creditcard_recurrence_category_id))
);
ALTER TABLE public.recurrence_creditcard OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.recurrence_creditcard IS 'Define transações recorrentes que ocorrem diretamente na fatura do cartão de crédito.';
COMMENT ON COLUMN public.recurrence_creditcard.creditcard_recurrence_id IS 'Identificador único da recorrência de cartão (PK, fornecido externamente).';
-- ... (Adicionar comentários para TODAS as outras colunas de recurrence_creditcard)...
COMMENT ON COLUMN public.recurrence_creditcard.creditcard_recurrence_last_update IS 'Timestamp da criação ou última atualização manual deste registro de recorrência de cartão.';

-- Tabela: creditcard_transactions
CREATE TABLE public.creditcard_transactions (
    creditcard_transactions_id character varying(50) NOT NULL,
    creditcard_transactions_user_id character varying(50) NOT NULL,
    creditcard_transactions_user_card_id character varying(50) NOT NULL,
    creditcard_transactions_invoice_id character varying(50),
    creditcard_transactions_procedure public.creditcard_transaction_procedure NOT NULL DEFAULT 'Débito em Fatura',
    creditcard_transactions_status public.status NOT NULL,
    creditcard_transactions_category_id character varying(50) NOT NULL,
    creditcard_transactions_operator_id character varying(50) NOT NULL,
    creditcard_transactions_description text,
    creditcard_transactions_observations text,
    creditcard_transactions_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creditcard_transactions_is_recurrence boolean NOT NULL DEFAULT false,
    creditcard_transactions_recurrence_id character varying(50),
    creditcard_transactions_schedule_datetime timestamp with time zone,
    creditcard_transactions_implementation_datetime timestamp with time zone NOT NULL,
    creditcard_transactions_statement_month public.month_enum NOT NULL,
    creditcard_transactions_statement_year integer NOT NULL CHECK (creditcard_transactions_statement_year >= 2020),
    creditcard_transactions_is_installment boolean NOT NULL DEFAULT false,
    creditcard_transactions_installment_count integer NOT NULL DEFAULT 1 CHECK (creditcard_transactions_installment_count >= 1 AND creditcard_transactions_installment_count <= 420),
    creditcard_transactions_base_value numeric(15, 2) NOT NULL,
    creditcard_transactions_fees_taxes numeric(15, 2) NOT NULL DEFAULT 0,
    creditcard_transactions_subtotal numeric(15, 2) GENERATED ALWAYS AS (creditcard_transactions_base_value + creditcard_transactions_fees_taxes) STORED,
    creditcard_transactions_total_effective numeric(15, 2) GENERATED ALWAYS AS (CASE WHEN creditcard_transactions_procedure = 'Crédito em Fatura' THEN (creditcard_transactions_base_value + creditcard_transactions_fees_taxes) ELSE ((creditcard_transactions_base_value + creditcard_transactions_fees_taxes) * -1) END) STORED,
    creditcard_transactions_receipt_archive text,
    creditcard_transactions_receipt_image text,
    creditcard_transactions_receipt_url text,
    creditcard_transactions_relevance_ir boolean NOT NULL DEFAULT false,
    creditcard_transactions_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT creditcard_transactions_pkey PRIMARY KEY (creditcard_transactions_id),
    CONSTRAINT fk_cctrans_user FOREIGN KEY (creditcard_transactions_user_id) REFERENCES public.users(users_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_cctrans_usercard FOREIGN KEY (creditcard_transactions_user_card_id) REFERENCES public.user_creditcards(user_creditcards_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_cctrans_invoice FOREIGN KEY (creditcard_transactions_invoice_id) REFERENCES public.creditcard_invoices(creditcard_invoices_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT fk_cctrans_category FOREIGN KEY (creditcard_transactions_category_id) REFERENCES public.categories(categories_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_cctrans_operator FOREIGN KEY (creditcard_transactions_operator_id) REFERENCES public.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_cctrans_recurrence FOREIGN KEY (creditcard_transactions_recurrence_id) REFERENCES public.recurrence_creditcard(creditcard_recurrence_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT chk_cctrans_installment_logic CHECK ((creditcard_transactions_is_installment IS FALSE AND creditcard_transactions_installment_count = 1) OR (creditcard_transactions_is_installment IS TRUE AND creditcard_transactions_installment_count > 1)),
    CONSTRAINT chk_cctrans_recurrence_logic CHECK ((creditcard_transactions_is_recurrence IS FALSE AND creditcard_transactions_recurrence_id IS NULL) OR (creditcard_transactions_is_recurrence IS TRUE AND creditcard_transactions_recurrence_id IS NOT NULL)),
    CONSTRAINT chk_cctrans_procedure_category CHECK (public.check_procedure_category_compatibility_cc(creditcard_transactions_procedure, creditcard_transactions_category_id))
);
ALTER TABLE public.creditcard_transactions OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.creditcard_transactions IS 'Registra cada movimentação individual (compra, estorno, taxa) realizada com o cartão de crédito.';
COMMENT ON COLUMN public.creditcard_transactions.creditcard_transactions_id IS 'Identificador único da transação de cartão (PK, fornecido externamente).';
-- ... (Adicionar comentários para TODAS as outras colunas de creditcard_transactions)...
COMMENT ON COLUMN public.creditcard_transactions.creditcard_transactions_last_update IS 'Timestamp da criação ou última atualização manual desta transação de cartão.';

-- Tabela: creditcard_installments
CREATE TABLE public.creditcard_installments (
    creditcard_installments_id character varying(50) NOT NULL,
    creditcard_installments_transaction_id character varying(50) NOT NULL,
    creditcard_installments_invoice_id character varying(50) NOT NULL,
    creditcard_installments_number integer NOT NULL CHECK (creditcard_installments_number >= 1 AND creditcard_installments_number <= 420),
    creditcard_installments_statement_month public.month_enum NOT NULL,
    creditcard_installments_statement_year integer NOT NULL CHECK (creditcard_installments_statement_year >= 2020),
    creditcard_installments_observations text,
    creditcard_installments_base_value numeric(15, 2) NOT NULL,
    creditcard_installments_fees_taxes numeric(15, 2) NOT NULL DEFAULT 0,
    creditcard_installments_subtotal numeric(15, 2) GENERATED ALWAYS AS (creditcard_installments_base_value + creditcard_installments_fees_taxes) STORED,
    creditcard_installments_total_effective numeric(15, 2) GENERATED ALWAYS AS ((creditcard_installments_base_value + creditcard_installments_fees_taxes) * -1) STORED,
    creditcard_installments_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT creditcard_installments_pkey PRIMARY KEY (creditcard_installments_id),
    CONSTRAINT fk_ccinstall_transaction FOREIGN KEY (creditcard_installments_transaction_id) REFERENCES public.creditcard_transactions(creditcard_transactions_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_ccinstall_invoice FOREIGN KEY (creditcard_installments_invoice_id) REFERENCES public.creditcard_invoices(creditcard_invoices_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT uq_ccinstall_trans_num UNIQUE (creditcard_installments_transaction_id, creditcard_installments_number)
);
ALTER TABLE public.creditcard_installments OWNER TO "SisFinance-adm";
COMMENT ON TABLE public.creditcard_installments IS 'Detalha cada parcela individual de uma transação de cartão de crédito que foi parcelada.';
COMMENT ON COLUMN public.creditcard_installments.creditcard_installments_id IS 'Identificador único da parcela (PK, fornecido externamente).';
-- ... (Adicionar comentários para TODAS as outras colunas de creditcard_installments)...
COMMENT ON COLUMN public.creditcard_installments.creditcard_installments_last_update IS 'Timestamp da criação ou última atualização manual desta parcela.';


-- ====================================================================
-- FASE 4: CRIAR ÍNDICES E TRIGGERS DE IMUTABILIDADE DE PK
-- ====================================================================

-- Índice único parcial para operators
CREATE UNIQUE INDEX IF NOT EXISTS uq_operators_priority_true_per_user
ON public.operators (operators_user_id)
WHERE operators_priority IS TRUE;
COMMENT ON INDEX public.uq_operators_priority_true_per_user IS 'Garante que um usuário possa ter apenas um operador marcado como prioritário.';

-- Índices Estratégicos (Lista Completa)
COMMENT ON TABLE public.operators IS 'Índices: PK(operators_id), UNIQUE(operators_name), FK(operators_user_id), Partial UNIQUE(user_id WHERE priority). Adicional: idx_operators_user_id.';
CREATE INDEX IF NOT EXISTS idx_operators_user_id ON public.operators (operators_user_id);
COMMENT ON INDEX public.idx_operators_user_id IS 'Acelera a busca de operadores por usuário.';

COMMENT ON TABLE public.recurrence_saldo IS 'Índices: PK(recurrence_saldo_id), FKs (user_id, user_account_id, etc). Adicionais: idx_recurr_saldo_user_id, idx_recurr_saldo_user_account_id, idx_recurr_saldo_status.';
CREATE INDEX IF NOT EXISTS idx_recurr_saldo_user_id ON public.recurrence_saldo (recurrence_saldo_user_id);
COMMENT ON INDEX public.idx_recurr_saldo_user_id IS 'Acelera a busca de recorrências de saldo por usuário.';
CREATE INDEX IF NOT EXISTS idx_recurr_saldo_user_account_id ON public.recurrence_saldo (recurrence_saldo_user_account_id);
COMMENT ON INDEX public.idx_recurr_saldo_user_account_id IS 'Acelera a busca de recorrências de saldo por conta de usuário.';
CREATE INDEX IF NOT EXISTS idx_recurr_saldo_status ON public.recurrence_saldo (recurrence_saldo_status);
COMMENT ON INDEX public.idx_recurr_saldo_status IS 'Acelera a busca por recorrências de saldo ativas/inativas.';

COMMENT ON TABLE public.transactions_saldo IS 'Índices: PK(id), FKs (user_accounts_id, category_id, recurrence_id, etc). Adicionais: idx_trans_saldo_user_account, idx_trans_saldo_status, idx_trans_saldo_impl_datetime, idx_trans_saldo_category_id, idx_trans_saldo_recurrence_id (parcial).';
CREATE INDEX IF NOT EXISTS idx_trans_saldo_user_account ON public.transactions_saldo (transactions_saldo_user_accounts_id);
COMMENT ON INDEX public.idx_trans_saldo_user_account IS 'Acelera JOINs e filtros pela conta do usuário (essencial para cálculo de saldo).';
CREATE INDEX IF NOT EXISTS idx_trans_saldo_status ON public.transactions_saldo (transactions_saldo_status);
COMMENT ON INDEX public.idx_trans_saldo_status IS 'Acelera filtros por status da transação de saldo (ex: Efetuado para saldo).';
CREATE INDEX IF NOT EXISTS idx_trans_saldo_impl_datetime ON public.transactions_saldo (transactions_saldo_implementation_datetime);
COMMENT ON INDEX public.idx_trans_saldo_impl_datetime IS 'Acelera filtros e ordenação por data de implementação da transação de saldo.';
CREATE INDEX IF NOT EXISTS idx_trans_saldo_category_id ON public.transactions_saldo (transactions_saldo_category_id);
COMMENT ON INDEX public.idx_trans_saldo_category_id IS 'Acelera filtros e agrupamentos por categoria em transações de saldo.';
CREATE INDEX IF NOT EXISTS idx_trans_saldo_recurrence_id ON public.transactions_saldo (transactions_saldo_recurrence_id) WHERE transactions_saldo_recurrence_id IS NOT NULL;
COMMENT ON INDEX public.idx_trans_saldo_recurrence_id IS 'Índice parcial para buscar transações de saldo geradas por recorrências específicas.';

COMMENT ON TABLE public.creditcards IS 'Índices: PK(creditcards_id), FK(financial_institutions_id). Adicional: idx_cc_fin_inst_id.';
CREATE INDEX IF NOT EXISTS idx_cc_fin_inst_id ON public.creditcards (creditcards_financial_institutions_id);
COMMENT ON INDEX public.idx_cc_fin_inst_id IS 'Acelera busca de cartões de crédito por instituição financeira.';

COMMENT ON TABLE public.user_creditcards IS 'Índices: PK(id), UNIQUE(user_id, card_id), FK(payment_user_account_id). Adicionais: idx_user_cc_status, idx_user_cc_payment_account.';
CREATE INDEX IF NOT EXISTS idx_user_cc_status ON public.user_creditcards (user_creditcards_status);
COMMENT ON INDEX public.idx_user_cc_status IS 'Acelera filtros por cartões de usuário ativos/inativos.';
CREATE INDEX IF NOT EXISTS idx_user_cc_payment_account ON public.user_creditcards (user_creditcards_payment_user_account_id);
COMMENT ON INDEX public.idx_user_cc_payment_account IS 'Acelera busca por cartões de usuário ligados a uma conta de pagamento específica.';

COMMENT ON TABLE public.creditcard_invoices IS 'Índices: PK(id), UNIQUE(user_card_id, period). Adicionais: idx_cc_invoice_status, idx_cc_invoice_due_date.';
CREATE INDEX IF NOT EXISTS idx_cc_invoice_status ON public.creditcard_invoices (creditcard_invoices_status);
COMMENT ON INDEX public.idx_cc_invoice_status IS 'Acelera filtros por status da fatura de cartão (Aberta, Paga, etc.).';
CREATE INDEX IF NOT EXISTS idx_cc_invoice_due_date ON public.creditcard_invoices (creditcard_invoices_due_date);
COMMENT ON INDEX public.idx_cc_invoice_due_date IS 'Acelera filtros e ordenação por data de vencimento da fatura.';

COMMENT ON TABLE public.recurrence_creditcard IS 'Índices: PK(id), FKs (user_card_id, etc). Adicionais: idx_recurr_cc_user_card_id, idx_recurr_cc_status.';
CREATE INDEX IF NOT EXISTS idx_recurr_cc_user_card_id ON public.recurrence_creditcard (creditcard_recurrence_user_card_id);
COMMENT ON INDEX public.idx_recurr_cc_user_card_id IS 'Acelera busca de recorrências de cartão por cartão de usuário.';
CREATE INDEX IF NOT EXISTS idx_recurr_cc_status ON public.recurrence_creditcard (creditcard_recurrence_status);
COMMENT ON INDEX public.idx_recurr_cc_status IS 'Acelera busca por recorrências de cartão ativas/inativas.';

COMMENT ON TABLE public.creditcard_transactions IS 'Índices: PK(id), FKs (user_card_id, invoice_id - parcial, category_id, recurrence_id - parcial, etc). Adicionais: idx_cctrans_user_card, idx_cctrans_invoice, idx_cctrans_impl_datetime, idx_cctrans_statement_period, idx_cctrans_category_id, idx_cctrans_recurrence_id.';
CREATE INDEX IF NOT EXISTS idx_cctrans_user_card ON public.creditcard_transactions (creditcard_transactions_user_card_id);
COMMENT ON INDEX public.idx_cctrans_user_card IS 'Acelera busca de transações de cartão por cartão de usuário.';
CREATE INDEX IF NOT EXISTS idx_cctrans_invoice ON public.creditcard_transactions (creditcard_transactions_invoice_id) WHERE creditcard_transactions_invoice_id IS NOT NULL;
COMMENT ON INDEX public.idx_cctrans_invoice IS 'Índice parcial para buscar transações de cartão por fatura (importante para calcular valor fatura).';
CREATE INDEX IF NOT EXISTS idx_cctrans_impl_datetime ON public.creditcard_transactions (creditcard_transactions_implementation_datetime);
COMMENT ON INDEX public.idx_cctrans_impl_datetime IS 'Acelera filtros/ordenação por data da transação de cartão.';
CREATE INDEX IF NOT EXISTS idx_cctrans_statement_period ON public.creditcard_transactions (creditcard_transactions_statement_year, creditcard_transactions_statement_month);
COMMENT ON INDEX public.idx_cctrans_statement_period IS 'Acelera filtros/agrupamentos por período da fatura para transações de cartão.';
CREATE INDEX IF NOT EXISTS idx_cctrans_category_id ON public.creditcard_transactions (creditcard_transactions_category_id);
COMMENT ON INDEX public.idx_cctrans_category_id IS 'Acelera filtros/agrupamentos por categoria em transações de cartão.';
CREATE INDEX IF NOT EXISTS idx_cctrans_recurrence_id ON public.creditcard_transactions (creditcard_transactions_recurrence_id) WHERE creditcard_transactions_recurrence_id IS NOT NULL;
COMMENT ON INDEX public.idx_cctrans_recurrence_id IS 'Índice parcial para buscar transações de cartão geradas por recorrências específicas de cartão.';

COMMENT ON TABLE public.creditcard_installments IS 'Índices: PK(id), UNIQUE(transaction_id, number), FK(invoice_id). Adicionais: idx_ccinstall_invoice, idx_ccinstall_statement_period.';
CREATE INDEX IF NOT EXISTS idx_ccinstall_invoice ON public.creditcard_installments (creditcard_installments_invoice_id);
COMMENT ON INDEX public.idx_ccinstall_invoice IS 'Acelera busca de parcelas por fatura (importante para calcular valor fatura).';
CREATE INDEX IF NOT EXISTS idx_ccinstall_statement_period ON public.creditcard_installments (creditcard_installments_statement_year, creditcard_installments_statement_month);
COMMENT ON INDEX public.idx_ccinstall_statement_period IS 'Acelera filtros/agrupamentos por período da fatura para parcelas.';


-- Triggers de Imutabilidade de PK (Aplicar para TODAS as 18 tabelas)
CREATE TRIGGER trigger_prevent_users_pk_update BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('users_id');
COMMENT ON TRIGGER trigger_prevent_users_pk_update ON public.users IS 'Impede a alteração da chave primária users_id.';
CREATE TRIGGER trigger_prevent_categories_pk_update BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('categories_id');
COMMENT ON TRIGGER trigger_prevent_categories_pk_update ON public.categories IS 'Impede a alteração da chave primária categories_id.';
CREATE TRIGGER trigger_prevent_proceedings_pk_update BEFORE UPDATE ON public.proceedings_saldo FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('proceedings_id');
COMMENT ON TRIGGER trigger_prevent_proceedings_pk_update ON public.proceedings_saldo IS 'Impede a alteração da chave primária proceedings_id.';
CREATE TRIGGER trigger_prevent_fin_inst_pk_update BEFORE UPDATE ON public.financial_institutions FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('financial_institutions_id');
COMMENT ON TRIGGER trigger_prevent_fin_inst_pk_update ON public.financial_institutions IS 'Impede a alteração da chave primária financial_institutions_id.';
CREATE TRIGGER trigger_prevent_acc_types_pk_update BEFORE UPDATE ON public.account_types FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('account_types_id');
COMMENT ON TRIGGER trigger_prevent_acc_types_pk_update ON public.account_types IS 'Impede a alteração da chave primária account_types_id.';
CREATE TRIGGER trigger_prevent_inst_acc_pk_update BEFORE UPDATE ON public.institution_accounts FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('institution_accounts_id');
COMMENT ON TRIGGER trigger_prevent_inst_acc_pk_update ON public.institution_accounts IS 'Impede a alteração da chave primária institution_accounts_id.';
CREATE TRIGGER trigger_prevent_operators_pk_update BEFORE UPDATE ON public.operators FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('operators_id');
COMMENT ON TRIGGER trigger_prevent_operators_pk_update ON public.operators IS 'Impede a alteração da chave primária operators_id.';
CREATE TRIGGER trigger_prevent_user_acc_pk_update BEFORE UPDATE ON public.user_accounts FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('user_accounts_id');
COMMENT ON TRIGGER trigger_prevent_user_acc_pk_update ON public.user_accounts IS 'Impede a alteração da chave primária user_accounts_id.';
CREATE TRIGGER trigger_prevent_uapix_pk_update BEFORE UPDATE ON public.user_accounts_pix_keys FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('user_accounts_pix_keys_id');
COMMENT ON TRIGGER trigger_prevent_uapix_pk_update ON public.user_accounts_pix_keys IS 'Impede a alteração da chave primária user_accounts_pix_keys_id.';
CREATE TRIGGER trigger_prevent_recurr_saldo_pk_update BEFORE UPDATE ON public.recurrence_saldo FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('recurrence_saldo_id');
COMMENT ON TRIGGER trigger_prevent_recurr_saldo_pk_update ON public.recurrence_saldo IS 'Impede a alteração da chave primária recurrence_saldo_id.';
CREATE TRIGGER trigger_prevent_trans_saldo_pk_update BEFORE UPDATE ON public.transactions_saldo FOR EACH ROW EXECUTE FUNCTION public.prevent_transactions_pk_update_conditional(); -- Específico
COMMENT ON TRIGGER trigger_prevent_trans_saldo_pk_update ON public.transactions_saldo IS 'Impede condicionalmente a alteração da PK transactions_saldo_id.';
CREATE TRIGGER trigger_prevent_internal_transfers_pk_update BEFORE UPDATE ON public.internal_transfers FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('internal_transfers_id');
COMMENT ON TRIGGER trigger_prevent_internal_transfers_pk_update ON public.internal_transfers IS 'Impede a alteração da chave primária internal_transfers_id.';
CREATE TRIGGER trigger_prevent_cc_pk_update BEFORE UPDATE ON public.creditcards FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcards_id');
COMMENT ON TRIGGER trigger_prevent_cc_pk_update ON public.creditcards IS 'Impede a alteração da chave primária creditcards_id.';
CREATE TRIGGER trigger_prevent_user_cc_pk_update BEFORE UPDATE ON public.user_creditcards FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('user_creditcards_id');
COMMENT ON TRIGGER trigger_prevent_user_cc_pk_update ON public.user_creditcards IS 'Impede a alteração da chave primária user_creditcards_id.';
CREATE TRIGGER trigger_prevent_cc_invoice_pk_update BEFORE UPDATE ON public.creditcard_invoices FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_invoices_id');
COMMENT ON TRIGGER trigger_prevent_cc_invoice_pk_update ON public.creditcard_invoices IS 'Impede a alteração da chave primária creditcard_invoices_id.';
CREATE TRIGGER trigger_prevent_recurr_cc_pk_update BEFORE UPDATE ON public.recurrence_creditcard FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_recurrence_id');
COMMENT ON TRIGGER trigger_prevent_recurr_cc_pk_update ON public.recurrence_creditcard IS 'Impede a alteração da chave primária creditcard_recurrence_id.';
CREATE TRIGGER trigger_prevent_cctrans_pk_update BEFORE UPDATE ON public.creditcard_transactions FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_transactions_id');
COMMENT ON TRIGGER trigger_prevent_cctrans_pk_update ON public.creditcard_transactions IS 'Impede a alteração da chave primária creditcard_transactions_id.';
CREATE TRIGGER trigger_prevent_ccinstall_pk_update BEFORE UPDATE ON public.creditcard_installments FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_installments_id');
COMMENT ON TRIGGER trigger_prevent_ccinstall_pk_update ON public.creditcard_installments IS 'Impede a alteração da chave primária creditcard_installments_id.';

-- Trigger para internal_transfers
CREATE TRIGGER trigger_sync_internal_transfer
AFTER INSERT OR UPDATE OR DELETE ON public.internal_transfers
FOR EACH ROW EXECUTE FUNCTION public.sync_internal_transfer_to_transactions();
COMMENT ON TRIGGER trigger_sync_internal_transfer ON public.internal_transfers IS 'Dispara a função sync_internal_transfer_to_transactions após operações DML em internal_transfers para manter transactions_saldo sincronizada.';


-- ====================================================================
-- FASE 5: CRIAR VIEW
-- ====================================================================
CREATE OR REPLACE VIEW public.view_user_account_balances AS
SELECT
    ua.user_accounts_id,
    ua.user_accounts_user_id AS user_id,
    ua.user_accounts_institution_account_id,
    ua.user_accounts_agency,
    ua.user_accounts_number,
    ia.institution_accounts_institution_id,
    ia.institution_accounts_type_id,
    ia.institution_accounts_product_name,
    ia.institution_accounts_processing_info,
    COALESCE(SUM(t.transactions_saldo_total_effective), 0.00) AS calculated_balance
FROM
    public.user_accounts ua
JOIN
    public.institution_accounts ia ON ua.user_accounts_institution_account_id = ia.institution_accounts_id
LEFT JOIN
    public.transactions_saldo t ON ua.user_accounts_id = t.transactions_saldo_user_accounts_id
                               AND t.transactions_saldo_status = 'Efetuado'::public.status
GROUP BY
    ua.user_accounts_id,
    ua.user_accounts_user_id,
    ua.user_accounts_institution_account_id,
    ua.user_accounts_agency,
    ua.user_accounts_number,
    ia.institution_accounts_institution_id,
    ia.institution_accounts_type_id,
    ia.institution_accounts_product_name,
    ia.institution_accounts_processing_info;

ALTER VIEW public.view_user_account_balances OWNER TO "SisFinance-adm";
COMMENT ON VIEW public.view_user_account_balances IS 'Visão que calcula o saldo atual (`calculated_balance`) para cada conta de usuário (`user_accounts`), buscando detalhes do produto (`institution_accounts`) e somando as transações de saldo efetuadas.';

-- =============================================================================
-- FIM DO SCRIPT DE CRIAÇÃO
-- =============================================================================