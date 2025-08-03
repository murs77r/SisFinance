-- =============================================================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS "SisFinance" COM SCHEMAS
-- =============================================================================
-- Proprietário Padrão dos Objetos: "SisFinance-adm"
-- Nome do Banco de Dados: "SisFinance"
-- Descrição: Banco de dados para o sistema de controle financeiro pessoal SisFinance, abrangendo todas as funcionalidades de gestão de contas, transações, cartões de crédito e recorrências.

-- =============================================================================
-- CRIAÇÃO DOS SCHEMAS "core", "transactions" e "auditoria"
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS core;
COMMENT ON SCHEMA core IS 'Schema para armazenar as entidades fundamentais do sistema, como usuários, categorias e instituições financeiras';

CREATE SCHEMA IF NOT EXISTS transactions;
COMMENT ON SCHEMA transactions IS 'Schema para armazenar as entidades relacionadas a transações financeiras, recorrências e faturas';

CREATE SCHEMA IF NOT EXISTS auditoria;
COMMENT ON SCHEMA auditoria IS 'Schema para armazenar logs de auditoria das modificações nos dados do sistema';


-- Garantir que o proprietário padrão tenha os privilégios necessários
ALTER SCHEMA core OWNER TO "SisFinance-adm";
ALTER SCHEMA transactions OWNER TO "SisFinance-adm";
ALTER SCHEMA auditoria OWNER TO "SisFinance-adm";

-- Função genérica para prevenir atualização de chaves primárias
CREATE OR REPLACE FUNCTION public.prevent_generic_pk_update()
RETURNS TRIGGER AS $$
DECLARE
    pk_column_name TEXT := TG_ARGV[0];
    old_value TEXT;
    new_value TEXT;
BEGIN
    -- Impede a atualização da chave primária
    IF TG_OP = 'UPDATE' THEN
        EXECUTE format('SELECT ($1).%I::TEXT', pk_column_name) USING OLD INTO old_value;
        EXECUTE format('SELECT ($1).%I::TEXT', pk_column_name) USING NEW INTO new_value;
        
        IF old_value <> new_value THEN
            RAISE EXCEPTION 'Atualização de chave primária não permitida: %', pk_column_name;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.prevent_generic_pk_update() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.prevent_generic_pk_update() IS 'Função genérica para prevenir atualização de chaves primárias.';

-- =============================================================================
-- CRIAÇÃO DOS TIPOS ENUM
-- =============================================================================

-- Tipo de Usuário
CREATE TYPE core.user_type AS ENUM ('Administrador', 'Usuário');
ALTER TYPE core.user_type OWNER TO "SisFinance-adm";
COMMENT ON TYPE core.user_type IS 'Define os papéis possíveis para um usuário no sistema (Ex: Administrador com acesso total, Usuário com acesso limitado aos seus próprios dados).';

-- Status da Conta do Usuário
CREATE TYPE core.user_account_status AS ENUM ('Ativo', 'Inativo', 'Pendente');
ALTER TYPE core.user_account_status OWNER TO "SisFinance-adm";
COMMENT ON TYPE core.user_account_status IS 'Define os estados possíveis para a conta de um usuário (Ex: Ativo para uso normal, Inativo para suspenso, Pendente para aguardando confirmação).';

-- Tipo de Chave PIX
CREATE TYPE core.pix_key_type AS ENUM ('CPF', 'E-mail', 'Telefone', 'Aleatória');
ALTER TYPE core.pix_key_type OWNER TO "SisFinance-adm";
COMMENT ON TYPE core.pix_key_type IS 'Define os tipos possíveis de chaves PIX (CPF, E-mail, Telefone, Aleatória).';

-- Operação Financeira (Crédito/Débito)
CREATE TYPE core.operation AS ENUM ('Crédito', 'Débito');
ALTER TYPE core.operation OWNER TO "SisFinance-adm";
COMMENT ON TYPE core.operation IS 'Define a natureza financeira de uma transação, categoria ou recorrência, indicando se representa uma entrada (Crédito) ou saída (Débito) de valor.';

-- Tipo de Conta Financeira
CREATE TYPE core.account_type AS ENUM ('Conta Corrente', 'Conta Poupança', 'Conta de Pagamento', 'Conta de Benefícios', 'Conta de Custódia');
ALTER TYPE core.account_type OWNER TO "SisFinance-adm";
COMMENT ON TYPE core.account_type IS 'Classifica os diferentes tipos de produtos financeiros que um usuário pode possuir ou que uma instituição pode oferecer.';

-- Status da Recorrência (Ativo/Inativo)
CREATE TYPE transactions.recurrence_status_ai AS ENUM ('Ativo', 'Inativo');
ALTER TYPE transactions.recurrence_status_ai OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.recurrence_status_ai IS 'Define se um agendamento de recorrência está atualmente ativo (gerando transações) ou inativo (pausado).';

-- Tipo da Recorrência (Determinada/Indeterminada)
CREATE TYPE transactions.recurrence_type AS ENUM ('Determinado', 'Indeterminado');
ALTER TYPE transactions.recurrence_type OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.recurrence_type IS 'Define se uma recorrência possui uma data de término específica (Determinada) ou se continua indefinidamente (Indeterminada).';

-- Frequência da Recorrência
CREATE TYPE transactions.recurrence_frequency AS ENUM ('Semanal', 'Mensal', 'Bimestral', 'Trimestral', 'Semestral', 'Anual');
ALTER TYPE transactions.recurrence_frequency OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.recurrence_frequency IS 'Define a periodicidade com que uma transação recorrente deve ocorrer.';

-- Status da Transação
CREATE TYPE transactions.status AS ENUM ('Efetuado', 'Pendente');
ALTER TYPE transactions.status OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.status IS 'Define o estado de uma transação financeira, indicando se foi concluída (Efetuado) ou está aguardando realização (Pendente).';

-- Método de Pagamento de Fatura de Cartão
CREATE TYPE transactions.payment_method AS ENUM ('Débito Automático', 'Boleto');
ALTER TYPE transactions.payment_method OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.payment_method IS 'Define as formas pelas quais uma fatura de cartão de crédito pode ser liquidada.';

-- Procedimento em Fatura de Cartão
CREATE TYPE transactions.creditcard_transaction_procedure AS ENUM ('Crédito em Fatura', 'Débito em Fatura');
ALTER TYPE transactions.creditcard_transaction_procedure OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.creditcard_transaction_procedure IS 'Define a natureza de uma transação individual dentro de uma fatura de cartão de crédito (impacto no saldo da fatura).';

-- Meses do Ano
CREATE TYPE transactions.month_enum AS ENUM ('Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro');
ALTER TYPE transactions.month_enum OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.month_enum IS 'Enumeração dos meses do ano, utilizada para referência em lançamentos de fatura e parcelas.';

-- Status da Fatura de Cartão
CREATE TYPE transactions.invoice_status AS ENUM ('Aberta', 'Fechada', 'Paga', 'Paga Parcialmente', 'Vencida');
ALTER TYPE transactions.invoice_status OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.invoice_status IS 'Representa os diferentes estágios do ciclo de vida de uma fatura de cartão de crédito.';

-- Tipo de Ação para Auditoria
CREATE TYPE auditoria.action_type AS ENUM ('INSERT', 'UPDATE', 'DELETE');
ALTER TYPE auditoria.action_type OWNER TO "SisFinance-adm";
COMMENT ON TYPE auditoria.action_type IS 'Define o tipo de operação realizada nos dados que está sendo registrada no log de auditoria.';


-- Escolha Temporal do Relatório
CREATE TYPE transactions.report_time_choice AS ENUM ('Por Lançamento', 'Por Data', 'Por Período');
ALTER TYPE transactions.report_time_choice OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.report_time_choice IS 'Define o tipo de filtro temporal utilizado no relatório de transações (Ex: Por Lançamento para períodos de competência, Por Data para datas específicas, Por Período para intervalos relativos).';

-- Tipo do Relatório
CREATE TYPE transactions.report_type AS ENUM ('Cartão de Crédito', 'Saldo', 'Saldo e Cartão de Crédito');
ALTER TYPE transactions.report_type OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.report_type IS 'Define o escopo das transações incluídas no relatório (Ex: apenas cartão, apenas saldo, ou ambos tipos de transação).';

-- Período Relativo
CREATE TYPE transactions.report_relative_period AS ENUM ('3 dias', '7 dias', '15 dias', '30 dias', 'Último Mês', 'Últimos 3 meses', 'Últimos 6 meses', 'Último 1 ano', 'Último Ano');
ALTER TYPE transactions.report_relative_period OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.report_relative_period IS 'Define períodos relativos à data atual para filtros temporais dinâmicos em relatórios de transações.';

-- Frequência de Geração Automática
CREATE TYPE transactions.report_auto_frequency AS ENUM ('Mensalmente', 'Bimestralmente', 'Trimestralmente', 'Semestralmente', 'Anualmente');
ALTER TYPE transactions.report_auto_frequency OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.report_auto_frequency IS 'Define a periodicidade com que um relatório automático deve ser gerado e enviado.';

-- Status de Recorrência do Relatório
CREATE TYPE transactions.report_recurring_status AS ENUM ('Ativado', 'Desativado');
ALTER TYPE transactions.report_recurring_status OWNER TO "SisFinance-adm";
COMMENT ON TYPE transactions.report_recurring_status IS 'Define se um relatório com geração automática está atualmente ativo (gerando relatórios) ou desativado (pausado).';

-- =============================================================================
-- FUNÇÕES AUXILIARES BÁSICAS
-- =============================================================================

CREATE OR REPLACE FUNCTION core.validate_email_format(email_input TEXT)
RETURNS TEXT AS $$
DECLARE
    clean_email TEXT;
BEGIN
    -- Normalização: trim e lowercase
    clean_email := lower(trim(email_input));
    
    -- Verifica formato básico de e-mail usando regex
    IF NOT (clean_email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN
        RAISE EXCEPTION 'E-mail inválido: formato incorreto. E-mail informado: %', email_input;
    END IF;
    
    -- Verifica se o e-mail não é muito longo (máximo 254 caracteres conforme RFC)
    IF length(clean_email) > 254 THEN
        RAISE EXCEPTION 'E-mail inválido: muito longo (máximo 254 caracteres). E-mail informado: %', email_input;
    END IF;
    
    -- Verifica se não tem pontos consecutivos
    IF clean_email ~ '\.\.' THEN
        RAISE EXCEPTION 'E-mail inválido: não pode conter pontos consecutivos. E-mail informado: %', email_input;
    END IF;
    
    -- Verifica se não começa ou termina com ponto
    IF clean_email ~ '^\.|\.$' THEN
        RAISE EXCEPTION 'E-mail inválido: não pode começar ou terminar com ponto. E-mail informado: %', email_input;
    END IF;
    
    RETURN clean_email;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
ALTER FUNCTION core.validate_email_format(TEXT) OWNER TO "SisFinance-adm";

-- =============================================================================
-- TABELAS DE AUDITORIA NECESSÁRIAS
-- =============================================================================

-- Tabela de auditoria para o schema core
CREATE TABLE IF NOT EXISTS auditoria.core_audit_log (
    audit_id character varying(50) NOT NULL,
    table_name character varying(100) NOT NULL,
    record_id character varying(50) NOT NULL,
    action_type auditoria.action_type NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by character varying(100) NOT NULL,
    changed_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT core_audit_log_pkey PRIMARY KEY (audit_id)
);
ALTER TABLE auditoria.core_audit_log OWNER TO "SisFinance-adm";
COMMENT ON TABLE auditoria.core_audit_log IS 'Log de auditoria para todas as tabelas do schema core.';

-- Tabela de auditoria para o schema transactions
CREATE TABLE IF NOT EXISTS auditoria.transactions_audit_log (
    audit_id character varying(50) NOT NULL,
    table_name character varying(100) NOT NULL,
    record_id character varying(50) NOT NULL,
    action_type auditoria.action_type NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by character varying(100) NOT NULL,
    changed_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transactions_audit_log_pkey PRIMARY KEY (audit_id)
);
ALTER TABLE auditoria.transactions_audit_log OWNER TO "SisFinance-adm";
COMMENT ON TABLE auditoria.transactions_audit_log IS 'Log de auditoria para todas as tabelas do schema transactions.';

-- =============================================================================
-- FUNÇÕES AUXILIARES NECESSÁRIAS PARA O SISTEMA
-- =============================================================================

-- Função genérica para log de auditoria do schema core
CREATE OR REPLACE FUNCTION public.log_core_audit()
RETURNS TRIGGER AS $$
DECLARE
    pk_column_name TEXT := TG_ARGV[0];
    audit_row RECORD;
    pk_value TEXT;
BEGIN
    -- Obter o valor da chave primária
    IF TG_OP = 'DELETE' THEN
        EXECUTE format('SELECT ($1).%I::TEXT', pk_column_name) USING OLD INTO pk_value;
        audit_row := OLD;
    ELSE
        EXECUTE format('SELECT ($1).%I::TEXT', pk_column_name) USING NEW INTO pk_value;
        audit_row := NEW;
    END IF;

    -- Inserir registro de auditoria
    INSERT INTO auditoria.core_audit_log (
        audit_id,
        table_name,
        record_id,
        action_type,
        old_values,
        new_values,
        changed_by,
        changed_at
    ) VALUES (
        gen_random_uuid()::TEXT,
        TG_TABLE_NAME,
        pk_value,
        TG_OP::auditoria.action_type,
        CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN row_to_json(NEW) ELSE NULL END,
        current_user,
        CURRENT_TIMESTAMP
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.log_core_audit() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.log_core_audit() IS 'Função genérica para log de auditoria do schema core.';

-- Função genérica para log de auditoria do schema transactions (CORRIGIDA)
CREATE OR REPLACE FUNCTION public.log_transactions_audit()
RETURNS TRIGGER AS $$
DECLARE
    pk_column_name TEXT := TG_ARGV[0];
    audit_row RECORD;
    pk_value TEXT;
BEGIN
    -- Obter o valor da chave primária
    IF TG_OP = 'DELETE' THEN
        EXECUTE format('SELECT ($1).%I::TEXT', pk_column_name) USING OLD INTO pk_value;
        audit_row := OLD;
    ELSE
        EXECUTE format('SELECT ($1).%I::TEXT', pk_column_name) USING NEW INTO pk_value;
        audit_row := NEW;
    END IF;

    -- Inserir registro de auditoria
    INSERT INTO auditoria.transactions_audit_log (
        audit_id,
        table_name,
        record_id,
        action_type,
        old_values,
        new_values,
        changed_by,
        changed_at
    ) VALUES (
        gen_random_uuid()::TEXT,
        TG_TABLE_NAME,
        pk_value,
        TG_OP::auditoria.action_type,
        CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN row_to_json(NEW) ELSE NULL END,
        current_user,
        CURRENT_TIMESTAMP
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.log_transactions_audit() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.log_transactions_audit() IS 'Função genérica para log de auditoria do schema transactions.';

-- =============================================================================
-- CRIAÇÃO DAS TABELAS DO SCHEMA "core"
-- =============================================================================

-- Tabela: users
CREATE TABLE core.users (
    users_id character varying(50) NOT NULL,
    users_first_name character varying(100) NOT NULL,
    users_last_name character varying(100) NULL,
    users_profile_picture_url text NULL,
    users_email character varying(255) NOT NULL,
    users_phone character varying(50) NULL,
    users_type core.user_type NOT NULL,
    users_status core.user_account_status NOT NULL DEFAULT 'Ativo',
    users_creation_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    users_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_pkey PRIMARY KEY (users_id),
    CONSTRAINT users_email_key UNIQUE (users_email),
    CONSTRAINT chk_users_email_format CHECK (
    core.validate_email_format(users_email) IS NOT NULL
    AND lower(users_email) = users_email
)
);
ALTER TABLE core.users OWNER to "SisFinance-adm";
COMMENT ON TABLE core.users IS 'Armazena informações sobre os usuários do sistema.';
COMMENT ON COLUMN core.users.users_id IS 'Identificador único e exclusivo para cada usuário (PK, fornecido externamente).';
COMMENT ON COLUMN core.users.users_first_name IS 'Primeiro nome do usuário.';
COMMENT ON COLUMN core.users.users_last_name IS 'Sobrenome(s) do usuário (opcional).';
COMMENT ON COLUMN core.users.users_profile_picture_url IS 'URL para uma imagem de perfil/avatar do usuário (opcional).';
COMMENT ON COLUMN core.users.users_email IS 'Endereço de e-mail principal do usuário (único e obrigatório).';
COMMENT ON COLUMN core.users.users_phone IS 'Número de telefone do usuário (opcional).';
COMMENT ON COLUMN core.users.users_type IS 'Define o papel do usuário no sistema (Administrador ou Usuário), utilizando o tipo ENUM user_type.';
COMMENT ON COLUMN core.users.users_status IS 'Indica o estado atual da conta do usuário (Ativo, Inativo, Pendente), utilizando o tipo ENUM user_account_status. Padrão: Ativo.';
COMMENT ON COLUMN core.users.users_creation_datetime IS 'Data e hora exatas (UTC) em que o registro do usuário foi criado. Preenchido automaticamente no INSERT.';
COMMENT ON COLUMN core.users.users_last_update IS 'Data e hora exatas (UTC) da última modificação manual neste registro de usuário. Preenchido no INSERT, requer atualização manual/via AppSheet.';

-- Tabela: categories
CREATE TABLE core.categories (
    categories_id character varying(50) NOT NULL,
    categories_name character varying(100) NOT NULL,
    categories_credit boolean NOT NULL DEFAULT false,
    categories_debit boolean NOT NULL DEFAULT false,
    CONSTRAINT categories_pkey PRIMARY KEY (categories_id),
    CONSTRAINT categories_category_name_key UNIQUE (categories_name),
    CONSTRAINT chk_categories_at_least_one_type CHECK (categories_credit IS TRUE OR categories_debit IS TRUE)
);
ALTER TABLE core.categories OWNER to "SisFinance-adm";

COMMENT ON TABLE core.categories IS 'Catálogo de categorias para classificar transações e recorrências, indicando se são aplicáveis a operações de crédito, débito ou ambas.';
COMMENT ON COLUMN core.categories.categories_id IS 'Identificador único da categoria (PK, fornecido externamente).';
COMMENT ON COLUMN core.categories.categories_name IS 'Nome descritivo e único da categoria (Ex: Salário, Moradia).';
COMMENT ON COLUMN core.categories.categories_credit IS 'Flag booleana que indica se esta categoria pode ser associada a operações de Crédito (entrada de valor). Padrão: FALSE.';
COMMENT ON COLUMN core.categories.categories_debit IS 'Flag booleana que indica se esta categoria pode ser associada a operações de Débito (saída de valor). Padrão: FALSE.';
COMMENT ON CONSTRAINT chk_categories_at_least_one_type ON core.categories IS 'Garante que cada categoria seja aplicável a pelo menos um tipo de operação (crédito ou débito).';

-- Tabela: proceedings_saldo
CREATE TABLE core.proceedings_saldo (
    proceedings_id character varying(50) NOT NULL,
    proceedings_name character varying(100) NOT NULL,
    proceedings_credit boolean NOT NULL DEFAULT false,
    proceedings_debit boolean NOT NULL DEFAULT false,
    CONSTRAINT proceedings_saldo_pkey PRIMARY KEY (proceedings_id),
    CONSTRAINT proceedings_saldo_name_key UNIQUE (proceedings_name),
    CONSTRAINT chk_proceedings_saldo_type CHECK (proceedings_credit IS TRUE OR proceedings_debit IS TRUE)
);
ALTER TABLE core.proceedings_saldo OWNER to "SisFinance-adm";

COMMENT ON TABLE core.proceedings_saldo IS 'Catálogo dos métodos ou instrumentos utilizados em transações de saldo (Ex: PIX, Boleto, Compra no Débito).';
COMMENT ON COLUMN core.proceedings_saldo.proceedings_id IS 'Identificador único do procedimento (PK, fornecido externamente).';
COMMENT ON COLUMN core.proceedings_saldo.proceedings_name IS 'Nome descritivo e único do procedimento/método.';
COMMENT ON COLUMN core.proceedings_saldo.proceedings_credit IS 'Flag booleana que indica se este procedimento pode originar uma operação de Crédito. Padrão: FALSE.';
COMMENT ON COLUMN core.proceedings_saldo.proceedings_debit IS 'Flag booleana que indica se este procedimento pode originar uma operação de Débito. Padrão: FALSE.';
COMMENT ON CONSTRAINT chk_proceedings_saldo_type ON core.proceedings_saldo IS 'Garante que cada procedimento seja aplicável a pelo menos um tipo de operação (crédito ou débito).';

-- Tabela: financial_institutions
CREATE TABLE core.financial_institutions (
    financial_institutions_id character varying(50) NOT NULL,
    financial_institutions_name character varying(150) NOT NULL,
    financial_institutions_official_name character varying(255) NOT NULL,
    financial_institutions_clearing_code character varying(10) NULL,
    financial_institutions_logo_url text NULL,
    financial_institutions_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT financial_institutions_pkey PRIMARY KEY (financial_institutions_id),
    CONSTRAINT financial_institutions_name_key UNIQUE (financial_institutions_name)
);
ALTER TABLE core.financial_institutions OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.financial_institutions IS 'Catálogo das instituições financeiras (bancos, fintechs, etc.).';
COMMENT ON COLUMN core.financial_institutions.financial_institutions_id IS 'Identificador único da instituição (PK, fornecido externamente).';
COMMENT ON COLUMN core.financial_institutions.financial_institutions_name IS 'Nome comum ou fantasia da instituição (único).';
COMMENT ON COLUMN core.financial_institutions.financial_institutions_official_name IS 'Nome oficial completo da instituição.';
COMMENT ON COLUMN core.financial_institutions.financial_institutions_clearing_code IS 'Código de compensação bancária (COMPE), se aplicável.';
COMMENT ON COLUMN core.financial_institutions.financial_institutions_logo_url IS 'URL para o logo da instituição (opcional).';
COMMENT ON COLUMN core.financial_institutions.financial_institutions_last_update IS 'Timestamp da criação ou última atualização manual deste registro.';

-- Tabela: account_types
CREATE TABLE core.account_types (
    account_types_id character varying(50) NOT NULL,
    account_types_name core.account_type NOT NULL,
    account_types_description text NULL,
    account_types_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT account_types_pkey PRIMARY KEY (account_types_id),
    CONSTRAINT account_types_name_key UNIQUE (account_types_name)
);
ALTER TABLE core.account_types OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.account_types IS 'Catálogo dos tipos genéricos de contas financeiras (Ex: Conta Corrente, Poupança).';
COMMENT ON COLUMN core.account_types.account_types_id IS 'Identificador único do tipo de conta (PK, fornecido externamente).';
COMMENT ON COLUMN core.account_types.account_types_name IS 'Nome do tipo de conta (ENUM account_type, único).';
COMMENT ON COLUMN core.account_types.account_types_description IS 'Descrição genérica sobre este tipo de conta (opcional).';
COMMENT ON COLUMN core.account_types.account_types_last_update IS 'Timestamp da criação ou última atualização manual deste registro.';

-- Tabela: institution_accounts (Produtos financeiros)
CREATE TABLE core.institution_accounts (
    institution_accounts_id character varying(50) NOT NULL,
    institution_accounts_institution_id character varying(50) NOT NULL,
    institution_accounts_type_id character varying(50) NOT NULL,
    institution_accounts_product_name character varying(150) NULL,
    institution_accounts_processing_info text NULL,
    institution_accounts_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT institution_accounts_pkey PRIMARY KEY (institution_accounts_id),
    CONSTRAINT fk_institution_accounts_institution FOREIGN KEY (institution_accounts_institution_id) REFERENCES core.financial_institutions(financial_institutions_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_institution_accounts_type FOREIGN KEY (institution_accounts_type_id) REFERENCES core.account_types(account_types_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT uq_institution_accounts_inst_type UNIQUE (institution_accounts_institution_id, institution_accounts_type_id)
);
ALTER TABLE core.institution_accounts OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.institution_accounts IS 'Define os "produtos" financeiros específicos oferecidos, ligando uma instituição a um tipo de conta.';
COMMENT ON COLUMN core.institution_accounts.institution_accounts_id IS 'Identificador único do produto financeiro (PK, fornecido externamente). Ex: "bb_cc_ouro".';
COMMENT ON COLUMN core.institution_accounts.institution_accounts_institution_id IS 'Referência à instituição financeira que oferece este produto (FK para financial_institutions).';
COMMENT ON COLUMN core.institution_accounts.institution_accounts_type_id IS 'Referência ao tipo genérico de conta deste produto (FK para account_types).';
COMMENT ON COLUMN core.institution_accounts.institution_accounts_product_name IS 'Nome específico do produto (Ex: "NuConta", "Conta Fácil"), se diferente do tipo genérico (opcional).';
COMMENT ON COLUMN core.institution_accounts.institution_accounts_processing_info IS 'Informações sobre horários/dias de processamento para este produto específico (opcional).';
COMMENT ON COLUMN core.institution_accounts.institution_accounts_last_update IS 'Timestamp da criação ou última atualização manual deste registro.';

-- Tabela: operators
CREATE TABLE core.operators (
    operators_id character varying(50) NOT NULL,
    operators_user_id character varying(50) NOT NULL,
    operators_name character varying(150) NOT NULL,
    operators_mail character varying(255) NULL,
    operators_priority boolean NOT NULL DEFAULT false,
    operators_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT operators_pkey PRIMARY KEY (operators_id),
    CONSTRAINT operators_operator_name_key UNIQUE (operators_name),
    CONSTRAINT fk_operators_user FOREIGN KEY (operators_user_id) REFERENCES core.users(users_id) ON DELETE RESTRICT ON UPDATE NO ACTION
);
ALTER TABLE core.operators OWNER to "SisFinance-adm";
COMMENT ON TABLE core.operators IS 'Cadastro de operadores (pessoas ou sistemas) associados a um usuário, responsáveis por registrar transações ou recorrências.';
COMMENT ON COLUMN core.operators.operators_id IS 'Identificador único do operador (PK, fornecido externamente).';
COMMENT ON COLUMN core.operators.operators_user_id IS 'Referência ao usuário do sistema associado a este operador (FK para users.users_id).';
COMMENT ON COLUMN core.operators.operators_name IS 'Nome identificador do operador (único).';
COMMENT ON COLUMN core.operators.operators_mail IS 'E-mail do operador (até 255 caracteres, pode ser nulo).';
COMMENT ON COLUMN core.operators.operators_priority IS 'Indica se este é o operador prioritário ou padrão para o usuário associado.';
COMMENT ON COLUMN core.operators.operators_last_update IS 'Timestamp da criação ou última atualização manual deste registro de operador.';

-- Tabela: user_accounts (Ligação Usuário-Produto)
CREATE TABLE core.user_accounts (
    user_accounts_id character varying(50) NOT NULL,
    user_accounts_user_id character varying(50) NOT NULL,
    user_accounts_institution_account_id character varying(50) NOT NULL,
    user_accounts_agency character varying(10) NULL,
    user_accounts_number character varying(100) NULL,
    user_accounts_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_accounts_pkey PRIMARY KEY (user_accounts_id),
    CONSTRAINT fk_user_accounts_user FOREIGN KEY (user_accounts_user_id) REFERENCES core.users(users_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_user_accounts_account FOREIGN KEY (user_accounts_institution_account_id) REFERENCES core.institution_accounts(institution_accounts_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT uq_user_accounts_user_account UNIQUE (user_accounts_user_id, user_accounts_institution_account_id)
);
ALTER TABLE core.user_accounts OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.user_accounts IS 'Associação entre usuários e os produtos financeiros específicos que eles possuem (Ex: a conta corrente específica do Usuário X no Banco Y).';
COMMENT ON COLUMN core.user_accounts.user_accounts_id IS 'Identificador único da associação usuário-produto (PK, fornecido externamente).';
COMMENT ON COLUMN core.user_accounts.user_accounts_user_id IS 'Referência ao usuário proprietário desta conta (FK para users).';
COMMENT ON COLUMN core.user_accounts.user_accounts_institution_account_id IS 'Referência ao produto financeiro específico que o usuário possui (FK para institution_accounts).';
COMMENT ON COLUMN core.user_accounts.user_accounts_agency IS 'Número da agência bancária associada a esta conta do usuário, se aplicável (opcional).';
COMMENT ON COLUMN core.user_accounts.user_accounts_number IS 'Número da conta bancária (ou identificador similar) associada a esta conta do usuário, se aplicável (opcional).';
COMMENT ON COLUMN core.user_accounts.user_accounts_last_update IS 'Timestamp da criação ou última atualização manual deste registro de associação.';

-- Tabela: user_accounts_pix_keys
CREATE TABLE core.user_accounts_pix_keys (
    user_accounts_pix_keys_id character varying(50) NOT NULL,
    user_accounts_pix_keys_user_account_id character varying(50) NOT NULL,
    user_accounts_pix_keys_type core.pix_key_type NOT NULL,
    user_accounts_pix_keys_key text NOT NULL,
    user_accounts_pix_keys_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_accounts_pix_keys_pkey PRIMARY KEY (user_accounts_pix_keys_id),
    CONSTRAINT fk_uapix_user_account FOREIGN KEY (user_accounts_pix_keys_user_account_id) REFERENCES core.user_accounts(user_accounts_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT uq_uapix_key_per_account UNIQUE (user_accounts_pix_keys_user_account_id, user_accounts_pix_keys_key)
);
ALTER TABLE core.user_accounts_pix_keys OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.user_accounts_pix_keys IS 'Armazena as chaves PIX individuais associadas a uma conta específica de um usuário (referenciando user_accounts).';
COMMENT ON COLUMN core.user_accounts_pix_keys.user_accounts_pix_keys_id IS 'Identificador único para esta entrada de chave PIX (PK, fornecido externamente).';
COMMENT ON COLUMN core.user_accounts_pix_keys.user_accounts_pix_keys_user_account_id IS 'Referência à associação usuário-conta específica à qual esta chave PIX pertence (FK para user_accounts).';
COMMENT ON COLUMN core.user_accounts_pix_keys.user_accounts_pix_keys_type IS 'Tipo da chave PIX (CPF, E-mail, Telefone, Aleatória).';
COMMENT ON COLUMN core.user_accounts_pix_keys.user_accounts_pix_keys_key IS 'A chave PIX em si (e-mail, telefone, CPF/CNPJ, chave aleatória).';
COMMENT ON COLUMN core.user_accounts_pix_keys.user_accounts_pix_keys_last_update IS 'Timestamp da criação ou última atualização manual deste registro de chave PIX.';

-- Tabela: creditcard
CREATE TABLE core.creditcard (
    creditcard_id character varying(50) NOT NULL,
    creditcard_name character varying(100) NOT NULL,
    creditcard_network character varying(150) NOT NULL,
    creditcard_logo text NULL,
    creditcard_financial_institutions_id character varying(50) NOT NULL,
    creditcard_postpone_due_date_to_business_day boolean NOT NULL DEFAULT true,
    creditcard_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT creditcard_pkey PRIMARY KEY (creditcard_id),
    CONSTRAINT fk_creditcard_financial_institution FOREIGN KEY (creditcard_financial_institutions_id) REFERENCES core.financial_institutions(financial_institutions_id) ON DELETE RESTRICT ON UPDATE NO ACTION
);
ALTER TABLE core.creditcard OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.creditcard IS 'Catálogo dos produtos de cartão de crédito oferecidos pelas instituições financeiras.';
COMMENT ON COLUMN core.creditcard.creditcard_id IS 'Identificador único do produto cartão de crédito (PK, fornecido externamente).';
COMMENT ON COLUMN core.creditcard.creditcard_name IS 'Nome comercial do cartão de crédito (Ex: Platinum, Gold).';
COMMENT ON COLUMN core.creditcard.creditcard_network IS 'Bandeira do cartão (Ex: Visa, Mastercard, Elo).';
COMMENT ON COLUMN core.creditcard.creditcard_logo IS 'URL para a imagem do logo do cartão (opcional).';
COMMENT ON COLUMN core.creditcard.creditcard_financial_institutions_id IS 'Referência à instituição financeira emissora do cartão (FK para financial_institutions).';
COMMENT ON COLUMN core.creditcard.creditcard_postpone_due_date_to_business_day IS 'Indica se o vencimento da fatura é adiado para o próximo dia útil caso caia em dia não útil. Padrão: TRUE.';
COMMENT ON COLUMN core.creditcard.creditcard_last_update IS 'Timestamp da criação ou última atualização manual do registro do cartão.';

-- Tabela: user_creditcard
CREATE TABLE core.user_creditcard (
    user_creditcard_id character varying(50) NOT NULL,
    user_creditcard_user_id character varying(50) NOT NULL,
    user_creditcard_creditcard_id character varying(50) NOT NULL,
    user_creditcard_payment_user_account_id character varying(50) NOT NULL,
    user_creditcard_payment_method transactions.payment_method NOT NULL,
    user_creditcard_closing_day integer NOT NULL CHECK (user_creditcard_closing_day >= 1 AND user_creditcard_closing_day <= 31),
    user_creditcard_due_day integer NOT NULL CHECK (user_creditcard_due_day >= 1 AND user_creditcard_due_day <= 31),
    user_creditcard_limit numeric(15, 2) NOT NULL DEFAULT 0,
    user_creditcard_status boolean NOT NULL DEFAULT true,
    user_creditcard_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_creditcard_pkey PRIMARY KEY (user_creditcard_id),
    CONSTRAINT fk_usercred_user FOREIGN KEY (user_creditcard_user_id) REFERENCES core.users(users_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_usercred_card FOREIGN KEY (user_creditcard_creditcard_id) REFERENCES core.creditcard(creditcard_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_usercred_payment_account FOREIGN KEY (user_creditcard_payment_user_account_id) REFERENCES core.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT uq_usercred_user_card UNIQUE (user_creditcard_user_id, user_creditcard_creditcard_id)
);
ALTER TABLE core.user_creditcard OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.user_creditcard IS 'Associação entre usuários e os cartões de crédito que possuem, definindo limites, forma de pagamento e status.';
COMMENT ON COLUMN core.user_creditcard.user_creditcard_id IS 'Identificador único da associação usuário-cartão (PK, fornecido externamente).';
COMMENT ON COLUMN core.user_creditcard.user_creditcard_user_id IS 'Referência ao usuário proprietário deste cartão (FK para users).';
COMMENT ON COLUMN core.user_creditcard.user_creditcard_creditcard_id IS 'Referência ao produto cartão de crédito que o usuário possui (FK para creditcard).';
COMMENT ON COLUMN core.user_creditcard.user_creditcard_payment_user_account_id IS 'Referência à conta do usuário (de user_accounts) usada para pagar a fatura deste cartão.';
COMMENT ON COLUMN core.user_creditcard.user_creditcard_payment_method IS 'Forma de pagamento da fatura deste cartão (Débito Automático ou Boleto).';
COMMENT ON COLUMN core.user_creditcard.user_creditcard_closing_day IS 'Dia do mês em que a fatura deste cartão fecha (1-31). Este é o NÚMERO DE DIAS ANTES DO VENCIMENTO.';
COMMENT ON COLUMN core.user_creditcard.user_creditcard_due_day IS 'Dia do mês em que a fatura deste cartão vence (1-31).';
COMMENT ON COLUMN core.user_creditcard.user_creditcard_limit IS 'Limite de crédito do usuário neste cartão. Padrão: 0.';
COMMENT ON COLUMN core.user_creditcard.user_creditcard_status IS 'Status do cartão para este usuário (TRUE = Ativo, FALSE = Desativado/Cancelado). Padrão: TRUE.';
COMMENT ON COLUMN core.user_creditcard.user_creditcard_last_update IS 'Timestamp da criação ou última atualização manual desta associação usuário-cartão.';

-- =============================================================================
-- CRIAÇÃO DAS TABELAS DO SCHEMA "transactions"
-- =============================================================================

CREATE TABLE transactions.description (
    description_id character varying(50) NOT NULL,
    description_name character varying(150) NOT NULL,
    description_local character varying(150),
    description_additional_information text,
    CONSTRAINT description_pkey PRIMARY KEY (description_id)
);
COMMENT ON TABLE transactions.description IS 'Catálogo de descrições detalhadas para transações, recorrências e lançamentos.';
COMMENT ON COLUMN transactions.description.description_id IS 'Identificador único da descrição (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.description.description_name IS 'Nome ou título da descrição.';
COMMENT ON COLUMN transactions.description.description_local IS 'Local relacionado à transação (opcional).';
COMMENT ON COLUMN transactions.description.description_additional_information IS 'Informações adicionais (opcional).';

-- Tabela: recurrence_saldo
CREATE TABLE transactions.recurrence_saldo (
    recurrence_saldo_id character varying(50) NOT NULL,
    recurrence_saldo_user_account_id character varying(50) NOT NULL,
    recurrence_saldo_operation core.operation NOT NULL,
    recurrence_saldo_proceeding_id character varying(50) NOT NULL,
    recurrence_saldo_category_id character varying(50) NOT NULL,
    recurrence_saldo_operator_id character varying(50) NOT NULL,
    recurrence_saldo_status transactions.recurrence_status_ai NOT NULL DEFAULT 'Ativo',
    recurrence_saldo_description_id character varying(50),
    recurrence_saldo_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    recurrence_saldo_type transactions.recurrence_type NOT NULL,
    recurrence_saldo_frequency transactions.recurrence_frequency NOT NULL,
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
    CONSTRAINT fk_recurrence_user_account FOREIGN KEY (recurrence_saldo_user_account_id) REFERENCES core.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_recurrence_proceeding FOREIGN KEY (recurrence_saldo_proceeding_id) REFERENCES core.proceedings_saldo(proceedings_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_recurrence_category FOREIGN KEY (recurrence_saldo_category_id) REFERENCES core.categories(categories_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_recurrence_operator FOREIGN KEY (recurrence_saldo_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT chk_recurrence_due_day_range CHECK (recurrence_saldo_due_day IS NULL OR (recurrence_saldo_due_day >= 1 AND recurrence_saldo_due_day <= 31)),
    CONSTRAINT fk_recurrence_saldo_description FOREIGN KEY (recurrence_saldo_description_id) REFERENCES transactions.description(description_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT chk_recurrence_due_day_required CHECK (recurrence_saldo_frequency = 'Semanal' OR recurrence_saldo_due_day IS NOT NULL),
    CONSTRAINT chk_recurrence_last_date_logic CHECK (recurrence_saldo_last_due_date IS NULL OR recurrence_saldo_last_due_date >= recurrence_saldo_first_due_date),
    CONSTRAINT chk_recurrence_determined_needs_last_date CHECK (recurrence_saldo_type = 'Indeterminado' OR recurrence_saldo_last_due_date IS NOT NULL)
);
ALTER TABLE transactions.recurrence_saldo OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.recurrence_saldo IS 'Armazena os modelos/agendamentos de transações financeiras de saldo recorrentes.';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_id IS 'Identificador único da recorrência de saldo (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_user_account_id IS 'Referência à associação usuário-conta específica afetada pela recorrência (FK para user_accounts).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_operation IS 'Natureza da operação (Crédito ou Débito) das transações geradas por esta recorrência.';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_proceeding_id IS 'Procedimento/método padrão das transações recorrentes (FK para proceedings_saldo).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_category_id IS 'Categoria padrão das transações recorrentes (FK para categories).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_operator_id IS 'Operador padrão associado às transações desta recorrência (FK para operators).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_status IS 'Status atual da recorrência (Ativo ou Inativo).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_description_id IS 'Descrição padrão para as transações geradas por esta recorrência (opcional).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_registration_datetime IS 'Data e hora de cadastro desta recorrência no sistema.';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_type IS 'Tipo de recorrência (Determinada com data final, ou Indeterminada).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_frequency IS 'Frequência com que a transação deve ocorrer (Semanal, Mensal, etc.).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_due_day IS 'Dia preferencial do mês para vencimento (1-31), obrigatório se a frequência não for Semanal (opcional).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_first_due_date IS 'Data do primeiro vencimento ou da primeira ocorrência desta recorrência.';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_last_due_date IS 'Data do último vencimento ou da última ocorrência (para tipo Determinado) (opcional).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_postpone_to_business_day IS 'Indica se o vencimento, caso caia em dia não útil, deve ser adiado para o próximo dia útil. Padrão: FALSE.';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_base_value IS 'Valor base da transação recorrente.';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_fees_taxes IS 'Valor de taxas ou impostos adicionais da transação recorrente. Padrão: 0.';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_subtotal IS 'Valor calculado: base_value +/- fees_taxes (dependendo da operação). Coluna Gerada.';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_total_effective IS 'Valor efetivo com sinal: subtotal ou -subtotal (dependendo da operação). Coluna Gerada.';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_receipt_archive IS 'Caminho ou identificador para um arquivo de comprovante modelo associado a esta recorrência (opcional).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_receipt_image IS 'Caminho ou identificador para uma imagem de comprovante modelo associada a esta recorrência (opcional).';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_relevance_ir IS 'Indica se as transações geradas por esta recorrência são relevantes para declaração de Imposto de Renda. Padrão: FALSE.';
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_last_update IS 'Timestamp da criação ou última atualização manual deste registro de recorrência.';

-- Tabela: transactions_saldo
CREATE TABLE transactions.transactions_saldo (
    transactions_saldo_id character varying(50) NOT NULL,
    transactions_saldo_user_accounts_id character varying(50) NOT NULL,
    transactions_saldo_operation core.operation NOT NULL,
    transactions_saldo_proceeding_id character varying(50) NOT NULL,
    transactions_saldo_status transactions.status NOT NULL DEFAULT 'Efetuado',
    transactions_saldo_category_id character varying(50) NOT NULL,
    transactions_saldo_operator_id character varying(50) NOT NULL,
    transactions_saldo_description_id character varying(50),
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
    CONSTRAINT fk_transactions_user_account FOREIGN KEY (transactions_saldo_user_accounts_id) REFERENCES core.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_proceeding FOREIGN KEY (transactions_saldo_proceeding_id) REFERENCES core.proceedings_saldo(proceedings_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_category FOREIGN KEY (transactions_saldo_category_id) REFERENCES core.categories(categories_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_operator FOREIGN KEY (transactions_saldo_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_saldo_description FOREIGN KEY (transactions_saldo_description_id) REFERENCES transactions.description(description_id) ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_recurrence FOREIGN KEY (transactions_saldo_recurrence_id) REFERENCES transactions.recurrence_saldo(recurrence_saldo_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT chk_transactions_recurrence_logic CHECK ((transactions_saldo_is_recurrence IS FALSE AND transactions_saldo_recurrence_id IS NULL) OR (transactions_saldo_is_recurrence IS TRUE AND transactions_saldo_recurrence_id IS NOT NULL)),
    CONSTRAINT chk_transactions_schedule_status CHECK (transactions_saldo_schedule_datetime IS NULL OR transactions_saldo_status = 'Pendente')
);
ALTER TABLE transactions.transactions_saldo OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.transactions_saldo IS 'Registros individuais de transações financeiras de saldo (movimentações em contas).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_id IS 'Identificador único da transação de saldo (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_user_accounts_id IS 'Referência à associação usuário-conta específica afetada pela transação (FK para user_accounts).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_operation IS 'Natureza da operação (Crédito ou Débito).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_proceeding_id IS 'Procedimento/método utilizado na transação (FK para proceedings_saldo).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_status IS 'Status da transação (Efetuado ou Pendente). Padrão: Efetuado.';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_category_id IS 'Categoria da transação (FK para categories).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_operator_id IS 'Operador que registrou/realizou a transação (FK para operators).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_description_id IS 'Descrição específica desta transação (opcional).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_observations IS 'Notas ou observações adicionais sobre a transação (opcional).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_registration_datetime IS 'Data e hora de registro da transação no sistema.';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_is_recurrence IS 'Flag booleana indicando se esta transação foi originada de um agendamento de recorrência. Padrão: FALSE.';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_recurrence_id IS 'Referência ao registro de recorrência que gerou esta transação (FK para recurrence_saldo), se aplicável (opcional).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_schedule_datetime IS 'Data e hora em que a transação está/estava agendada para ocorrer (para transações com status Pendente) (opcional).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_implementation_datetime IS 'Data e hora em que a transação foi efetivamente realizada/liquidada no mundo real.';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_base_value IS 'Valor principal da transação.';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_fees_taxes IS 'Taxas/impostos associados a esta transação específica. Padrão: 0.';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_subtotal IS 'Valor calculado: base_value +/- fees_taxes (dependendo da operação). Coluna Gerada.';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_total_effective IS 'Valor efetivo com sinal: subtotal ou -subtotal (dependendo da operação). Coluna Gerada.';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_receipt_archive IS 'Caminho/ID do arquivo de comprovante da transação (opcional).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_receipt_image IS 'Caminho/ID da imagem de comprovante da transação (opcional).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_receipt_url IS 'URL externa para o comprovante da transação (opcional).';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_relevance_ir IS 'Indica se esta transação é relevante para declaração de Imposto de Renda. Padrão: FALSE.';
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_last_update IS 'Timestamp da criação ou última atualização manual deste registro de transação.';

-- Tabela: internal_transfers
CREATE TABLE transactions.internal_transfers (
    internal_transfers_id character varying(50) NOT NULL,
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
    CONSTRAINT fk_inttransf_origin FOREIGN KEY (internal_transfers_origin_user_account_id) REFERENCES core.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_inttransf_destination FOREIGN KEY (internal_transfers_destination_user_account_id) REFERENCES core.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_inttransf_operator FOREIGN KEY (internal_transfers_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT chk_inttransf_different_accounts CHECK (internal_transfers_origin_user_account_id <> internal_transfers_destination_user_account_id),
    CONSTRAINT chk_inttransf_value_vs_fees CHECK (internal_transfers_base_value >= internal_transfers_fees_taxes)
);
ALTER TABLE transactions.internal_transfers OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.internal_transfers IS 'Registra operações de transferência de fundos entre contas do mesmo usuário, que dispara a criação de duas transações em transactions_saldo.';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_id IS 'Identificador único da operação de transferência (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_origin_user_account_id IS 'Conta de origem dos fundos para a transferência (FK para user_accounts).';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_destination_user_account_id IS 'Conta de destino dos fundos para a transferência (FK para user_accounts).';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_operator_id IS 'Operador que registrou a transferência (FK para operators).';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_observations IS 'Observações sobre a transferência (opcional).';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_registration_datetime IS 'Data/hora de registro da operação de transferência no sistema.';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_implementation_datetime IS 'Data/hora em que a transferência foi efetivamente realizada.';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_base_value IS 'Valor principal transferido (deve ser positivo).';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_fees_taxes IS 'Taxas associadas à operação de transferência em si (raro em transferências internas). Padrão: 0.';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_subtotal IS 'Valor calculado: base_value - fees_taxes. Coluna Gerada.';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_total_effective IS 'Valor efetivo transferido: base_value - fees_taxes. Coluna Gerada.';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_receipt_image IS 'URL/ID da imagem do comprovante da transferência (opcional).';
COMMENT ON COLUMN transactions.internal_transfers.internal_transfers_last_update IS 'Timestamp da criação ou última atualização manual deste registro.';

-- Tabela: creditcard_invoices
CREATE TABLE transactions.creditcard_invoices (
    creditcard_invoices_id character varying(50) NOT NULL,
    creditcard_invoices_user_creditcard_id character varying(50) NOT NULL,
    creditcard_invoices_creation_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creditcard_invoices_opening_date date NOT NULL,
    creditcard_invoices_closing_date date NOT NULL,
    creditcard_invoices_due_date date NOT NULL,
    creditcard_invoices_amount numeric(15, 2) NOT NULL DEFAULT 0,
    creditcard_invoices_paid_amount numeric(15, 2) NOT NULL DEFAULT 0,
    creditcard_invoices_payment_date date,
    creditcard_invoices_status transactions.invoice_status NOT NULL DEFAULT 'Aberta',
    creditcard_invoices_file_url text,
    creditcard_invoices_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT creditcard_invoices_pkey PRIMARY KEY (creditcard_invoices_id),
    CONSTRAINT fk_invoice_usercard FOREIGN KEY (creditcard_invoices_user_creditcard_id) REFERENCES core.user_creditcard(user_creditcard_id) ON DELETE CASCADE ON UPDATE NO ACTION
);
ALTER TABLE transactions.creditcard_invoices OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.creditcard_invoices IS 'Representa cada fatura mensal de um cartão de crédito específico do usuário.';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_id IS 'Identificador único da fatura (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_user_creditcard_id IS 'Referência à associação usuário-cartão à qual esta fatura pertence (FK para user_creditcard).';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_creation_datetime IS 'Data e hora de criação do registro da fatura no sistema.';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_opening_date IS 'Data de início do período de compras desta fatura.';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_closing_date IS 'Data de fechamento para novas compras desta fatura.';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_due_date IS 'Data de vencimento para pagamento desta fatura.';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_amount IS 'Valor total da fatura a ser pago. Inicialmente 0, calculado por processo externo/script.';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_paid_amount IS 'Valor efetivamente pago desta fatura. Inicialmente 0.';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_payment_date IS 'Data em que o pagamento (total ou parcial) da fatura foi realizado (opcional).';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_status IS 'Status atual da fatura (Aberta, Fechada, Paga, etc.). Padrão: Aberta.';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_file_url IS 'URL para o arquivo PDF ou imagem da fatura (opcional).';
COMMENT ON COLUMN transactions.creditcard_invoices.creditcard_invoices_last_update IS 'Timestamp da criação ou última atualização manual do registro da fatura.';

-- Tabela: creditcard_recurrence
CREATE TABLE transactions.creditcard_recurrence (
    creditcard_recurrence_id character varying(50) NOT NULL,
    creditcard_recurrence_user_card_id character varying(50) NOT NULL,
    creditcard_recurrence_procedure transactions.creditcard_transaction_procedure NOT NULL DEFAULT 'Débito em Fatura',
    creditcard_recurrence_category_id character varying(50) NOT NULL,
    creditcard_recurrence_operator_id character varying(50) NOT NULL,
    creditcard_recurrence_status transactions.recurrence_status_ai NOT NULL DEFAULT 'Ativo',
    creditcard_recurrence_description_id character varying(50),
    creditcard_recurrence_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creditcard_recurrence_type transactions.recurrence_type NOT NULL,
    creditcard_recurrence_frequency transactions.recurrence_frequency NOT NULL,
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
    CONSTRAINT fk_ccrecur_usercard FOREIGN KEY (creditcard_recurrence_user_card_id) REFERENCES core.user_creditcard(user_creditcard_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_ccrecur_category FOREIGN KEY (creditcard_recurrence_category_id) REFERENCES core.categories(categories_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_ccrecur_operator FOREIGN KEY (creditcard_recurrence_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_creditcard_recurrence_description FOREIGN KEY (creditcard_recurrence_description_id) REFERENCES transactions.description(description_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT chk_ccrecur_due_day_required CHECK (creditcard_recurrence_frequency = 'Semanal' OR creditcard_recurrence_due_day IS NOT NULL),
    CONSTRAINT chk_ccrecur_last_date_logic CHECK (creditcard_recurrence_last_due_date IS NULL OR creditcard_recurrence_last_due_date >= creditcard_recurrence_first_due_date),
    CONSTRAINT chk_ccrecur_determined_needs_last_date CHECK (creditcard_recurrence_type = 'Indeterminado' OR creditcard_recurrence_last_due_date IS NOT NULL)
);
ALTER TABLE transactions.creditcard_recurrence OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.creditcard_recurrence IS 'Define transações recorrentes que ocorrem diretamente na fatura do cartão de crédito.';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_id IS 'Identificador único da recorrência de cartão (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_user_card_id IS 'Referência ao cartão específico do usuário afetado (FK para user_creditcard).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_procedure IS 'Procedimento a ser aplicado na fatura (Crédito ou Débito em Fatura).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_category_id IS 'Categoria da recorrência (FK para categories).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_operator_id IS 'Operador associado a esta recorrência (FK para operators).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_status IS 'Status atual da recorrência (Ativo ou Inativo).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_description_id IS 'Descrição para as transações geradas por esta recorrência (opcional).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_registration_datetime IS 'Data e hora de cadastro desta recorrência no sistema.';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_type IS 'Tipo de recorrência (Determinada ou Indeterminada).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_frequency IS 'Frequência com que a transação recorrente deve ocorrer.';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_due_day IS 'Dia do mês preferencial para lançamento (1-31), exceto para frequência Semanal.';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_first_due_date IS 'Data da primeira ocorrência desta recorrência.';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_last_due_date IS 'Data da última ocorrência (obrigatória para tipo Determinado).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_postpone_to_business_day IS 'Indica se a data, caso caia em dia não útil, deve ser adiada.';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_base_value IS 'Valor base da transação recorrente.';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_fees_taxes IS 'Taxas ou impostos adicionais relacionados. Padrão: 0.';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_subtotal IS 'Valor calculado: base_value + fees_taxes. Coluna Gerada.';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_total_effective IS 'Valor efetivo com sinal (positivo para crédito, negativo para débito).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_receipt_archive IS 'Caminho/ID para arquivo de comprovante modelo (opcional).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_receipt_image IS 'Caminho/ID para imagem de comprovante modelo (opcional).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_receipt_url IS 'URL externa para comprovante modelo (opcional).';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_relevance_ir IS 'Indica relevância para Imposto de Renda.';
COMMENT ON COLUMN transactions.creditcard_recurrence.creditcard_recurrence_last_update IS 'Timestamp da última atualização manual deste registro.';

-- Tabela: creditcard_transactions
CREATE TABLE transactions.creditcard_transactions (
    creditcard_transactions_id character varying(50) NOT NULL,
    creditcard_transactions_invoice_id character varying(50),
    creditcard_transactions_procedure transactions.creditcard_transaction_procedure NOT NULL DEFAULT 'Débito em Fatura',
    creditcard_transactions_status transactions.status NOT NULL,
    creditcard_transactions_category_id character varying(50) NOT NULL,
    creditcard_transactions_operator_id character varying(50) NOT NULL,
    creditcard_transactions_description_id character varying(50),
    creditcard_transactions_observations text,
    creditcard_transactions_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creditcard_transactions_is_recurrence boolean NOT NULL DEFAULT false,
    creditcard_transactions_recurrence_id character varying(50),
    creditcard_transactions_schedule_datetime timestamp with time zone,
    creditcard_transactions_implementation_datetime timestamp with time zone NOT NULL,
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
    CONSTRAINT fk_cctrans_invoice FOREIGN KEY (creditcard_transactions_invoice_id) REFERENCES transactions.creditcard_invoices(creditcard_invoices_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT fk_cctrans_category FOREIGN KEY (creditcard_transactions_category_id) REFERENCES core.categories(categories_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_cctrans_operator FOREIGN KEY (creditcard_transactions_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_creditcard_transactions_description FOREIGN KEY (creditcard_transactions_description_id) REFERENCES transactions.description(description_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT fk_cctrans_recurrence FOREIGN KEY (creditcard_transactions_recurrence_id) REFERENCES transactions.creditcard_recurrence(creditcard_recurrence_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT chk_cctrans_installment_logic CHECK ((creditcard_transactions_is_installment IS FALSE AND creditcard_transactions_installment_count = 1) OR (creditcard_transactions_is_installment IS TRUE AND creditcard_transactions_installment_count > 1)),
    CONSTRAINT chk_cctrans_recurrence_logic CHECK ((creditcard_transactions_is_recurrence IS FALSE AND creditcard_transactions_recurrence_id IS NULL) OR (creditcard_transactions_is_recurrence IS TRUE AND creditcard_transactions_recurrence_id IS NOT NULL))
);
ALTER TABLE transactions.creditcard_transactions OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.creditcard_transactions IS 'Registra cada movimentação individual (compra, estorno, taxa) realizada com o cartão de crédito.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_id IS 'Identificador único da transação de cartão (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_invoice_id IS 'Fatura à qual esta transação está associada (FK para creditcard_invoices).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_procedure IS 'Procedimento aplicado na fatura (Crédito ou Débito em Fatura).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_status IS 'Status da transação (Efetuado ou Pendente).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_category_id IS 'Categoria da transação (FK para categories).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_operator_id IS 'Operador que registrou a transação (FK para operators).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_description_id IS 'Descrição da transação (opcional).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_observations IS 'Observações adicionais sobre a transação (opcional).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_registration_datetime IS 'Data e hora de registro da transação no sistema.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_is_recurrence IS 'Indica se foi gerada por uma recorrência. Padrão: FALSE.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_recurrence_id IS 'Recorrência que gerou esta transação, se aplicável (FK para creditcard_recurrence).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_schedule_datetime IS 'Data e hora agendada para transações pendentes (opcional).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_implementation_datetime IS 'Data e hora em que a transação foi efetivamente realizada.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_is_installment IS 'Indica se é uma compra parcelada. Padrão: FALSE.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_installment_count IS 'Número total de parcelas, se aplicável. Padrão: 1.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_base_value IS 'Valor principal da transação.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_fees_taxes IS 'Taxas adicionais. Padrão: 0.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_subtotal IS 'Valor calculado: base_value + fees_taxes. Coluna Gerada.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_total_effective IS 'Valor efetivo com sinal (positivo para crédito, negativo para débito).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_receipt_archive IS 'Caminho/ID para arquivo de comprovante (opcional).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_receipt_image IS 'Caminho/ID para imagem de comprovante (opcional).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_receipt_url IS 'URL externa para comprovante (opcional).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_relevance_ir IS 'Indica relevância para Imposto de Renda.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_last_update IS 'Timestamp da última atualização manual deste registro.';

-- Tabela: creditcard_installments
CREATE TABLE transactions.creditcard_installments (
    creditcard_installments_id character varying(50) NOT NULL,
    creditcard_installments_transaction_id character varying(50) NOT NULL,
    creditcard_installments_invoice_id character varying(50) NOT NULL,
    creditcard_installments_number integer NOT NULL CHECK (creditcard_installments_number >= 1 AND creditcard_installments_number <= 420),
    creditcard_installments_observations text,
    creditcard_installments_base_value numeric(15, 2) NOT NULL,
    creditcard_installments_fees_taxes numeric(15, 2) NOT NULL DEFAULT 0,
    creditcard_installments_subtotal numeric(15, 2) GENERATED ALWAYS AS (creditcard_installments_base_value + creditcard_installments_fees_taxes) STORED,
    creditcard_installments_total_effective numeric(15, 2) GENERATED ALWAYS AS ((creditcard_installments_base_value + creditcard_installments_fees_taxes) * -1) STORED,
    creditcard_installments_update_alert boolean NOT NULL DEFAULT false,
    creditcard_installments_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT creditcard_installments_pkey PRIMARY KEY (creditcard_installments_id),
    CONSTRAINT fk_ccinstall_transaction FOREIGN KEY (creditcard_installments_transaction_id) REFERENCES transactions.creditcard_transactions(creditcard_transactions_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_ccinstall_invoice FOREIGN KEY (creditcard_installments_invoice_id) REFERENCES transactions.creditcard_invoices(creditcard_invoices_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT uq_ccinstall_trans_num UNIQUE (creditcard_installments_transaction_id, creditcard_installments_number)
);
ALTER TABLE transactions.creditcard_installments OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.creditcard_installments IS 'Detalha cada parcela individual de uma transação de cartão de crédito que foi parcelada.';
COMMENT ON COLUMN transactions.creditcard_installments.creditcard_installments_id IS 'Identificador único da parcela (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.creditcard_installments.creditcard_installments_transaction_id IS 'Transação principal à qual esta parcela pertence (FK para creditcard_transactions).';
COMMENT ON COLUMN transactions.creditcard_installments.creditcard_installments_invoice_id IS 'Fatura à qual esta parcela está associada (FK para creditcard_invoices).';
COMMENT ON COLUMN transactions.creditcard_installments.creditcard_installments_number IS 'Número sequencial desta parcela (1 a 420).';
COMMENT ON COLUMN transactions.creditcard_installments.creditcard_installments_observations IS 'Observações específicas sobre esta parcela (opcional).';
COMMENT ON COLUMN transactions.creditcard_installments.creditcard_installments_base_value IS 'Valor principal desta parcela específica.';
COMMENT ON COLUMN transactions.creditcard_installments.creditcard_installments_fees_taxes IS 'Taxas adicionais específicas desta parcela. Padrão: 0.';
COMMENT ON COLUMN transactions.creditcard_installments.creditcard_installments_subtotal IS 'Valor calculado: base_value + fees_taxes. Coluna Gerada.';
COMMENT ON COLUMN transactions.creditcard_installments.creditcard_installments_total_effective IS 'Valor efetivo com sinal (sempre negativo pois é débito). Coluna Gerada.';
COMMENT ON COLUMN transactions.creditcard_installments.creditcard_installments_update_alert IS 'Registro de atualização caso seja necessário.';
COMMENT ON COLUMN transactions.creditcard_installments.creditcard_installments_last_update IS 'Timestamp da última atualização manual deste registro de parcela.';

-- Remoção dos campos de valores da tabela original
ALTER TABLE transactions.recurrence_saldo
    DROP COLUMN recurrence_saldo_subtotal,
    DROP COLUMN recurrence_saldo_total_effective,
    DROP COLUMN recurrence_saldo_base_value,
    DROP COLUMN recurrence_saldo_fees_taxes;
    

-- Criação da tabela auxiliar para armazenar valores
CREATE TABLE transactions.recurrence_saldo_values (
    recurrence_saldo_values_id character varying(50) NOT NULL,
    recurrence_saldo_values_recurrence_id character varying(50) NOT NULL,
    recurrence_saldo_values_operation core.operation NOT NULL,
    recurrence_saldo_values_value numeric(15, 2) NOT NULL,
    CONSTRAINT recurrence_saldo_values_pkey PRIMARY KEY (recurrence_saldo_values_id),
    CONSTRAINT fk_recurrence_saldo_values_recurrence 
        FOREIGN KEY (recurrence_saldo_values_recurrence_id) 
        REFERENCES transactions.recurrence_saldo(recurrence_saldo_id) 
        ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Comentários da tabela
COMMENT ON TABLE transactions.recurrence_saldo_values IS 'Armazena valores monetários associados às recorrências de saldo.';
COMMENT ON COLUMN transactions.recurrence_saldo_values.recurrence_saldo_values_id IS 'Identificador único do registro de valor (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.recurrence_saldo_values.recurrence_saldo_values_recurrence_id IS 'Referência à recorrência de saldo (FK para recurrence_saldo).';
COMMENT ON COLUMN transactions.recurrence_saldo_values.recurrence_saldo_values_operation IS 'Tipo de operação financeira (Crédito ou Débito).';
COMMENT ON COLUMN transactions.recurrence_saldo_values.recurrence_saldo_values_value IS 'Valor monetário associado à operação.';

-- Definir owner da tabela
ALTER TABLE transactions.recurrence_saldo_values OWNER TO "SisFinance-adm";

-- Trigger para imutabilidade da PK
CREATE TRIGGER trigger_prevent_recurrence_saldo_values_pk_update
BEFORE UPDATE ON transactions.recurrence_saldo_values
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('recurrence_saldo_values_id');

-- Trigger para auditoria
CREATE TRIGGER trigger_audit_recurrence_saldo_values
AFTER INSERT OR UPDATE OR DELETE ON transactions.recurrence_saldo_values
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('recurrence_saldo_values_id');

-- Remoção dos campos de valores da tabela original
ALTER TABLE transactions.transactions_saldo
    DROP COLUMN transactions_saldo_subtotal,
    DROP COLUMN transactions_saldo_total_effective,
    DROP COLUMN transactions_saldo_base_value,
    DROP COLUMN transactions_saldo_fees_taxes;
    

-- Criação da tabela auxiliar para armazenar valores
CREATE TABLE transactions.transactions_saldo_values (
    transactions_saldo_values_id character varying(50) NOT NULL,
    transactions_saldo_values_transaction_id character varying(50) NOT NULL,
    transactions_saldo_values_operation core.operation NOT NULL,
    transactions_saldo_values_value numeric(15, 2) NOT NULL,
    CONSTRAINT transactions_saldo_values_pkey PRIMARY KEY (transactions_saldo_values_id),
    CONSTRAINT fk_transactions_saldo_values_transaction 
        FOREIGN KEY (transactions_saldo_values_transaction_id) 
        REFERENCES transactions.transactions_saldo(transactions_saldo_id) 
        ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Comentários da tabela
COMMENT ON TABLE transactions.transactions_saldo_values IS 'Armazena valores monetários associados às transações de saldo.';
COMMENT ON COLUMN transactions.transactions_saldo_values.transactions_saldo_values_id IS 'Identificador único do registro de valor (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.transactions_saldo_values.transactions_saldo_values_transaction_id IS 'Referência à transação de saldo (FK para transactions_saldo).';
COMMENT ON COLUMN transactions.transactions_saldo_values.transactions_saldo_values_operation IS 'Tipo de operação financeira (Crédito ou Débito).';
COMMENT ON COLUMN transactions.transactions_saldo_values.transactions_saldo_values_value IS 'Valor monetário associado à operação.';

-- Definir owner da tabela
ALTER TABLE transactions.transactions_saldo_values OWNER TO "SisFinance-adm";

-- Trigger para imutabilidade da PK
CREATE TRIGGER trigger_prevent_transactions_saldo_values_pk_update
BEFORE UPDATE ON transactions.transactions_saldo_values
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('transactions_saldo_values_id');

-- Trigger para auditoria
CREATE TRIGGER trigger_audit_transactions_saldo_values
AFTER INSERT OR UPDATE OR DELETE ON transactions.transactions_saldo_values
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('transactions_saldo_values_id');

-- Remoção dos campos de valores da tabela original
ALTER TABLE transactions.internal_transfers
    DROP COLUMN internal_transfers_subtotal,
    DROP COLUMN internal_transfers_total_effective,
    DROP COLUMN internal_transfers_base_value,
    DROP COLUMN internal_transfers_fees_taxes;
    

-- Criação da tabela auxiliar para armazenar valores
CREATE TABLE transactions.internal_transfers_values (
    internal_transfers_values_id character varying(50) NOT NULL,
    internal_transfers_values_transfer_id character varying(50) NOT NULL,
    internal_transfers_values_operation core.operation NOT NULL,
    internal_transfers_values_value numeric(15, 2) NOT NULL,
    CONSTRAINT internal_transfers_values_pkey PRIMARY KEY (internal_transfers_values_id),
    CONSTRAINT fk_internal_transfers_values_transfer 
        FOREIGN KEY (internal_transfers_values_transfer_id) 
        REFERENCES transactions.internal_transfers(internal_transfers_id) 
        ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Comentários da tabela
COMMENT ON TABLE transactions.internal_transfers_values IS 'Armazena valores monetários associados às transferências internas.';
COMMENT ON COLUMN transactions.internal_transfers_values.internal_transfers_values_id IS 'Identificador único do registro de valor (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.internal_transfers_values.internal_transfers_values_transfer_id IS 'Referência à transferência interna (FK para internal_transfers).';
COMMENT ON COLUMN transactions.internal_transfers_values.internal_transfers_values_operation IS 'Tipo de operação financeira (Crédito ou Débito).';
COMMENT ON COLUMN transactions.internal_transfers_values.internal_transfers_values_value IS 'Valor monetário associado à operação.';

-- Definir owner da tabela
ALTER TABLE transactions.internal_transfers_values OWNER TO "SisFinance-adm";

-- Trigger para imutabilidade da PK
CREATE TRIGGER trigger_prevent_internal_transfers_values_pk_update
BEFORE UPDATE ON transactions.internal_transfers_values
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('internal_transfers_values_id');

-- Trigger para auditoria
CREATE TRIGGER trigger_audit_internal_transfers_values
AFTER INSERT OR UPDATE OR DELETE ON transactions.internal_transfers_values
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('internal_transfers_values_id');

-- Remoção dos campos de valores da tabela original
ALTER TABLE transactions.creditcard_recurrence
    DROP COLUMN creditcard_recurrence_subtotal,
    DROP COLUMN creditcard_recurrence_total_effective,
    DROP COLUMN creditcard_recurrence_base_value,
    DROP COLUMN creditcard_recurrence_fees_taxes;
    

-- Criação da tabela auxiliar para armazenar valores
CREATE TABLE transactions.creditcard_recurrence_values (
    creditcard_recurrence_values_id character varying(50) NOT NULL,
    creditcard_recurrence_values_recurrence_id character varying(50) NOT NULL,
    creditcard_recurrence_values_procedure transactions.creditcard_transaction_procedure NOT NULL,
    creditcard_recurrence_values_value numeric(15, 2) NOT NULL,
    CONSTRAINT creditcard_recurrence_values_pkey PRIMARY KEY (creditcard_recurrence_values_id),
    CONSTRAINT fk_creditcard_recurrence_values_recurrence 
        FOREIGN KEY (creditcard_recurrence_values_recurrence_id) 
        REFERENCES transactions.creditcard_recurrence(creditcard_recurrence_id) 
        ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Comentários da tabela
COMMENT ON TABLE transactions.creditcard_recurrence_values IS 'Armazena valores monetários associados às recorrências de cartão de crédito.';
COMMENT ON COLUMN transactions.creditcard_recurrence_values.creditcard_recurrence_values_id IS 'Identificador único do registro de valor (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.creditcard_recurrence_values.creditcard_recurrence_values_recurrence_id IS 'Referência à recorrência de cartão (FK para creditcard_recurrence).';
COMMENT ON COLUMN transactions.creditcard_recurrence_values.creditcard_recurrence_values_procedure IS 'Tipo de procedimento (Crédito em Fatura ou Débito em Fatura).';
COMMENT ON COLUMN transactions.creditcard_recurrence_values.creditcard_recurrence_values_value IS 'Valor monetário associado ao procedimento.';

-- Definir owner da tabela
ALTER TABLE transactions.creditcard_recurrence_values OWNER TO "SisFinance-adm";

-- Trigger para imutabilidade da PK
CREATE TRIGGER trigger_prevent_creditcard_recurrence_values_pk_update
BEFORE UPDATE ON transactions.creditcard_recurrence_values
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_recurrence_values_id');

-- Trigger para auditoria
CREATE TRIGGER trigger_audit_creditcard_recurrence_values
AFTER INSERT OR UPDATE OR DELETE ON transactions.creditcard_recurrence_values
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('creditcard_recurrence_values_id');

-- Remoção dos campos de valores da tabela original
ALTER TABLE transactions.creditcard_transactions
    DROP COLUMN creditcard_transactions_subtotal,
    DROP COLUMN creditcard_transactions_total_effective,
    DROP COLUMN creditcard_transactions_base_value,
    DROP COLUMN creditcard_transactions_fees_taxes;
    

-- Criação da tabela auxiliar para armazenar valores
CREATE TABLE transactions.creditcard_transactions_values (
    creditcard_transactions_values_id character varying(50) NOT NULL,
    creditcard_transactions_values_transaction_id character varying(50) NOT NULL,
    creditcard_transactions_values_procedure transactions.creditcard_transaction_procedure NOT NULL,
    creditcard_transactions_values_value numeric(15, 2) NOT NULL,
    CONSTRAINT creditcard_transactions_values_pkey PRIMARY KEY (creditcard_transactions_values_id),
    CONSTRAINT fk_creditcard_transactions_values_transaction 
        FOREIGN KEY (creditcard_transactions_values_transaction_id) 
        REFERENCES transactions.creditcard_transactions(creditcard_transactions_id) 
        ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Comentários da tabela
COMMENT ON TABLE transactions.creditcard_transactions_values IS 'Armazena valores monetários associados às transações de cartão de crédito.';
COMMENT ON COLUMN transactions.creditcard_transactions_values.creditcard_transactions_values_id IS 'Identificador único do registro de valor (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.creditcard_transactions_values.creditcard_transactions_values_transaction_id IS 'Referência à transação de cartão (FK para creditcard_transactions).';
COMMENT ON COLUMN transactions.creditcard_transactions_values.creditcard_transactions_values_procedure IS 'Tipo de procedimento (Crédito em Fatura ou Débito em Fatura).';
COMMENT ON COLUMN transactions.creditcard_transactions_values.creditcard_transactions_values_value IS 'Valor monetário associado ao procedimento.';

-- Definir owner da tabela
ALTER TABLE transactions.creditcard_transactions_values OWNER TO "SisFinance-adm";

-- Trigger para imutabilidade da PK
CREATE TRIGGER trigger_prevent_creditcard_transactions_values_pk_update
BEFORE UPDATE ON transactions.creditcard_transactions_values
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_transactions_values_id');

-- Trigger para auditoria
CREATE TRIGGER trigger_audit_creditcard_transactions_values
AFTER INSERT OR UPDATE OR DELETE ON transactions.creditcard_transactions_values
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('creditcard_transactions_values_id');

-- Remoção dos campos de valores da tabela original
ALTER TABLE transactions.creditcard_installments
    DROP COLUMN creditcard_installments_subtotal,
    DROP COLUMN creditcard_installments_total_effective,
    DROP COLUMN creditcard_installments_base_value,
    DROP COLUMN creditcard_installments_fees_taxes;
    

-- Criação da tabela auxiliar para armazenar valores
CREATE TABLE transactions.creditcard_installments_values (
    creditcard_installments_values_id character varying(50) NOT NULL,
    creditcard_installments_values_installment_id character varying(50) NOT NULL,
    creditcard_installments_values_procedure transactions.creditcard_transaction_procedure NOT NULL,
    creditcard_installments_values_value numeric(15, 2) NOT NULL,
    CONSTRAINT creditcard_installments_values_pkey PRIMARY KEY (creditcard_installments_values_id),
    CONSTRAINT fk_creditcard_installments_values_installment 
        FOREIGN KEY (creditcard_installments_values_installment_id) 
        REFERENCES transactions.creditcard_installments(creditcard_installments_id) 
        ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Comentários da tabela
COMMENT ON TABLE transactions.creditcard_installments_values IS 'Armazena valores monetários associados às parcelas de cartão de crédito.';
COMMENT ON COLUMN transactions.creditcard_installments_values.creditcard_installments_values_id IS 'Identificador único do registro de valor (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.creditcard_installments_values.creditcard_installments_values_installment_id IS 'Referência à parcela de cartão (FK para creditcard_installments).';
COMMENT ON COLUMN transactions.creditcard_installments_values.creditcard_installments_values_procedure IS 'Tipo de procedimento (Crédito em Fatura ou Débito em Fatura).';
COMMENT ON COLUMN transactions.creditcard_installments_values.creditcard_installments_values_value IS 'Valor monetário associado ao procedimento.';

-- Definir owner da tabela
ALTER TABLE transactions.creditcard_installments_values OWNER TO "SisFinance-adm";

-- Trigger para imutabilidade da PK
CREATE TRIGGER trigger_prevent_creditcard_installments_values_pk_update
BEFORE UPDATE ON transactions.creditcard_installments_values
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_installments_values_id');

-- Trigger para auditoria
CREATE TRIGGER trigger_audit_creditcard_installments_values
AFTER INSERT OR UPDATE OR DELETE ON transactions.creditcard_installments_values
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('creditcard_installments_values_id');

-- =============================================================================
-- EXTENSÕES PARA SISTEMA DE CÂMBIO DE MOEDAS
-- =============================================================================

-- Criação da tabela de moedas
CREATE TABLE core.currencies (
    currencies_id character varying(50) NOT NULL,
    currencies_iso character(3) NOT NULL UNIQUE,
    currencies_name character varying(150) NOT NULL UNIQUE,
    currencies_value numeric(15, 6) NOT NULL DEFAULT 0,
    currencies_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT currencies_pkey PRIMARY KEY (currencies_id),
    CONSTRAINT chk_currencies_value_positive CHECK (currencies_value >= 0),
    CONSTRAINT chk_currencies_iso_format CHECK (currencies_iso ~ '^[A-Z]{3}$')
);
ALTER TABLE core.currencies OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.currencies IS 'Catálogo das moedas disponíveis no sistema com suas respectivas taxas de câmbio em relação ao BRL.';
COMMENT ON COLUMN core.currencies.currencies_id IS 'Identificador único da moeda (PK, fornecido externamente).';
COMMENT ON COLUMN core.currencies.currencies_iso IS 'Código ISO 4217 da moeda (3 caracteres, único).';
COMMENT ON COLUMN core.currencies.currencies_name IS 'Nome completo da moeda (único).';
COMMENT ON COLUMN core.currencies.currencies_value IS 'Valor da moeda em relação ao BRL (fornecido externamente).';
COMMENT ON COLUMN core.currencies.currencies_last_update IS 'Data e hora da última atualização do registro.';

-- Populando com BRL por padrão
INSERT INTO core.currencies (currencies_id, currencies_iso, currencies_name, currencies_value) 
VALUES ('1', 'BRL', 'Real', 1.000000);

-- Criação da tabela de histórico de taxas de câmbio
CREATE TABLE core.currencies_exchange_rates_history (
    currencies_exchange_rates_history_id character varying(50) NOT NULL,
    currencies_exchange_rates_history_currency_id character varying(50) NOT NULL,
    currencies_exchange_rates_history_rate numeric(15, 6) NOT NULL,
    currencies_exchange_rates_history_source character varying(100) NULL,
    currencies_exchange_rates_history_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    currencies_exchange_rates_history_is_current boolean NOT NULL DEFAULT true,
    CONSTRAINT currencies_exchange_rates_history_pkey PRIMARY KEY (currencies_exchange_rates_history_id),
    CONSTRAINT fk_curr_hist_currency FOREIGN KEY (currencies_exchange_rates_history_currency_id) REFERENCES core.currencies(currencies_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT chk_curr_hist_rate_positive CHECK (currencies_exchange_rates_history_rate > 0)
);
ALTER TABLE core.currencies_exchange_rates_history OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.currencies_exchange_rates_history IS 'Histórico das taxas de câmbio das moedas, permitindo rastreamento temporal das variações.';
COMMENT ON COLUMN core.currencies_exchange_rates_history.currencies_exchange_rates_history_id IS 'Identificador único do registro histórico (PK, fornecido externamente).';
COMMENT ON COLUMN core.currencies_exchange_rates_history.currencies_exchange_rates_history_currency_id IS 'Referência à moeda (FK para currencies).';
COMMENT ON COLUMN core.currencies_exchange_rates_history.currencies_exchange_rates_history_rate IS 'Taxa de câmbio registrada (sempre > 0).';
COMMENT ON COLUMN core.currencies_exchange_rates_history.currencies_exchange_rates_history_source IS 'Fonte da cotação (API, manual, etc.) (opcional).';
COMMENT ON COLUMN core.currencies_exchange_rates_history.currencies_exchange_rates_history_datetime IS 'Data e hora do registro da taxa.';
COMMENT ON COLUMN core.currencies_exchange_rates_history.currencies_exchange_rates_history_is_current IS 'Indica se esta é a taxa atual para a moeda.';

-- Criação da tabela user_accounts_currencies
CREATE TABLE core.user_accounts_currencies (
    user_accounts_currencies_id character varying(50) NOT NULL,
    user_accounts_currencies_user_account_id character varying(50) NOT NULL,
    user_accounts_currencies_currency_id character varying(50) NOT NULL,
    user_accounts_currencies_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_accounts_currencies_pkey PRIMARY KEY (user_accounts_currencies_id),
    CONSTRAINT fk_uac_user_account FOREIGN KEY (user_accounts_currencies_user_account_id) REFERENCES core.user_accounts(user_accounts_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_uac_currency FOREIGN KEY (user_accounts_currencies_currency_id) REFERENCES core.currencies(currencies_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT uq_uac_account_currency UNIQUE (user_accounts_currencies_user_account_id, user_accounts_currencies_currency_id)
);
ALTER TABLE core.user_accounts_currencies OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.user_accounts_currencies IS 'Associação entre contas de usuários e moedas que podem ser utilizadas nessas contas.';
COMMENT ON COLUMN core.user_accounts_currencies.user_accounts_currencies_id IS 'Identificador único da associação (PK, fornecido externamente).';
COMMENT ON COLUMN core.user_accounts_currencies.user_accounts_currencies_user_account_id IS 'Referência à conta do usuário (FK para user_accounts).';
COMMENT ON COLUMN core.user_accounts_currencies.user_accounts_currencies_currency_id IS 'Referência à moeda (FK para currencies).';
COMMENT ON COLUMN core.user_accounts_currencies.user_accounts_currencies_last_update IS 'Data e hora da última atualização do registro.';

-- Criação da tabela de transferências de câmbio
CREATE TABLE transactions.currencies_transfers (
    currencies_transfers_id character varying(50) NOT NULL,
    currencies_transfers_origin_user_account_id character varying(50) NOT NULL,
    currencies_transfers_destination_user_account_id character varying(50) NOT NULL,
    currencies_transfers_operator_id character varying(50) NOT NULL,
    currencies_transfers_observations text,
    currencies_transfers_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    currencies_transfers_implementation_datetime timestamp with time zone NOT NULL,
    currencies_transfers_base_value_origin numeric(15, 2) NOT NULL,
    currencies_transfers_fees_taxes_origin numeric(15, 2) NOT NULL DEFAULT 0,
    currencies_transfers_exchange_rate_destination numeric(15, 6) NOT NULL DEFAULT 1.0,
    currencies_transfers_additional_fees_destination numeric(15, 2) NOT NULL DEFAULT 0,
    currencies_transfers_total_origin numeric(15, 2) GENERATED ALWAYS AS (currencies_transfers_base_value_origin + currencies_transfers_fees_taxes_origin) STORED,
    currencies_transfers_total_destination numeric(15, 2) GENERATED ALWAYS AS ((currencies_transfers_base_value_origin - currencies_transfers_fees_taxes_origin) * currencies_transfers_exchange_rate_destination - currencies_transfers_additional_fees_destination) STORED,
    currencies_transfers_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT currencies_transfers_pkey PRIMARY KEY (currencies_transfers_id),
    CONSTRAINT fk_ct_origin_user_account FOREIGN KEY (currencies_transfers_origin_user_account_id) REFERENCES core.user_accounts_currencies(user_accounts_currencies_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_ct_destination_user_account FOREIGN KEY (currencies_transfers_destination_user_account_id) REFERENCES core.user_accounts_currencies(user_accounts_currencies_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_ct_operator FOREIGN KEY (currencies_transfers_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT chk_ct_different_currencies CHECK (currencies_transfers_origin_user_account_id <> currencies_transfers_destination_user_account_id),
    CONSTRAINT chk_ct_positive_values CHECK (currencies_transfers_base_value_origin > 0 AND currencies_transfers_fees_taxes_origin >= 0 AND currencies_transfers_additional_fees_destination >= 0),
    CONSTRAINT chk_ct_positive_exchange_rate CHECK (currencies_transfers_exchange_rate_destination > 0)
    -- NOTA: Constraint chk_ct_not_both_brl removido para evitar dependência circular
    -- Será validado via trigger ou aplicação
    -- Constraint chk_ct_same_user removida, será implementada via trigger
);
ALTER TABLE transactions.currencies_transfers OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.currencies_transfers IS 'Registra operações de conversão de moedas entre contas do mesmo usuário.';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_id IS 'Identificador único da operação de câmbio (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_origin_user_account_id IS 'Conta de origem na moeda de origem (FK para user_accounts_currencies).';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_destination_user_account_id IS 'Conta de destino na moeda de destino (FK para user_accounts_currencies).';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_operator_id IS 'Operador responsável pela operação (FK para operators).';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_observations IS 'Observações sobre a operação de câmbio (opcional).';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_registration_datetime IS 'Data e hora de registro da operação.';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_implementation_datetime IS 'Data e hora de efetivação da operação.';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_base_value_origin IS 'Valor base na moeda de origem.';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_fees_taxes_origin IS 'Taxas e impostos na moeda de origem.';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_exchange_rate_destination IS 'Taxa de câmbio para conversão.';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_additional_fees_destination IS 'Taxas adicionais na moeda de destino.';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_total_origin IS 'Valor total debitado da origem (base + taxas origem).';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_total_destination IS 'Valor total creditado no destino ((base + taxas origem) * taxa + taxas destino).';
COMMENT ON COLUMN transactions.currencies_transfers.currencies_transfers_last_update IS 'Data e hora da última atualização do registro.';

-- Criação da tabela para transações em moedas estrangeiras
CREATE TABLE transactions.foreign_currency_transactions (
    foreign_currency_transactions_id character varying(50) NOT NULL,
    foreign_currency_transactions_user_account_currency_id character varying(50) NOT NULL,
    foreign_currency_transactions_operation core.operation NOT NULL,
    foreign_currency_transactions_category_id character varying(50) NOT NULL,
    foreign_currency_transactions_operator_id character varying(50) NOT NULL,
    foreign_currency_transactions_description_id character varying(50),
    foreign_currency_transactions_observations text,
    foreign_currency_transactions_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    foreign_currency_transactions_implementation_datetime timestamp with time zone NOT NULL,
    foreign_currency_transactions_base_value numeric(15, 2) NOT NULL,
    foreign_currency_transactions_fees_taxes numeric(15, 2) NOT NULL DEFAULT 0,
    foreign_currency_transactions_subtotal numeric(15, 2) GENERATED ALWAYS AS (CASE WHEN foreign_currency_transactions_operation = 'Crédito' THEN foreign_currency_transactions_base_value - foreign_currency_transactions_fees_taxes ELSE foreign_currency_transactions_base_value + foreign_currency_transactions_fees_taxes END) STORED,
    foreign_currency_transactions_total_effective numeric(15, 2) GENERATED ALWAYS AS (CASE WHEN foreign_currency_transactions_operation = 'Crédito' THEN (foreign_currency_transactions_base_value - foreign_currency_transactions_fees_taxes) ELSE ((foreign_currency_transactions_base_value + foreign_currency_transactions_fees_taxes) * -1) END) STORED,
    foreign_currency_transactions_exchange_source character varying(50) NULL,
    foreign_currency_transactions_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT foreign_currency_transactions_pkey PRIMARY KEY (foreign_currency_transactions_id),
    CONSTRAINT fk_fct_user_account_currency FOREIGN KEY (foreign_currency_transactions_user_account_currency_id) REFERENCES core.user_accounts_currencies(user_accounts_currencies_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_foreign_currency_transactions_description FOREIGN KEY (foreign_currency_transactions_description_id) REFERENCES transactions.description(description_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT fk_fct_category FOREIGN KEY (foreign_currency_transactions_category_id) REFERENCES core.categories(categories_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_fct_operator FOREIGN KEY (foreign_currency_transactions_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT chk_fct_positive_values CHECK (foreign_currency_transactions_base_value > 0 AND foreign_currency_transactions_fees_taxes >= 0)
);
ALTER TABLE transactions.foreign_currency_transactions OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.foreign_currency_transactions IS 'Registra transações realizadas diretamente em moedas estrangeiras, sem conversão para BRL.';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_id IS 'Identificador único da transação (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_user_account_currency_id IS 'Referência à conta-moeda (FK para user_accounts_currencies).';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_operation IS 'Tipo de operação (Crédito ou Débito).';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_category_id IS 'Categoria da transação (FK para categories).';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_operator_id IS 'Operador responsável (FK para operators).';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_description_id IS 'Descrição da transação (opcional).';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_observations IS 'Observações adicionais (opcional).';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_registration_datetime IS 'Data e hora de registro.';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_implementation_datetime IS 'Data e hora de implementação.';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_base_value IS 'Valor base da transação.';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_fees_taxes IS 'Taxas e impostos.';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_subtotal IS 'Subtotal calculado (base +/- taxas).';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_total_effective IS 'Valor efetivo com sinal.';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_exchange_source IS 'Fonte da operação de câmbio (opcional).';
COMMENT ON COLUMN transactions.foreign_currency_transactions.foreign_currency_transactions_last_update IS 'Data e hora da última atualização.';


-- =============================================================================
-- FUNÇÕES PARA SISTEMA DE CÂMBIO
-- =============================================================================

-- Função para atualizar taxa atual de moeda
CREATE OR REPLACE FUNCTION public.update_current_currency_rate()
RETURNS TRIGGER AS $$
BEGIN
    -- Marcar todas as outras taxas como não atuais
    UPDATE core.currencies_exchange_rates_history 
    SET currencies_exchange_rates_history_is_current = false
    WHERE currencies_exchange_rates_history_currency_id = NEW.currencies_exchange_rates_history_currency_id
      AND currencies_exchange_rates_history_id != NEW.currencies_exchange_rates_history_id;
    
    -- Atualizar a taxa atual na tabela principal
    UPDATE core.currencies 
    SET currencies_value = NEW.currencies_exchange_rates_history_rate,
        currencies_last_update = NEW.currencies_exchange_rates_history_datetime
    WHERE currencies_id = NEW.currencies_exchange_rates_history_currency_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.update_current_currency_rate() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.update_current_currency_rate() IS 'Atualiza a taxa atual da moeda quando um novo registro histórico é marcado como atual.';

-- Função para criar registro BRL automaticamente
CREATE OR REPLACE FUNCTION public.auto_create_brl_currency_account()
RETURNS TRIGGER AS $$
BEGIN
    -- Criar automaticamente associação com BRL (ID = '1')
    INSERT INTO core.user_accounts_currencies (
        user_accounts_currencies_id,
        user_accounts_currencies_user_account_id,
        user_accounts_currencies_currency_id
    ) VALUES (
        NEW.user_accounts_id || '-BRL',
        NEW.user_accounts_id,
        '1'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.auto_create_brl_currency_account() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.auto_create_brl_currency_account() IS 'Cria automaticamente associação com BRL ao criar uma nova conta de usuário.';

-- Função para sincronizar operações de câmbio com transactions_saldo e foreign_currency_transactions
CREATE OR REPLACE FUNCTION public.sync_currency_transfer_to_transactions()
RETURNS TRIGGER AS $$
DECLARE
    v_origin_currency_id character varying(50);
    v_dest_currency_id character varying(50);
    v_origin_user_account_id character varying(50);
    v_dest_user_account_id character varying(50);
    v_proc_id character varying(50);
    v_cat_id character varying(50);
    v_proceeding_name TEXT := 'Operação de Câmbio';
    v_category_name TEXT := 'Transferências Internas';
    v_debit_txn_id character varying(101);
    v_credit_txn_id character varying(101);
    v_debit_value_id character varying(105);
    v_credit_value_id character varying(105);
    v_values_record RECORD;
BEGIN
    -- Buscar informações das moedas e contas
    SELECT uac1.user_accounts_currencies_currency_id, uac1.user_accounts_currencies_user_account_id,
           uac2.user_accounts_currencies_currency_id, uac2.user_accounts_currencies_user_account_id
    INTO v_origin_currency_id, v_origin_user_account_id, v_dest_currency_id, v_dest_user_account_id
    FROM core.user_accounts_currencies uac1, core.user_accounts_currencies uac2
    WHERE uac1.user_accounts_currencies_id = COALESCE(NEW.currencies_transfers_origin_user_account_id, OLD.currencies_transfers_origin_user_account_id)
      AND uac2.user_accounts_currencies_id = COALESCE(NEW.currencies_transfers_destination_user_account_id, OLD.currencies_transfers_destination_user_account_id);

    -- Buscar valores da transferência na tabela auxiliar
    IF (TG_OP = 'INSERT') THEN
        SELECT * INTO v_values_record 
        FROM transactions.currencies_transfers_values
        WHERE currencies_transfers_values_transfer_id = NEW.currencies_transfers_id;
    ELSE
        SELECT * INTO v_values_record 
        FROM transactions.currencies_transfers_values
        WHERE currencies_transfers_values_transfer_id = OLD.currencies_transfers_id;
    END IF;
    
    -- Se não encontrou os valores, lançar exceção
    IF v_values_record IS NULL THEN
        RAISE EXCEPTION 'Valores da transferência de câmbio não encontrados';
    END IF;

    -- Buscar procedimento e categoria
    SELECT proceedings_id INTO v_proc_id FROM core.proceedings_saldo WHERE proceedings_name = v_proceeding_name LIMIT 1;
    SELECT categories_id INTO v_cat_id FROM core.categories WHERE categories_name = v_category_name LIMIT 1;

    -- Se não encontrou os dados básicos, tentar criar ou usar IDs padrão
    IF v_proc_id IS NULL THEN
        -- Tentar inserir o procedimento padrão
        BEGIN
            INSERT INTO core.proceedings_saldo (proceedings_id, proceedings_name, proceedings_credit, proceedings_debit)
            VALUES ('PROC_CAMBIO', v_proceeding_name, true, true)
            ON CONFLICT (proceedings_name) DO NOTHING;
            
            SELECT proceedings_id INTO v_proc_id FROM core.proceedings_saldo WHERE proceedings_name = v_proceeding_name LIMIT 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Não foi possível criar ou encontrar procedimento padrão "%" para operações de câmbio.', v_proceeding_name;
        END;
    END IF;
    
    IF v_cat_id IS NULL THEN
        -- Tentar inserir a categoria padrão
        BEGIN
            INSERT INTO core.categories (categories_id, categories_name, categories_credit, categories_debit)
            VALUES ('CAT_TRANSF_INT', v_category_name, true, true)
            ON CONFLICT (categories_name) DO NOTHING;
            
            SELECT categories_id INTO v_cat_id FROM core.categories WHERE categories_name = v_category_name LIMIT 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Não foi possível criar ou encontrar categoria padrão "%" para operações de câmbio.', v_category_name;
        END;
    END IF;

    IF (TG_OP = 'INSERT') THEN
        -- ORIGEM: Criar transação de débito
        IF v_origin_currency_id = '1' THEN
            -- Débito em BRL (transactions_saldo)
            v_debit_txn_id := NEW.currencies_transfers_id || '-CAMBIO-DEBIT';
            INSERT INTO transactions.transactions_saldo (
                transactions_saldo_id, transactions_saldo_user_accounts_id,
                transactions_saldo_operation, transactions_saldo_proceeding_id, transactions_saldo_status,
                transactions_saldo_category_id, transactions_saldo_operator_id, transactions_saldo_description_id,
                transactions_saldo_observations, transactions_saldo_registration_datetime,
                transactions_saldo_implementation_datetime,
                transactions_saldo_is_recurrence, transactions_saldo_relevance_ir
            ) VALUES (
                v_debit_txn_id, v_origin_user_account_id, 'Débito'::core.operation, v_proc_id, 'Efetuado'::transactions.status,
                v_cat_id, NEW.currencies_transfers_operator_id, NULL, NEW.currencies_transfers_observations,
                NEW.currencies_transfers_registration_datetime, NEW.currencies_transfers_implementation_datetime,
                FALSE, FALSE
            );
            
            -- Inserir valor para débito
            v_debit_value_id := v_debit_txn_id || '-VALUE';
            INSERT INTO transactions.transactions_saldo_values (
                transactions_saldo_values_id,
                transactions_saldo_values_transaction_id,
                transactions_saldo_values_operation,
                transactions_saldo_values_value
            ) VALUES (
                v_debit_value_id,
                v_debit_txn_id,
                'Débito'::core.operation,
                v_values_record.currencies_transfers_values_total_origin
            );
        ELSE
            -- Débito em moeda estrangeira (foreign_currency_transactions)
            v_debit_txn_id := NEW.currencies_transfers_id || '-CAMBIO-DEBIT';
            INSERT INTO transactions.foreign_currency_transactions (
                foreign_currency_transactions_id, foreign_currency_transactions_user_account_currency_id,
                foreign_currency_transactions_operation, foreign_currency_transactions_category_id,
                foreign_currency_transactions_operator_id, foreign_currency_transactions_description_id,
                foreign_currency_transactions_observations, foreign_currency_transactions_registration_datetime,
                foreign_currency_transactions_implementation_datetime, foreign_currency_transactions_base_value,
                foreign_currency_transactions_fees_taxes, foreign_currency_transactions_exchange_source
            ) VALUES (
                v_debit_txn_id, NEW.currencies_transfers_origin_user_account_id, 'Débito'::core.operation,
                v_cat_id, NEW.currencies_transfers_operator_id, NULL, NEW.currencies_transfers_observations,
                NEW.currencies_transfers_registration_datetime, NEW.currencies_transfers_implementation_datetime,
                v_values_record.currencies_transfers_values_base_value_origin, 
                v_values_record.currencies_transfers_values_fees_taxes_origin, 
                'CURRENCY_EXCHANGE'
            );
        END IF;

        -- DESTINO: Criar transação de crédito
        IF v_dest_currency_id = '1' THEN
            -- Crédito em BRL (transactions_saldo)
            v_credit_txn_id := NEW.currencies_transfers_id || '-CAMBIO-CREDIT';
            INSERT INTO transactions.transactions_saldo (
                transactions_saldo_id, transactions_saldo_user_accounts_id,
                transactions_saldo_operation, transactions_saldo_proceeding_id, transactions_saldo_status,
                transactions_saldo_category_id, transactions_saldo_operator_id, transactions_saldo_description_id,
                transactions_saldo_observations, transactions_saldo_registration_datetime,
                transactions_saldo_implementation_datetime,
                transactions_saldo_is_recurrence, transactions_saldo_relevance_ir
            ) VALUES (
                v_credit_txn_id, v_dest_user_account_id, 'Crédito'::core.operation, v_proc_id, 'Efetuado'::transactions.status,
                v_cat_id, NEW.currencies_transfers_operator_id, NULL, NEW.currencies_transfers_observations,
                NEW.currencies_transfers_registration_datetime, NEW.currencies_transfers_implementation_datetime,
                FALSE, FALSE
            );
            
            -- Inserir valor para crédito
            v_credit_value_id := v_credit_txn_id || '-VALUE';
            INSERT INTO transactions.transactions_saldo_values (
                transactions_saldo_values_id,
                transactions_saldo_values_transaction_id,
                transactions_saldo_values_operation,
                transactions_saldo_values_value
            ) VALUES (
                v_credit_value_id,
                v_credit_txn_id,
                'Crédito'::core.operation,
                v_values_record.currencies_transfers_values_total_destination
            );
        ELSE
            -- Crédito em moeda estrangeira (foreign_currency_transactions)
            v_credit_txn_id := NEW.currencies_transfers_id || '-CAMBIO-CREDIT';
            INSERT INTO transactions.foreign_currency_transactions (
                foreign_currency_transactions_id, foreign_currency_transactions_user_account_currency_id,
                foreign_currency_transactions_operation, foreign_currency_transactions_category_id,
                foreign_currency_transactions_operator_id, foreign_currency_transactions_description_id,
                foreign_currency_transactions_observations, foreign_currency_transactions_registration_datetime,
                foreign_currency_transactions_implementation_datetime, foreign_currency_transactions_base_value,
                foreign_currency_transactions_fees_taxes, foreign_currency_transactions_exchange_source
            ) VALUES (
                v_credit_txn_id, NEW.currencies_transfers_destination_user_account_id, 'Crédito'::core.operation,
                v_cat_id, NEW.currencies_transfers_operator_id, NULL, NEW.currencies_transfers_observations,
                NEW.currencies_transfers_registration_datetime, NEW.currencies_transfers_implementation_datetime,
                v_values_record.currencies_transfers_values_total_destination, 
                v_values_record.currencies_transfers_values_additional_fees_destination, 
                'CURRENCY_EXCHANGE'
            );
        END IF;

    ELSIF (TG_OP = 'DELETE') THEN
        -- Remover transações relacionadas de ambas as tabelas
        DELETE FROM transactions.transactions_saldo 
        WHERE transactions_saldo_id IN (
            OLD.currencies_transfers_id || '-CAMBIO-DEBIT',
            OLD.currencies_transfers_id || '-CAMBIO-CREDIT'
        );
        
        DELETE FROM transactions.foreign_currency_transactions 
        WHERE foreign_currency_transactions_id IN (
            OLD.currencies_transfers_id || '-CAMBIO-DEBIT',
            OLD.currencies_transfers_id || '-CAMBIO-CREDIT'
        );
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.sync_currency_transfer_to_transactions() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.sync_currency_transfer_to_transactions() IS 'Sincroniza operações de câmbio criando transações correspondentes: BRL em transactions_saldo e moedas estrangeiras em foreign_currency_transactions.';

-- =============================================================================
-- CRIAÇÃO DE TRIGGERS PARA SISTEMA DE CÂMBIO
-- =============================================================================

-- Trigger para atualizar taxa atual
CREATE TRIGGER trigger_update_current_currency_rate
    AFTER INSERT OR UPDATE ON core.currencies_exchange_rates_history
    FOR EACH ROW 
    WHEN (NEW.currencies_exchange_rates_history_is_current = true)
    EXECUTE FUNCTION public.update_current_currency_rate();
COMMENT ON TRIGGER trigger_update_current_currency_rate ON core.currencies_exchange_rates_history IS 'Atualiza taxa atual da moeda quando histórico é marcado como atual.';

-- Trigger para criar associação BRL automaticamente
CREATE TRIGGER trigger_auto_create_brl_currency_account
    AFTER INSERT ON core.user_accounts
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_create_brl_currency_account();
COMMENT ON TRIGGER trigger_auto_create_brl_currency_account ON core.user_accounts IS 'Cria automaticamente associação com BRL ao criar conta de usuário.';

-- Trigger para sincronizar operações de câmbio
CREATE TRIGGER trigger_sync_currency_transfer
    AFTER INSERT OR DELETE ON transactions.currencies_transfers
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_currency_transfer_to_transactions();
COMMENT ON TRIGGER trigger_sync_currency_transfer ON transactions.currencies_transfers IS 'Sincroniza operações de câmbio criando transações automáticas em transactions_saldo (BRL) e foreign_currency_transactions (moedas estrangeiras).';

-- Triggers de imutabilidade para novas tabelas
CREATE TRIGGER trigger_prevent_currencies_pk_update
BEFORE UPDATE ON core.currencies
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('currencies_id');

CREATE TRIGGER trigger_prevent_currencies_hist_pk_update
BEFORE UPDATE ON core.currencies_exchange_rates_history
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('currencies_exchange_rates_history_id');

CREATE TRIGGER trigger_prevent_uac_pk_update
BEFORE UPDATE ON core.user_accounts_currencies
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('user_accounts_currencies_id');

CREATE TRIGGER trigger_prevent_ct_pk_update
BEFORE UPDATE ON transactions.currencies_transfers
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('currencies_transfers_id');

CREATE TRIGGER trigger_prevent_fct_pk_update
BEFORE UPDATE ON transactions.foreign_currency_transactions
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('foreign_currency_transactions_id');

-- Triggers extras para integridade de currencies_transfers

-- Trigger para impedir transferências entre duas contas BRL
CREATE OR REPLACE FUNCTION transactions.chk_ct_not_both_brl_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_origin_currency_id varchar(50);
    v_dest_currency_id varchar(50);
BEGIN
    SELECT user_accounts_currencies_currency_id INTO v_origin_currency_id
      FROM core.user_accounts_currencies
     WHERE user_accounts_currencies_id = NEW.currencies_transfers_origin_user_account_id;
    SELECT user_accounts_currencies_currency_id INTO v_dest_currency_id
      FROM core.user_accounts_currencies
     WHERE user_accounts_currencies_id = NEW.currencies_transfers_destination_user_account_id;
    IF v_origin_currency_id = '1' AND v_dest_currency_id = '1' THEN
        RAISE EXCEPTION 'Não é permitido transferir entre duas contas BRL';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_chk_ct_not_both_brl
BEFORE INSERT OR UPDATE ON transactions.currencies_transfers
FOR EACH ROW EXECUTE FUNCTION transactions.chk_ct_not_both_brl_trigger();

-- Trigger para garantir que origem e destino pertençam ao mesmo usuário
CREATE OR REPLACE FUNCTION transactions.chk_ct_same_user_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_origin_user_id varchar(50);
    v_dest_user_id varchar(50);
BEGIN
    SELECT ua.user_accounts_user_id INTO v_origin_user_id
      FROM core.user_accounts_currencies uac
      JOIN core.user_accounts ua ON uac.user_accounts_currencies_user_account_id = ua.user_accounts_id
     WHERE uac.user_accounts_currencies_id = NEW.currencies_transfers_origin_user_account_id;
    SELECT ua.user_accounts_user_id INTO v_dest_user_id
      FROM core.user_accounts_currencies uac
      JOIN core.user_accounts ua ON uac.user_accounts_currencies_user_account_id = ua.user_accounts_id
     WHERE uac.user_accounts_currencies_id = NEW.currencies_transfers_destination_user_account_id;
    IF v_origin_user_id IS NULL OR v_dest_user_id IS NULL THEN
        RAISE EXCEPTION 'Conta de origem ou destino não encontrada.';
    END IF;
    IF v_origin_user_id <> v_dest_user_id THEN
        RAISE EXCEPTION 'Transferências de câmbio só são permitidas entre contas do mesmo usuário.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_chk_ct_same_user
BEFORE INSERT OR UPDATE ON transactions.currencies_transfers
FOR EACH ROW EXECUTE FUNCTION transactions.chk_ct_same_user_trigger();

-- =============================================================================
-- TRIGGERS DE AUDITORIA PARA NOVAS TABELAS
-- =============================================================================

-- Auditoria para currencies
CREATE TRIGGER trigger_audit_currencies
AFTER INSERT OR UPDATE OR DELETE ON core.currencies
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('currencies_id');

-- Auditoria para currencies_exchange_rates_history
CREATE TRIGGER trigger_audit_currencies_history
AFTER INSERT OR UPDATE OR DELETE ON core.currencies_exchange_rates_history
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('currencies_exchange_rates_history_id');

-- Auditoria para user_accounts_currencies
CREATE TRIGGER trigger_audit_user_accounts_currencies
AFTER INSERT OR UPDATE OR DELETE ON core.user_accounts_currencies
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('user_accounts_currencies_id');

-- Auditoria para currencies_transfers
CREATE TRIGGER trigger_audit_currencies_transfers
AFTER INSERT OR UPDATE OR DELETE ON transactions.currencies_transfers
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('currencies_transfers_id');

-- Auditoria para foreign_currency_transactions
CREATE TRIGGER trigger_audit_foreign_currency_transactions
AFTER INSERT OR UPDATE OR DELETE ON transactions.foreign_currency_transactions
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('foreign_currency_transactions_id');

CREATE OR REPLACE FUNCTION public.sync_internal_transfer_to_transactions()
RETURNS TRIGGER AS $$
DECLARE
    v_category_id character varying(50);
    v_proc_id character varying(50);
    v_debit_txn_id character varying(101);
    v_credit_txn_id character varying(101);
    v_debit_value_id character varying(105);
    v_credit_value_id character varying(105);
BEGIN
    -- Buscar categoria e procedimento padrão
    SELECT categories_id INTO v_category_id FROM core.categories WHERE categories_name = 'Transferências Internas' LIMIT 1;
    SELECT proceedings_id INTO v_proc_id FROM core.proceedings_saldo WHERE proceedings_name = 'Operação de Câmbio' LIMIT 1;
    IF v_category_id IS NULL THEN
        -- Cria a categoria padrão caso não exista
        INSERT INTO core.categories (categories_id, categories_name, categories_credit, categories_debit)
        VALUES ('CAT_TRANSF_INT', 'Transferências Internas', true, true)
        ON CONFLICT (categories_name) DO NOTHING;
        SELECT categories_id INTO v_category_id FROM core.categories WHERE categories_name = 'Transferências Internas' LIMIT 1;
    END IF;
    IF v_proc_id IS NULL THEN
        -- Cria o procedimento padrão caso não exista
        INSERT INTO core.proceedings_saldo (proceedings_id, proceedings_name, proceedings_credit, proceedings_debit)
        VALUES ('PROC_CAMBIO', 'Operação de Câmbio', true, true)
        ON CONFLICT (proceedings_name) DO NOTHING;
        SELECT proceedings_id INTO v_proc_id FROM core.proceedings_saldo WHERE proceedings_name = 'Operação de Câmbio' LIMIT 1;
    END IF;
    IF (TG_OP = 'INSERT') THEN
        -- Débito na origem
        v_debit_txn_id := NEW.internal_transfers_id || '-DEBIT';
        INSERT INTO transactions.transactions_saldo (
            transactions_saldo_id, transactions_saldo_user_accounts_id,
            transactions_saldo_operation, transactions_saldo_proceeding_id, transactions_saldo_status,
            transactions_saldo_category_id, transactions_saldo_operator_id, transactions_saldo_description,
            transactions_saldo_observations, transactions_saldo_registration_datetime,
            transactions_saldo_implementation_datetime,
            transactions_saldo_is_recurrence, transactions_saldo_relevance_ir
        ) VALUES (
            v_debit_txn_id, NEW.internal_transfers_origin_user_account_id, 'Débito'::core.operation, v_proc_id, 'Efetuado'::transactions.status,
            v_category_id, NEW.internal_transfers_operator_id, 'Transferência interna - saída', NEW.internal_transfers_observations,
            NEW.internal_transfers_registration_datetime, NEW.internal_transfers_implementation_datetime,
            FALSE, FALSE
        );
        
        -- Inserir registro na tabela de valores para débito
        v_debit_value_id := v_debit_txn_id || '-VALUE';
        INSERT INTO transactions.transactions_saldo_values (
            transactions_saldo_values_id,
            transactions_saldo_values_transaction_id,
            transactions_saldo_values_operation,
            transactions_saldo_values_value
        ) VALUES (
            v_debit_value_id,
            v_debit_txn_id,
            'Débito'::core.operation,
            NEW.internal_transfers_base_value + NEW.internal_transfers_fees_taxes
        );
        
        -- Crédito no destino
        v_credit_txn_id := NEW.internal_transfers_id || '-CREDIT';
        INSERT INTO transactions.transactions_saldo (
            transactions_saldo_id, transactions_saldo_user_accounts_id,
            transactions_saldo_operation, transactions_saldo_proceeding_id, transactions_saldo_status,
            transactions_saldo_category_id, transactions_saldo_operator_id, transactions_saldo_description,
            transactions_saldo_observations, transactions_saldo_registration_datetime,
            transactions_saldo_implementation_datetime,
            transactions_saldo_is_recurrence, transactions_saldo_relevance_ir
        ) VALUES (
            v_credit_txn_id, NEW.internal_transfers_destination_user_account_id, 'Crédito'::core.operation, v_proc_id, 'Efetuado'::transactions.status,
            v_category_id, NEW.internal_transfers_operator_id, 'Transferência interna - entrada', NEW.internal_transfers_observations,
            NEW.internal_transfers_registration_datetime, NEW.internal_transfers_implementation_datetime,
            FALSE, FALSE
        );
        
        -- Inserir registro na tabela de valores para crédito
        v_credit_value_id := v_credit_txn_id || '-VALUE';
        INSERT INTO transactions.transactions_saldo_values (
            transactions_saldo_values_id,
            transactions_saldo_values_transaction_id,
            transactions_saldo_values_operation,
            transactions_saldo_values_value
        ) VALUES (
            v_credit_value_id,
            v_credit_txn_id,
            'Crédito'::core.operation,
            NEW.internal_transfers_base_value - NEW.internal_transfers_fees_taxes
        );
        
    ELSIF (TG_OP = 'DELETE') THEN
        -- A exclusão em transactions_saldo_values ocorrerá automaticamente pela FK ON DELETE CASCADE
        DELETE FROM transactions.transactions_saldo 
        WHERE transactions_saldo_id IN (
            OLD.internal_transfers_id || '-DEBIT',
            OLD.internal_transfers_id || '-CREDIT'
        );
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_internal_transfer ON transactions.internal_transfers;

CREATE TRIGGER trigger_sync_internal_transfer
    AFTER INSERT OR DELETE ON transactions.internal_transfers
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_internal_transfer_to_transactions();



-- Triggers de imutabilidade e auditoria para tabelas que ainda não possuem

-- =========================
-- Tabelas do schema core
-- =========================

-- users
CREATE TRIGGER trigger_prevent_users_pk_update
BEFORE UPDATE ON core.users
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('users_id');

CREATE TRIGGER trigger_audit_users
AFTER INSERT OR UPDATE OR DELETE ON core.users
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('users_id');

-- categories
CREATE TRIGGER trigger_prevent_categories_pk_update
BEFORE UPDATE ON core.categories
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('categories_id');

CREATE TRIGGER trigger_audit_categories
AFTER INSERT OR UPDATE OR DELETE ON core.categories
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('categories_id');

-- proceedings_saldo
CREATE TRIGGER trigger_prevent_proceedings_saldo_pk_update
BEFORE UPDATE ON core.proceedings_saldo
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('proceedings_id');

CREATE TRIGGER trigger_audit_proceedings_saldo
AFTER INSERT OR UPDATE OR DELETE ON core.proceedings_saldo
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('proceedings_id');

-- financial_institutions
CREATE TRIGGER trigger_prevent_financial_institutions_pk_update
BEFORE UPDATE ON core.financial_institutions
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('financial_institutions_id');

CREATE TRIGGER trigger_audit_financial_institutions
AFTER INSERT OR UPDATE OR DELETE ON core.financial_institutions
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('financial_institutions_id');

-- account_types
CREATE TRIGGER trigger_prevent_account_types_pk_update
BEFORE UPDATE ON core.account_types
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('account_types_id');

CREATE TRIGGER trigger_audit_account_types
AFTER INSERT OR UPDATE OR DELETE ON core.account_types
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('account_types_id');

-- institution_accounts
CREATE TRIGGER trigger_prevent_institution_accounts_pk_update
BEFORE UPDATE ON core.institution_accounts
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('institution_accounts_id');

CREATE TRIGGER trigger_audit_institution_accounts
AFTER INSERT OR UPDATE OR DELETE ON core.institution_accounts
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('institution_accounts_id');

-- operators
CREATE TRIGGER trigger_prevent_operators_pk_update
BEFORE UPDATE ON core.operators
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('operators_id');

CREATE TRIGGER trigger_audit_operators
AFTER INSERT OR UPDATE OR DELETE ON core.operators
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('operators_id');

-- user_accounts
CREATE TRIGGER trigger_prevent_user_accounts_pk_update
BEFORE UPDATE ON core.user_accounts
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('user_accounts_id');

CREATE TRIGGER trigger_audit_user_accounts
AFTER INSERT OR UPDATE OR DELETE ON core.user_accounts
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('user_accounts_id');

-- user_accounts_pix_keys
CREATE TRIGGER trigger_prevent_user_accounts_pix_keys_pk_update
BEFORE UPDATE ON core.user_accounts_pix_keys
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('user_accounts_pix_keys_id');

CREATE TRIGGER trigger_audit_user_accounts_pix_keys
AFTER INSERT OR UPDATE OR DELETE ON core.user_accounts_pix_keys
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('user_accounts_pix_keys_id');

-- creditcard
CREATE TRIGGER trigger_prevent_creditcard_pk_update
BEFORE UPDATE ON core.creditcard
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_id');

CREATE TRIGGER trigger_audit_creditcard
AFTER INSERT OR UPDATE OR DELETE ON core.creditcard
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('creditcard_id');

-- user_creditcard
CREATE TRIGGER trigger_prevent_user_creditcard_pk_update
BEFORE UPDATE ON core.user_creditcard
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('user_creditcard_id');

CREATE TRIGGER trigger_audit_user_creditcard
AFTER INSERT OR UPDATE OR DELETE ON core.user_creditcard
FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('user_creditcard_id');

-- =========================
-- Tabelas do schema transactions
-- =========================

-- recurrence_saldo
CREATE TRIGGER trigger_prevent_recurrence_saldo_pk_update
BEFORE UPDATE ON transactions.recurrence_saldo
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('recurrence_saldo_id');

CREATE TRIGGER trigger_audit_recurrence_saldo
AFTER INSERT OR UPDATE OR DELETE ON transactions.recurrence_saldo
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('recurrence_saldo_id');

-- transactions_saldo
CREATE TRIGGER trigger_prevent_transactions_saldo_pk_update
BEFORE UPDATE ON transactions.transactions_saldo
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('transactions_saldo_id');

CREATE TRIGGER trigger_audit_transactions_saldo
AFTER INSERT OR UPDATE OR DELETE ON transactions.transactions_saldo
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('transactions_saldo_id');

-- internal_transfers
CREATE TRIGGER trigger_prevent_internal_transfers_pk_update
BEFORE UPDATE ON transactions.internal_transfers
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('internal_transfers_id');

CREATE TRIGGER trigger_audit_internal_transfers
AFTER INSERT OR UPDATE OR DELETE ON transactions.internal_transfers
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('internal_transfers_id');

-- creditcard_invoices
CREATE TRIGGER trigger_prevent_creditcard_invoices_pk_update
BEFORE UPDATE ON transactions.creditcard_invoices
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_invoices_id');

CREATE TRIGGER trigger_audit_creditcard_invoices
AFTER INSERT OR UPDATE OR DELETE ON transactions.creditcard_invoices
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('creditcard_invoices_id');

-- creditcard_recurrence
CREATE TRIGGER trigger_prevent_creditcard_recurrence_pk_update
BEFORE UPDATE ON transactions.creditcard_recurrence
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_recurrence_id');

CREATE TRIGGER trigger_audit_creditcard_recurrence
AFTER INSERT OR UPDATE OR DELETE ON transactions.creditcard_recurrence
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('creditcard_recurrence_id');

-- creditcard_transactions
CREATE TRIGGER trigger_prevent_creditcard_transactions_pk_update
BEFORE UPDATE ON transactions.creditcard_transactions
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_transactions_id');

CREATE TRIGGER trigger_audit_creditcard_transactions
AFTER INSERT OR UPDATE OR DELETE ON transactions.creditcard_transactions
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('creditcard_transactions_id');

-- creditcard_installments
CREATE TRIGGER trigger_prevent_creditcard_installments_pk_update
BEFORE UPDATE ON transactions.creditcard_installments
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_installments_id');

CREATE TRIGGER trigger_audit_creditcard_installments
AFTER INSERT OR UPDATE OR DELETE ON transactions.creditcard_installments
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('creditcard_installments_id');

-- =============================================================================
-- FINALIZAÇÃO DO SCRIPT
-- =============================================================================

-- Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE '=== SCRIPT EXECUTADO COM SUCESSO ===';
    RAISE NOTICE 'Banco de dados SisFinance criado e configurado.';
    RAISE NOTICE 'Schemas: core, transactions, auditoria';
    RAISE NOTICE 'Todas as tabelas, funções, triggers e views foram criadas.';
    RAISE NOTICE '=======================================';
END $$;

-- =============================================================================
-- CRIAÇÃO DOS TIPOS ENUM PARA INVESTIMENTOS
-- =============================================================================

-- Tipo de Mercado (Local/Internacional)
CREATE TYPE core.investment_type_enum AS ENUM ('Local', 'Internacional');
ALTER TYPE core.investment_type_enum OWNER TO "SisFinance-adm";
COMMENT ON TYPE core.investment_type_enum IS 'Define se o investimento é no mercado local (Brasil) ou internacional.';

-- Tipo de Operação de Investimento
CREATE TYPE core.investment_operation_enum AS ENUM ('Aplicação', 'Resgate');
ALTER TYPE core.investment_operation_enum OWNER TO "SisFinance-adm";
COMMENT ON TYPE core.investment_operation_enum IS 'Define o tipo de operação realizada no investimento.';

-- =============================================================================
-- CRIAÇÃO DAS TABELAS DE INVESTIMENTOS
-- =============================================================================

-- Tabela: investment_indexes (Benchmarks)
CREATE TABLE core.investment_indexes (
    investment_indexes_id character varying(50) NOT NULL,
    investment_indexes_name character varying(100) NOT NULL,
    investment_indexes_currency_id character varying(50) NOT NULL,
    investment_indexes_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT investment_indexes_pkey PRIMARY KEY (investment_indexes_id),
    CONSTRAINT fk_investment_indexes_currency FOREIGN KEY (investment_indexes_currency_id) REFERENCES core.currencies(currencies_id) ON DELETE RESTRICT ON UPDATE NO ACTION
);
ALTER TABLE core.investment_indexes OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.investment_indexes IS 'Catálogo de índices de referência (benchmarks) para investimentos.';
COMMENT ON COLUMN core.investment_indexes.investment_indexes_id IS 'Identificador único do índice (PK, fornecido externamente).';
COMMENT ON COLUMN core.investment_indexes.investment_indexes_name IS 'Nome do índice de referência (ex: CDI, IPCA, S&P 500).';
COMMENT ON COLUMN core.investment_indexes.investment_indexes_currency_id IS 'Moeda base do índice (FK para currencies).';
COMMENT ON COLUMN core.investment_indexes.investment_indexes_last_update IS 'Data da última atualização do registro.';

-- Tabela: investment_indexes_history (Histórico de preços dos benchmarks)
CREATE TABLE core.investment_indexes_history (
    investment_indexes_history_id character varying(50) NOT NULL,
    investment_indexes_id character varying(50) NOT NULL,
    investment_indexes_history_date date NOT NULL,
    investment_indexes_history_value numeric(15,6) NOT NULL,
    CONSTRAINT investment_indexes_history_pkey PRIMARY KEY (investment_indexes_history_id),
    CONSTRAINT fk_investment_indexes_history FOREIGN KEY (investment_indexes_id) REFERENCES core.investment_indexes(investment_indexes_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT uq_investment_indexes_history_date UNIQUE (investment_indexes_id, investment_indexes_history_date)
);
ALTER TABLE core.investment_indexes_history OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.investment_indexes_history IS 'Histórico de valores dos índices de referência.';
COMMENT ON COLUMN core.investment_indexes_history.investment_indexes_history_id IS 'Identificador único do registro histórico (PK, fornecido externamente).';
COMMENT ON COLUMN core.investment_indexes_history.investment_indexes_id IS 'Referência ao índice (FK para investment_indexes).';
COMMENT ON COLUMN core.investment_indexes_history.investment_indexes_history_date IS 'Data do valor registrado.';
COMMENT ON COLUMN core.investment_indexes_history.investment_indexes_history_value IS 'Valor do índice na data especificada.';

-- Tabela: investment_fixed_issuers (Emissores de renda fixa)
CREATE TABLE core.investment_fixed_issuers (
    investment_fixed_issuers_id character varying(50) NOT NULL,
    investment_fixed_issuers_name text NOT NULL,
    investment_fixed_issuers_type core.investment_type_enum NOT NULL,
    CONSTRAINT investment_fixed_issuers_pkey PRIMARY KEY (investment_fixed_issuers_id)
);
ALTER TABLE core.investment_fixed_issuers OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.investment_fixed_issuers IS 'Catálogo de emissores de investimentos de renda fixa.';
COMMENT ON COLUMN core.investment_fixed_issuers.investment_fixed_issuers_id IS 'Identificador único do emissor (PK, fornecido externamente).';
COMMENT ON COLUMN core.investment_fixed_issuers.investment_fixed_issuers_name IS 'Nome do emissor (ex: Tesouro Nacional, Banco do Brasil).';
COMMENT ON COLUMN core.investment_fixed_issuers.investment_fixed_issuers_type IS 'Tipo de mercado do emissor (Local ou Internacional).';

-- Tabela: investment_fixed_products (Produtos de renda fixa)
CREATE TABLE core.investment_fixed_products (
    investment_fixed_products_id character varying(50) NOT NULL,
    investment_fixed_products_description text NOT NULL,
    investment_fixed_products_issuers_id character varying(50) NOT NULL,
    investment_fixed_products_yield_rate numeric(8,4),
    investment_fixed_products_index_id character varying(50),
    investment_fixed_products_currency_id character varying(50) NOT NULL,
    investment_fixed_products_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT investment_fixed_products_pkey PRIMARY KEY (investment_fixed_products_id),
    CONSTRAINT fk_investment_fixed_products_issuers FOREIGN KEY (investment_fixed_products_issuers_id) REFERENCES core.investment_fixed_issuers(investment_fixed_issuers_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_investment_fixed_products_index FOREIGN KEY (investment_fixed_products_index_id) REFERENCES core.investment_indexes(investment_indexes_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT fk_investment_fixed_products_currency FOREIGN KEY (investment_fixed_products_currency_id) REFERENCES core.currencies(currencies_id) ON DELETE RESTRICT ON UPDATE NO ACTION
);
ALTER TABLE core.investment_fixed_products OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.investment_fixed_products IS 'Catálogo de produtos de investimento de renda fixa disponíveis.';
COMMENT ON COLUMN core.investment_fixed_products.investment_fixed_products_id IS 'Identificador único do produto (PK, fornecido externamente).';
COMMENT ON COLUMN core.investment_fixed_products.investment_fixed_products_description IS 'Descrição detalhada do produto de investimento.';
COMMENT ON COLUMN core.investment_fixed_products.investment_fixed_products_issuers_id IS 'Referência ao emissor (FK para investment_fixed_issuers).';
COMMENT ON COLUMN core.investment_fixed_products.investment_fixed_products_yield_rate IS 'Taxa de rendimento do produto (opcional).';
COMMENT ON COLUMN core.investment_fixed_products.investment_fixed_products_index_id IS 'Índice de referência do produto (FK para investment_indexes, opcional).';
COMMENT ON COLUMN core.investment_fixed_products.investment_fixed_products_currency_id IS 'Moeda do produto (FK para currencies).';
COMMENT ON COLUMN core.investment_fixed_products.investment_fixed_products_last_update IS 'Data da última atualização do registro.';

-- Tabela: investment_variable_types (Tipos de renda variável)
CREATE TABLE core.investment_variable_types (
    investment_variable_types_id character varying(50) NOT NULL,
    investment_variable_types_name character varying(100) NOT NULL,
    investment_variable_types_description text NOT NULL,
    CONSTRAINT investment_variable_types_pkey PRIMARY KEY (investment_variable_types_id)
);
ALTER TABLE core.investment_variable_types OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.investment_variable_types IS 'Catálogo de tipos de investimentos de renda variável.';
COMMENT ON COLUMN core.investment_variable_types.investment_variable_types_id IS 'Identificador único do tipo (PK, fornecido externamente).';
COMMENT ON COLUMN core.investment_variable_types.investment_variable_types_name IS 'Nome do tipo de investimento (ex: Ações, ETFs, REITs).';
COMMENT ON COLUMN core.investment_variable_types.investment_variable_types_description IS 'Descrição detalhada do tipo de investimento.';

-- Tabela: investment_stock_exchanges (Bolsas de valores)
CREATE TABLE core.investment_stock_exchanges (
    investment_stock_exchanges_id character varying(50) NOT NULL,
    investment_stock_exchanges_name character varying(100) NOT NULL,
    investment_stock_exchanges_description character varying(100),
    investment_stock_exchanges_type core.investment_type_enum NOT NULL,
    investment_stock_exchanges_currency_id character varying(50) NOT NULL,
    CONSTRAINT investment_stock_exchanges_pkey PRIMARY KEY (investment_stock_exchanges_id),
    CONSTRAINT fk_investment_stock_exchanges_currency FOREIGN KEY (investment_stock_exchanges_currency_id) REFERENCES core.currencies(currencies_id) ON DELETE RESTRICT ON UPDATE NO ACTION
);
ALTER TABLE core.investment_stock_exchanges OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.investment_stock_exchanges IS 'Catálogo de bolsas de valores onde os ativos são negociados.';
COMMENT ON COLUMN core.investment_stock_exchanges.investment_stock_exchanges_id IS 'Identificador único da bolsa (PK, fornecido externamente).';
COMMENT ON COLUMN core.investment_stock_exchanges.investment_stock_exchanges_name IS 'Nome da bolsa de valores (ex: B3, NYSE, NASDAQ).';
COMMENT ON COLUMN core.investment_stock_exchanges.investment_stock_exchanges_description IS 'Descrição da bolsa (opcional).';
COMMENT ON COLUMN core.investment_stock_exchanges.investment_stock_exchanges_type IS 'Tipo de mercado da bolsa (Local ou Internacional).';
COMMENT ON COLUMN core.investment_stock_exchanges.investment_stock_exchanges_currency_id IS 'Moeda principal da bolsa (FK para currencies).';

-- Tabela: investment_variable_assets (Ativos de renda variável)
CREATE TABLE core.investment_variable_assets (
    investment_variable_assets_id character varying(50) NOT NULL,
    investment_variable_assets_type_id character varying(50) NOT NULL,
    investment_variable_assets_name character varying(100) NOT NULL,
    investment_variable_assets_stock_exchange_id character varying(50) NOT NULL,
    investment_variable_assets_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT investment_variable_assets_pkey PRIMARY KEY (investment_variable_assets_id),
    CONSTRAINT fk_investment_variable_assets_type FOREIGN KEY (investment_variable_assets_type_id) REFERENCES core.investment_variable_types(investment_variable_types_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_investment_variable_assets_exchange FOREIGN KEY (investment_variable_assets_stock_exchange_id) REFERENCES core.investment_stock_exchanges(investment_stock_exchanges_id) ON DELETE RESTRICT ON UPDATE NO ACTION
);
ALTER TABLE core.investment_variable_assets OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.investment_variable_assets IS 'Catálogo de ativos de renda variável disponíveis para investimento.';
COMMENT ON COLUMN core.investment_variable_assets.investment_variable_assets_id IS 'Identificador único do ativo (PK, fornecido externamente).';
COMMENT ON COLUMN core.investment_variable_assets.investment_variable_assets_type_id IS 'Tipo do ativo (FK para investment_variable_types).';
COMMENT ON COLUMN core.investment_variable_assets.investment_variable_assets_name IS 'Nome/código do ativo (ex: PETR4, AAPL, ITUB4).';
COMMENT ON COLUMN core.investment_variable_assets.investment_variable_assets_stock_exchange_id IS 'Bolsa onde o ativo é negociado (FK para investment_stock_exchanges).';
COMMENT ON COLUMN core.investment_variable_assets.investment_variable_assets_last_update IS 'Data da última atualização do registro.';

-- Tabela: investment_variable_assets_history (Histórico de preços dos ativos)
CREATE TABLE core.investment_variable_assets_history (
    investment_variable_assets_history_id character varying(50) NOT NULL,
    investment_variable_assets_history_asset_id character varying(50) NOT NULL,
    investment_variable_assets_history_date date NOT NULL,
    investment_variable_assets_history_price numeric(15,6) NOT NULL,
    investment_variable_assets_history_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT investment_variable_assets_history_pkey PRIMARY KEY (investment_variable_assets_history_id),
    CONSTRAINT fk_investment_variable_assets_history FOREIGN KEY (investment_variable_assets_history_asset_id) REFERENCES core.investment_variable_assets(investment_variable_assets_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT uq_investment_variable_assets_history_date UNIQUE (investment_variable_assets_history_asset_id, investment_variable_assets_history_date)
);
ALTER TABLE core.investment_variable_assets_history OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.investment_variable_assets_history IS 'Histórico de preços dos ativos de renda variável.';
COMMENT ON COLUMN core.investment_variable_assets_history.investment_variable_assets_history_id IS 'Identificador único do registro histórico (PK, fornecido externamente).';
COMMENT ON COLUMN core.investment_variable_assets_history.investment_variable_assets_history_asset_id IS 'Referência ao ativo (FK para investment_variable_assets).';
COMMENT ON COLUMN core.investment_variable_assets_history.investment_variable_assets_history_date IS 'Data do preço registrado.';
COMMENT ON COLUMN core.investment_variable_assets_history.investment_variable_assets_history_price IS 'Preço do ativo na data especificada.';
COMMENT ON COLUMN core.investment_variable_assets_history.investment_variable_assets_history_last_update IS 'Data da última atualização do registro.';

-- Tabela: investment_fixed_history (Histórico de preços dos produtos de renda fixa)
CREATE TABLE core.investment_fixed_history (
    investment_fixed_history_id character varying(50) NOT NULL,
    investment_fixed_products_id character varying(50) NOT NULL,
    investment_fixed_history_date date NOT NULL,
    investment_fixed_history_price numeric(15,6) NOT NULL,
    investment_fixed_history_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT investment_fixed_history_pkey PRIMARY KEY (investment_fixed_history_id),
    CONSTRAINT fk_investment_fixed_history FOREIGN KEY (investment_fixed_products_id) REFERENCES core.investment_fixed_products(investment_fixed_products_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT uq_investment_fixed_history_date UNIQUE (investment_fixed_products_id, investment_fixed_history_date)
);
ALTER TABLE core.investment_fixed_history OWNER TO "SisFinance-adm";
COMMENT ON TABLE core.investment_fixed_history IS 'Histórico de preços dos produtos de renda fixa.';
COMMENT ON COLUMN core.investment_fixed_history.investment_fixed_history_id IS 'Identificador único do registro histórico (PK, fornecido externamente).';
COMMENT ON COLUMN core.investment_fixed_history.investment_fixed_products_id IS 'Referência ao produto (FK para investment_fixed_products).';
COMMENT ON COLUMN core.investment_fixed_history.investment_fixed_history_date IS 'Data do preço registrado.';
COMMENT ON COLUMN core.investment_fixed_history.investment_fixed_history_price IS 'Preço do produto na data especificada.';
COMMENT ON COLUMN core.investment_fixed_history.investment_fixed_history_last_update IS 'Data da última atualização do registro.';

-- =============================================================================
-- TABELAS DE TRANSAÇÕES DE INVESTIMENTOS
-- =============================================================================

-- Tabela: investments_fixed (Transações de renda fixa)
CREATE TABLE transactions.investments_fixed (
    investments_fixed_id character varying(50) NOT NULL,
    investments_fixed_product_id character varying(50) NOT NULL,
    investments_fixed_user_accounts_id character varying(50) NOT NULL,
    investments_fixed_operator_id character varying(50) NOT NULL,
    investments_fixed_operation core.investment_operation_enum NOT NULL,
    investments_fixed_status transactions.status NOT NULL,
    investments_fixed_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    investments_fixed_purchase_datetime timestamp with time zone NOT NULL,
    investments_fixed_maturity_date timestamp with time zone,
    investments_fixed_quantity numeric(15,6) NOT NULL,
    investments_fixed_unit_purchase_price numeric(15,2) NOT NULL,
    investments_fixed_total_invested_purchase numeric(15,2) NOT NULL,
    investments_fixed_fees_taxes numeric(15,2) NOT NULL DEFAULT 0,
    investments_fixed_subtotal numeric(15,2) GENERATED ALWAYS AS (investments_fixed_total_invested_purchase - investments_fixed_fees_taxes) STORED,
    investments_fixed_total_effective_purchase numeric(15,2) GENERATED ALWAYS AS (CASE WHEN investments_fixed_operation = 'Aplicação' THEN (investments_fixed_total_invested_purchase - investments_fixed_fees_taxes) * -1 ELSE (investments_fixed_total_invested_purchase - investments_fixed_fees_taxes) END) STORED,
    investments_fixed_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT investments_fixed_pkey PRIMARY KEY (investments_fixed_id),
    CONSTRAINT fk_investments_fixed_product FOREIGN KEY (investments_fixed_product_id) REFERENCES core.investment_fixed_products(investment_fixed_products_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_investments_fixed_user_accounts FOREIGN KEY (investments_fixed_user_accounts_id) REFERENCES core.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_investments_fixed_operator FOREIGN KEY (investments_fixed_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT chk_investments_fixed_quantity_positive CHECK (investments_fixed_quantity > 0),
    CONSTRAINT chk_investments_fixed_price_positive CHECK (investments_fixed_unit_purchase_price > 0),
    CONSTRAINT chk_investments_fixed_total_positive CHECK (investments_fixed_total_invested_purchase > 0)
);
ALTER TABLE transactions.investments_fixed OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.investments_fixed IS 'Registra transações de investimentos em renda fixa.';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_id IS 'Identificador único da transação (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_product_id IS 'Produto de renda fixa transacionado (FK para investment_fixed_products).';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_user_accounts_id IS 'Conta de custódia do usuário (FK para user_accounts).';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_operator_id IS 'Operador responsável pela transação (FK para operators).';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_operation IS 'Tipo de operação realizada (Aplicação ou Resgate).';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_status IS 'Status da transação (Efetuado ou Pendente).';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_registration_datetime IS 'Data e hora de registro da transação.';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_purchase_datetime IS 'Data e hora de execução da transação.';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_maturity_date IS 'Data de vencimento do investimento (opcional).';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_quantity IS 'Quantidade de unidades transacionadas.';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_unit_purchase_price IS 'Preço unitário na transação.';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_total_invested_purchase IS 'Valor total bruto da transação.';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_fees_taxes IS 'Taxas e impostos da transação.';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_subtotal IS 'Valor líquido da transação (total - taxas).';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_total_effective_purchase IS 'Valor efetivo com sinal (negativo para aplicação, positivo para resgate).';
COMMENT ON COLUMN transactions.investments_fixed.investments_fixed_last_update IS 'Data da última atualização do registro.';

-- Tabela: investments_variable (Transações de renda variável)
CREATE TABLE transactions.investments_variable (
    investments_variable_id character varying(50) NOT NULL,
    investments_variable_asset_id character varying(50) NOT NULL,
    investments_variable_user_accounts_id character varying(50) NOT NULL,
    investments_variable_operator_id character varying(50) NOT NULL,
    investments_variable_operation core.investment_operation_enum NOT NULL,
    investments_variable_status transactions.status NOT NULL,
    investments_variable_registration_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    investments_variable_purchase_datetime timestamp with time zone NOT NULL,
    investments_variable_quantity numeric(15,0) NOT NULL,
    investments_variable_unit_price_purchase numeric(15,2) NOT NULL,
    investments_variable_total_invested_purchase numeric(15,2) NOT NULL,
    investments_variable_fees_taxes numeric(15,2) NOT NULL DEFAULT 0,
    investments_variable_subtotal numeric(15,2) GENERATED ALWAYS AS (investments_variable_total_invested_purchase - investments_variable_fees_taxes) STORED,
    investments_variable_total_effective_purchase numeric(15,2) GENERATED ALWAYS AS (CASE WHEN investments_variable_operation = 'Aplicação' THEN (investments_variable_total_invested_purchase - investments_variable_fees_taxes) * -1 ELSE (investments_variable_total_invested_purchase - investments_variable_fees_taxes) END) STORED,
    investments_variable_last_update timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT investments_variable_pkey PRIMARY KEY (investments_variable_id),
    CONSTRAINT fk_investments_variable_asset FOREIGN KEY (investments_variable_asset_id) REFERENCES core.investment_variable_assets(investment_variable_assets_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_investments_variable_user_accounts FOREIGN KEY (investments_variable_user_accounts_id) REFERENCES core.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_investments_variable_operator FOREIGN KEY (investments_variable_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT chk_investments_variable_quantity_positive CHECK (investments_variable_quantity > 0),
    CONSTRAINT chk_investments_variable_price_positive CHECK (investments_variable_unit_price_purchase > 0),
    CONSTRAINT chk_investments_variable_total_positive CHECK (investments_variable_total_invested_purchase > 0)
);
ALTER TABLE transactions.investments_variable OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.investments_variable IS 'Registra transações de investimentos em renda variável.';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_id IS 'Identificador único da transação (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_asset_id IS 'Ativo de renda variável transacionado (FK para investment_variable_assets).';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_user_accounts_id IS 'Conta de custódia do usuário (FK para user_accounts).';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_operator_id IS 'Operador responsável pela transação (FK para operators).';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_operation IS 'Tipo de operação realizada (Aplicação ou Resgate).';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_status IS 'Status da transação (Efetuado ou Pendente).';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_registration_datetime IS 'Data e hora de registro da transação.';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_purchase_datetime IS 'Data e hora de execução da transação.';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_quantity IS 'Quantidade de unidades transacionadas.';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_unit_price_purchase IS 'Preço unitário na transação.';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_total_invested_purchase IS 'Valor total bruto da transação.';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_fees_taxes IS 'Taxas e impostos da transação.';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_subtotal IS 'Valor líquido da transação (total - taxas).';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_total_effective_purchase IS 'Valor efetivo com sinal (negativo para aplicação, positivo para resgate).';
COMMENT ON COLUMN transactions.investments_variable.investments_variable_last_update IS 'Data da última atualização do registro.';

-- =============================================================================
-- FUNÇÕES PARA VALIDAÇÃO DE CONTAS DE CUSTÓDIA
-- =============================================================================

-- Função para validar conta de custódia
CREATE OR REPLACE FUNCTION public.validate_custody_account()
RETURNS TRIGGER AS $$
DECLARE
    v_account_type_name text;
BEGIN
    -- Buscar o tipo de conta
    SELECT at.account_types_name INTO v_account_type_name
    FROM core.user_accounts ua
    JOIN core.institution_accounts ia ON ua.user_accounts_institution_account_id = ia.institution_accounts_id
    JOIN core.account_types at ON ia.institution_accounts_type_id = at.account_types_id
    WHERE ua.user_accounts_id = NEW.investments_fixed_user_accounts_id;
    
    -- Validar se é conta de custódia
    IF v_account_type_name != 'Conta de Custódia' THEN
        RAISE EXCEPTION 'Investimentos só podem ser realizados em contas do tipo "Conta de Custódia". Tipo encontrado: %', v_account_type_name;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.validate_custody_account() OWNER TO "SisFinance-adm";

-- Função similar para renda variável
CREATE OR REPLACE FUNCTION public.validate_custody_account_variable()
RETURNS TRIGGER AS $$
DECLARE
    v_account_type_name text;
BEGIN
    -- Buscar o tipo de conta
    SELECT at.account_types_name INTO v_account_type_name
    FROM core.user_accounts ua
    JOIN core.institution_accounts ia ON ua.user_accounts_institution_account_id = ia.institution_accounts_id
    JOIN core.account_types at ON ia.institution_accounts_type_id = at.account_types_id
    WHERE ua.user_accounts_id = NEW.investments_variable_user_accounts_id;
    
    -- Validar se é conta de custódia
    IF v_account_type_name != 'Conta de Custódia' THEN
        RAISE EXCEPTION 'Investimentos só podem ser realizados em contas do tipo "Conta de Custódia". Tipo encontrado: %', v_account_type_name;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.validate_custody_account_variable() OWNER TO "SisFinance-adm";

-- =============================================================================
-- TRIGGERS PARA VALIDAÇÃO E AUDITORIA
-- =============================================================================

-- Triggers para validação de conta de custódia
CREATE TRIGGER trigger_validate_custody_account_fixed
    BEFORE INSERT OR UPDATE ON transactions.investments_fixed
    FOR EACH ROW
    EXECUTE FUNCTION public.validate_custody_account();

CREATE TRIGGER trigger_validate_custody_account_variable
    BEFORE INSERT OR UPDATE ON transactions.investments_variable
    FOR EACH ROW
    EXECUTE FUNCTION public.validate_custody_account_variable();

-- Triggers de imutabilidade de PKs
CREATE TRIGGER trigger_prevent_investment_indexes_pk_update
    BEFORE UPDATE ON core.investment_indexes
    FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('investment_indexes_id');

CREATE TRIGGER trigger_prevent_investment_indexes_history_pk_update
    BEFORE UPDATE ON core.investment_indexes_history
    FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('investment_indexes_history_id');

CREATE TRIGGER trigger_prevent_investment_fixed_issuers_pk_update
    BEFORE UPDATE ON core.investment_fixed_issuers
    FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('investment_fixed_issuers_id');

CREATE TRIGGER trigger_prevent_investment_fixed_products_pk_update
    BEFORE UPDATE ON core.investment_fixed_products
    FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('investment_fixed_products_id');

CREATE TRIGGER trigger_prevent_investment_variable_types_pk_update
    BEFORE UPDATE ON core.investment_variable_types
    FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('investment_variable_types_id');

CREATE TRIGGER trigger_prevent_investment_stock_exchanges_pk_update
    BEFORE UPDATE ON core.investment_stock_exchanges
    FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('investment_stock_exchanges_id');

CREATE TRIGGER trigger_prevent_investment_variable_assets_pk_update
    BEFORE UPDATE ON core.investment_variable_assets
    FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('investment_variable_assets_id');

CREATE TRIGGER trigger_prevent_investment_variable_assets_history_pk_update
    BEFORE UPDATE ON core.investment_variable_assets_history
    FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('investment_variable_assets_history_id');

CREATE TRIGGER trigger_prevent_investment_fixed_history_pk_update
    BEFORE UPDATE ON core.investment_fixed_history
    FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('investment_fixed_history_id');

CREATE TRIGGER trigger_prevent_investments_fixed_pk_update
    BEFORE UPDATE ON transactions.investments_fixed
    FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('investments_fixed_id');

CREATE TRIGGER trigger_prevent_investments_variable_pk_update
    BEFORE UPDATE ON transactions.investments_variable
    FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('investments_variable_id');

-- Triggers de auditoria para tabelas core
CREATE TRIGGER trigger_audit_investment_indexes
    AFTER INSERT OR UPDATE OR DELETE ON core.investment_indexes
    FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('investment_indexes_id');

CREATE TRIGGER trigger_audit_investment_indexes_history
    AFTER INSERT OR UPDATE OR DELETE ON core.investment_indexes_history
    FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('investment_indexes_history_id');

CREATE TRIGGER trigger_audit_investment_fixed_issuers
    AFTER INSERT OR UPDATE OR DELETE ON core.investment_fixed_issuers
    FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('investment_fixed_issuers_id');

CREATE TRIGGER trigger_audit_investment_fixed_products
    AFTER INSERT OR UPDATE OR DELETE ON core.investment_fixed_products
    FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('investment_fixed_products_id');

CREATE TRIGGER trigger_audit_investment_variable_types
    AFTER INSERT OR UPDATE OR DELETE ON core.investment_variable_types
    FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('investment_variable_types_id');

CREATE TRIGGER trigger_audit_investment_stock_exchanges
    AFTER INSERT OR UPDATE OR DELETE ON core.investment_stock_exchanges
    FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('investment_stock_exchanges_id');

CREATE TRIGGER trigger_audit_investment_variable_assets
    AFTER INSERT OR UPDATE OR DELETE ON core.investment_variable_assets
    FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('investment_variable_assets_id');

CREATE TRIGGER trigger_audit_investment_variable_assets_history
    AFTER INSERT OR UPDATE OR DELETE ON core.investment_variable_assets_history
    FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('investment_variable_assets_history_id');

CREATE TRIGGER trigger_audit_investment_fixed_history
    AFTER INSERT OR UPDATE OR DELETE ON core.investment_fixed_history
    FOR EACH ROW EXECUTE FUNCTION public.log_core_audit('investment_fixed_history_id');

-- Triggers de auditoria para tabelas transactions
CREATE TRIGGER trigger_audit_investments_fixed
    AFTER INSERT OR UPDATE OR DELETE ON transactions.investments_fixed
    FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('investments_fixed_id');

CREATE TRIGGER trigger_audit_investments_variable
    AFTER INSERT OR UPDATE OR DELETE ON transactions.investments_variable
    FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('investments_variable_id');

-- =============================================================================
-- VIEWS PARA POSIÇÕES DE INVESTIMENTOS
-- =============================================================================

-- View 1: Posições ativas de renda fixa por usuário e tipo de mercado
CREATE OR REPLACE VIEW transactions.view_fixed_income_positions_by_user AS
SELECT 
    ua.user_accounts_user_id,
    u.users_first_name,
    u.users_last_name,
    ifp.investment_fixed_products_id,
    ifp.investment_fixed_products_description,
    ifi.investment_fixed_issuers_name,
    ifi.investment_fixed_issuers_type,
    curr.currencies_iso,
    curr.currencies_name,
    SUM(CASE WHEN if_trans.investments_fixed_operation = 'Aplicação' THEN if_trans.investments_fixed_quantity ELSE -if_trans.investments_fixed_quantity END) AS net_quantity,
    COALESCE(latest_price.investment_fixed_history_price, 0) AS current_unit_price,
    (SUM(CASE WHEN if_trans.investments_fixed_operation = 'Aplicação' THEN if_trans.investments_fixed_quantity ELSE -if_trans.investments_fixed_quantity END) * COALESCE(latest_price.investment_fixed_history_price, 0)) AS current_market_value,
    (SUM(CASE WHEN if_trans.investments_fixed_operation = 'Aplicação' THEN if_trans.investments_fixed_quantity ELSE -if_trans.investments_fixed_quantity END) * COALESCE(latest_price.investment_fixed_history_price, 0)) * curr.currencies_value AS current_market_value_brl
FROM 
    transactions.investments_fixed if_trans
    JOIN core.investment_fixed_products ifp ON if_trans.investments_fixed_product_id = ifp.investment_fixed_products_id
    JOIN core.investment_fixed_issuers ifi ON ifp.investment_fixed_products_issuers_id = ifi.investment_fixed_issuers_id
    JOIN core.user_accounts ua ON if_trans.investments_fixed_user_accounts_id = ua.user_accounts_id
    JOIN core.users u ON ua.user_accounts_user_id = u.users_id
    JOIN core.currencies curr ON ifp.investment_fixed_products_currency_id = curr.currencies_id
    LEFT JOIN (
        SELECT 
            ifh.investment_fixed_products_id,
            ifh.investment_fixed_history_price,
            ROW_NUMBER() OVER (PARTITION BY ifh.investment_fixed_products_id ORDER BY ifh.investment_fixed_history_date DESC) as rn
        FROM core.investment_fixed_history ifh
    ) latest_price ON ifp.investment_fixed_products_id = latest_price.investment_fixed_products_id AND latest_price.rn = 1
WHERE 
    if_trans.investments_fixed_status = 'Efetuado'
GROUP BY 
    ua.user_accounts_user_id, u.users_first_name, u.users_last_name,
    ifp.investment_fixed_products_id, ifp.investment_fixed_products_description,
    ifi.investment_fixed_issuers_name, ifi.investment_fixed_issuers_type,
    curr.currencies_iso, curr.currencies_name, curr.currencies_value,
    latest_price.investment_fixed_history_price
HAVING 
    SUM(CASE WHEN if_trans.investments_fixed_operation = 'Aplicação' THEN if_trans.investments_fixed_quantity ELSE -if_trans.investments_fixed_quantity END) > 0;

ALTER VIEW transactions.view_fixed_income_positions_by_user OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_fixed_income_positions_by_user IS 'Posições ativas de renda fixa por usuário, separadas por tipo de mercado (Local/Internacional).';

-- View 2: Posições ativas de renda fixa por usuário, tipo de mercado e conta
CREATE OR REPLACE VIEW transactions.view_fixed_income_positions_by_account AS
SELECT 
    ua.user_accounts_user_id,
    u.users_first_name,
    u.users_last_name,
    ua.user_accounts_id,
    fi.financial_institutions_name,
    ifp.investment_fixed_products_id,
    ifp.investment_fixed_products_description,
    ifi.investment_fixed_issuers_name,
    ifi.investment_fixed_issuers_type,
    curr.currencies_iso,
    curr.currencies_name,
    SUM(CASE WHEN if_trans.investments_fixed_operation = 'Aplicação' THEN if_trans.investments_fixed_quantity ELSE -if_trans.investments_fixed_quantity END) AS net_quantity,
    COALESCE(latest_price.investment_fixed_history_price, 0) AS current_unit_price,
    (SUM(CASE WHEN if_trans.investments_fixed_operation = 'Aplicação' THEN if_trans.investments_fixed_quantity ELSE -if_trans.investments_fixed_quantity END) * COALESCE(latest_price.investment_fixed_history_price, 0)) AS current_market_value,
    (SUM(CASE WHEN if_trans.investments_fixed_operation = 'Aplicação' THEN if_trans.investments_fixed_quantity ELSE -if_trans.investments_fixed_quantity END) * COALESCE(latest_price.investment_fixed_history_price, 0)) * curr.currencies_value AS current_market_value_brl
FROM 
    transactions.investments_fixed if_trans
    JOIN core.investment_fixed_products ifp ON if_trans.investments_fixed_product_id = ifp.investment_fixed_products_id
    JOIN core.investment_fixed_issuers ifi ON ifp.investment_fixed_products_issuers_id = ifi.investment_fixed_issuers_id
    JOIN core.user_accounts ua ON if_trans.investments_fixed_user_accounts_id = ua.user_accounts_id
    JOIN core.users u ON ua.user_accounts_user_id = u.users_id
    JOIN core.institution_accounts ia ON ua.user_accounts_institution_account_id = ia.institution_accounts_id
    JOIN core.financial_institutions fi ON ia.institution_accounts_institution_id = fi.financial_institutions_id
    JOIN core.currencies curr ON ifp.investment_fixed_products_currency_id = curr.currencies_id
    LEFT JOIN (
        SELECT 
            ifh.investment_fixed_products_id,
            ifh.investment_fixed_history_price,
            ROW_NUMBER() OVER (PARTITION BY ifh.investment_fixed_products_id ORDER BY ifh.investment_fixed_history_date DESC) as rn
        FROM core.investment_fixed_history ifh
    ) latest_price ON ifp.investment_fixed_products_id = latest_price.investment_fixed_products_id AND latest_price.rn = 1
WHERE 
    if_trans.investments_fixed_status = 'Efetuado'
GROUP BY 
    ua.user_accounts_user_id, u.users_first_name, u.users_last_name,
    ua.user_accounts_id, fi.financial_institutions_name,
    ifp.investment_fixed_products_id, ifp.investment_fixed_products_description,
    ifi.investment_fixed_issuers_name, ifi.investment_fixed_issuers_type,
    curr.currencies_iso, curr.currencies_name, curr.currencies_value,
    latest_price.investment_fixed_history_price
HAVING 
    SUM(CASE WHEN if_trans.investments_fixed_operation = 'Aplicação' THEN if_trans.investments_fixed_quantity ELSE -if_trans.investments_fixed_quantity END) > 0;

ALTER VIEW transactions.view_fixed_income_positions_by_account OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_fixed_income_positions_by_account IS 'Posições ativas de renda fixa por usuário, tipo de mercado e conta bancária.';

-- View 3: Posições ativas de renda variável por usuário e tipo de mercado
CREATE OR REPLACE VIEW transactions.view_variable_income_positions_by_user AS
SELECT 
    ua.user_accounts_user_id,
    u.users_first_name,
    u.users_last_name,
    iva.investment_variable_assets_id,
    iva.investment_variable_assets_name,
    ivt.investment_variable_types_name,
    ise.investment_stock_exchanges_name,
    ise.investment_stock_exchanges_type,
    curr.currencies_iso,
    curr.currencies_name,
    SUM(CASE WHEN iv_trans.investments_variable_operation = 'Aplicação' THEN iv_trans.investments_variable_quantity ELSE -iv_trans.investments_variable_quantity END) AS net_quantity,
    COALESCE(latest_price.investment_variable_assets_history_price, 0) AS current_unit_price,
    (SUM(CASE WHEN iv_trans.investments_variable_operation = 'Aplicação' THEN iv_trans.investments_variable_quantity ELSE -iv_trans.investments_variable_quantity END) * COALESCE(latest_price.investment_variable_assets_history_price, 0)) AS current_market_value,
    (SUM(CASE WHEN iv_trans.investments_variable_operation = 'Aplicação' THEN iv_trans.investments_variable_quantity ELSE -iv_trans.investments_variable_quantity END) * COALESCE(latest_price.investment_variable_assets_history_price, 0)) * curr.currencies_value AS current_market_value_brl
FROM 
    transactions.investments_variable iv_trans
    JOIN core.investment_variable_assets iva ON iv_trans.investments_variable_asset_id = iva.investment_variable_assets_id
    JOIN core.investment_variable_types ivt ON iva.investment_variable_assets_type_id = ivt.investment_variable_types_id
    JOIN core.investment_stock_exchanges ise ON iva.investment_variable_assets_stock_exchange_id = ise.investment_stock_exchanges_id
    JOIN core.user_accounts ua ON iv_trans.investments_variable_user_accounts_id = ua.user_accounts_id
    JOIN core.users u ON ua.user_accounts_user_id = u.users_id
    JOIN core.currencies curr ON ise.investment_stock_exchanges_currency_id = curr.currencies_id
    LEFT JOIN (
        SELECT 
            ivah.investment_variable_assets_history_asset_id,
            ivah.investment_variable_assets_history_price,
            ROW_NUMBER() OVER (PARTITION BY ivah.investment_variable_assets_history_asset_id ORDER BY ivah.investment_variable_assets_history_date DESC) as rn
        FROM core.investment_variable_assets_history ivah
    ) latest_price ON iva.investment_variable_assets_id = latest_price.investment_variable_assets_history_asset_id AND latest_price.rn = 1
WHERE 
    iv_trans.investments_variable_status = 'Efetuado'
GROUP BY 
    ua.user_accounts_user_id, u.users_first_name, u.users_last_name,
    iva.investment_variable_assets_id, iva.investment_variable_assets_name,
    ivt.investment_variable_types_name, ise.investment_stock_exchanges_name, ise.investment_stock_exchanges_type,
    curr.currencies_iso, curr.currencies_name, curr.currencies_value,
    latest_price.investment_variable_assets_history_price
HAVING 
    SUM(CASE WHEN iv_trans.investments_variable_operation = 'Aplicação' THEN iv_trans.investments_variable_quantity ELSE -iv_trans.investments_variable_quantity END) > 0;

ALTER VIEW transactions.view_variable_income_positions_by_user OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_variable_income_positions_by_user IS 'Posições ativas de renda variável por usuário, separadas por tipo de mercado (Local/Internacional).';

-- View 4: Posições ativas de renda variável por usuário, tipo de mercado e conta
CREATE OR REPLACE VIEW transactions.view_variable_income_positions_by_account AS
SELECT 
    ua.user_accounts_user_id,
    u.users_first_name,
    u.users_last_name,
    ua.user_accounts_id,
    fi.financial_institutions_name,
    iva.investment_variable_assets_id,
    iva.investment_variable_assets_name,
    ivt.investment_variable_types_name,
    ise.investment_stock_exchanges_name,
    ise.investment_stock_exchanges_type,
    curr.currencies_iso,
    curr.currencies_name,
    SUM(CASE WHEN iv_trans.investments_variable_operation = 'Aplicação' THEN iv_trans.investments_variable_quantity ELSE -iv_trans.investments_variable_quantity END) AS net_quantity,
    COALESCE(latest_price.investment_variable_assets_history_price, 0) AS current_unit_price,
    (SUM(CASE WHEN iv_trans.investments_variable_operation = 'Aplicação' THEN iv_trans.investments_variable_quantity ELSE -iv_trans.investments_variable_quantity END) * COALESCE(latest_price.investment_variable_assets_history_price, 0)) AS current_market_value,
    (SUM(CASE WHEN iv_trans.investments_variable_operation = 'Aplicação' THEN iv_trans.investments_variable_quantity ELSE -iv_trans.investments_variable_quantity END) * COALESCE(latest_price.investment_variable_assets_history_price, 0)) * curr.currencies_value AS current_market_value_brl
FROM 
    transactions.investments_variable iv_trans
    JOIN core.investment_variable_assets iva ON iv_trans.investments_variable_asset_id = iva.investment_variable_assets_id
    JOIN core.investment_variable_types ivt ON iva.investment_variable_assets_type_id = ivt.investment_variable_types_id
    JOIN core.investment_stock_exchanges ise ON iva.investment_variable_assets_stock_exchange_id = ise.investment_stock_exchanges_id
    JOIN core.user_accounts ua ON iv_trans.investments_variable_user_accounts_id = ua.user_accounts_id
    JOIN core.users u ON ua.user_accounts_user_id = u.users_id
    JOIN core.institution_accounts ia ON ua.user_accounts_institution_account_id = ia.institution_accounts_id
    JOIN core.financial_institutions fi ON ia.institution_accounts_institution_id = fi.financial_institutions_id
    JOIN core.currencies curr ON ise.investment_stock_exchanges_currency_id = curr.currencies_id
    LEFT JOIN (
        SELECT 
            ivah.investment_variable_assets_history_asset_id,
            ivah.investment_variable_assets_history_price,
            ROW_NUMBER() OVER (PARTITION BY ivah.investment_variable_assets_history_asset_id ORDER BY ivah.investment_variable_assets_history_date DESC) as rn
        FROM core.investment_variable_assets_history ivah
    ) latest_price ON iva.investment_variable_assets_id = latest_price.investment_variable_assets_history_asset_id AND latest_price.rn = 1
WHERE 
    iv_trans.investments_variable_status = 'Efetuado'
GROUP BY 
    ua.user_accounts_user_id, u.users_first_name, u.users_last_name,
    ua.user_accounts_id, fi.financial_institutions_name,
    iva.investment_variable_assets_id, iva.investment_variable_assets_name,
    ivt.investment_variable_types_name, ise.investment_stock_exchanges_name, ise.investment_stock_exchanges_type,
    curr.currencies_iso, curr.currencies_name, curr.currencies_value,
    latest_price.investment_variable_assets_history_price
HAVING 
    SUM(CASE WHEN iv_trans.investments_variable_operation = 'Aplicação' THEN iv_trans.investments_variable_quantity ELSE -iv_trans.investments_variable_quantity END) > 0;

ALTER VIEW transactions.view_variable_income_positions_by_account OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_variable_income_positions_by_account IS 'Posições ativas de renda variável por usuário, tipo de mercado e conta bancária.';

-- View 5: Balances consolidados (Atualização da view existente para incluir investimentos)
CREATE OR REPLACE VIEW transactions.view_consolidated_balances_by_account AS
-- Saldos BRL em contas de movimentação (não custódia)
SELECT
    ua.user_accounts_id,
    ua.user_accounts_user_id,
    u.users_first_name,
    u.users_last_name,
    fi.financial_institutions_name || ' (Conta de Movimentação)' AS account_display_name,
    'BRL' AS currency_type,
    'Movimentação' AS account_category,
    SUM(
        CASE 
            WHEN tsv.transactions_saldo_values_operation = 'Crédito' THEN tsv.transactions_saldo_values_value
            ELSE -tsv.transactions_saldo_values_value
        END
    ) AS balance_amount,
    SUM(
        CASE 
            WHEN tsv.transactions_saldo_values_operation = 'Crédito' THEN tsv.transactions_saldo_values_value
            ELSE -tsv.transactions_saldo_values_value
        END
    ) AS balance_amount_brl
FROM
    transactions.transactions_saldo ts
    JOIN transactions.transactions_saldo_values tsv ON ts.transactions_saldo_id = tsv.transactions_saldo_values_transaction_id
    JOIN core.user_accounts ua ON ts.transactions_saldo_user_accounts_id = ua.user_accounts_id
    JOIN core.user_accounts_currencies uac ON ua.user_accounts_id = uac.user_accounts_currencies_user_account_id
    JOIN core.currencies curr ON uac.user_accounts_currencies_currency_id = curr.currencies_id
    JOIN core.users u ON ua.user_accounts_user_id = u.users_id
    JOIN core.institution_accounts ia ON ua.user_accounts_institution_account_id = ia.institution_accounts_id
    JOIN core.financial_institutions fi ON ia.institution_accounts_institution_id = fi.financial_institutions_id
    JOIN core.account_types at ON ia.institution_accounts_type_id = at.account_types_id
WHERE
    curr.currencies_iso = 'BRL'
    AND ts.transactions_saldo_status = 'Efetuado'
    AND at.account_types_name <> 'Conta de Custódia'
GROUP BY
    ua.user_accounts_id, ua.user_accounts_user_id,
    u.users_first_name, u.users_last_name,
    fi.financial_institutions_name

UNION ALL

-- Investimentos de renda fixa em contas de custódia
SELECT
    ua.user_accounts_id,
    ua.user_accounts_user_id,
    u.users_first_name,
    u.users_last_name,
    fi.financial_institutions_name || ' (Conta de Custódia)' AS account_display_name,
    curr.currencies_iso AS currency_type,
    'Investimento - Renda Fixa' AS account_category,
    SUM(net_positions.current_market_value) AS balance_amount,
    SUM(net_positions.current_market_value_brl) AS balance_amount_brl
FROM
    transactions.view_fixed_income_positions_by_account net_positions
    JOIN core.user_accounts ua ON net_positions.user_accounts_id = ua.user_accounts_id
    JOIN core.users u ON ua.user_accounts_user_id = u.users_id
    JOIN core.institution_accounts ia ON ua.user_accounts_institution_account_id = ia.institution_accounts_id
    JOIN core.financial_institutions fi ON ia.institution_accounts_institution_id = fi.financial_institutions_id
    JOIN core.currencies curr ON net_positions.currencies_iso = curr.currencies_iso
GROUP BY
    ua.user_accounts_id, ua.user_accounts_user_id,
    u.users_first_name, u.users_last_name,
    fi.financial_institutions_name, curr.currencies_iso

UNION ALL

-- Investimentos de renda variável em contas de custódia
SELECT
    ua.user_accounts_id,
    ua.user_accounts_user_id,
    u.users_first_name,
    u.users_last_name,
    fi.financial_institutions_name || ' (Conta de Custódia)' AS account_display_name,
    curr.currencies_iso AS currency_type,
    'Investimento - Renda Variável' AS account_category,
    SUM(net_positions.current_market_value) AS balance_amount,
    SUM(net_positions.current_market_value_brl) AS balance_amount_brl
FROM
    transactions.view_variable_income_positions_by_account net_positions
    JOIN core.user_accounts ua ON net_positions.user_accounts_id = ua.user_accounts_id
    JOIN core.users u ON ua.user_accounts_user_id = u.users_id
    JOIN core.institution_accounts ia ON ua.user_accounts_institution_account_id = ia.institution_accounts_id
    JOIN core.financial_institutions fi ON ia.institution_accounts_institution_id = fi.financial_institutions_id
    JOIN core.currencies curr ON net_positions.currencies_iso = curr.currencies_iso
GROUP BY
    ua.user_accounts_id, ua.user_accounts_user_id,
    u.users_first_name, u.users_last_name,
    fi.financial_institutions_name, curr.currencies_iso;

ALTER VIEW transactions.view_consolidated_balances_by_account OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_consolidated_balances_by_account IS 'Balances consolidados incluindo contas de movimentação (saldos BRL) e contas de custódia (investimentos), separadas por categoria e tipo de conta.';

COMMIT;

-- Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE '=== EXTENSÃO DE INVESTIMENTOS EXECUTADA COM SUCESSO ===';
    RAISE NOTICE 'Módulo de investimentos criado e configurado.';
    RAISE NOTICE 'Tabelas: investment_indexes, investment_fixed_issuers, investment_fixed_products, etc.';
    RAISE NOTICE 'Views: posições ativas de renda fixa e variável, balances consolidados.';
    RAISE NOTICE 'Triggers: validação de contas de custódia e auditoria.';
    RAISE NOTICE '========================================================';
END $$;

-- =========================================================
-- FUNÇÕES DE VALIDAÇÃO DE OPERAÇÃO X CATEGORIA/PROCEDIMENTO
-- =========================================================

CREATE OR REPLACE FUNCTION transactions.validate_operation_category_procedure()
RETURNS TRIGGER AS $$
DECLARE
    v_cat_credit BOOLEAN;
    v_cat_debit BOOLEAN;
    v_proc_credit BOOLEAN;
    v_proc_debit BOOLEAN;
BEGIN
    -- Buscar flags da categoria
    SELECT categories_credit, categories_debit
      INTO v_cat_credit, v_cat_debit
      FROM core.categories
     WHERE categories_id = COALESCE(NEW.transactions_saldo_category_id, NEW.recurrence_saldo_category_id);

    -- Buscar flags do procedimento
    SELECT proceedings_credit, proceedings_debit
      INTO v_proc_credit, v_proc_debit
      FROM core.proceedings_saldo
     WHERE proceedings_id = COALESCE(NEW.transactions_saldo_proceeding_id, NEW.recurrence_saldo_proceeding_id);

    -- Validação categoria x operação
    IF (NEW.transactions_saldo_operation = 'Crédito' OR NEW.recurrence_saldo_operation = 'Crédito') AND NOT v_cat_credit THEN
        RAISE EXCEPTION 'Categoria não permite operação de Crédito.';
    ELSIF (NEW.transactions_saldo_operation = 'Débito' OR NEW.recurrence_saldo_operation = 'Débito') AND NOT v_cat_debit THEN
        RAISE EXCEPTION 'Categoria não permite operação de Débito.';
    END IF;

    -- Validação procedimento x operação
    IF (NEW.transactions_saldo_operation = 'Crédito' OR NEW.recurrence_saldo_operation = 'Crédito') AND NOT v_proc_credit THEN
        RAISE EXCEPTION 'Procedimento não permite operação de Crédito.';
    ELSIF (NEW.transactions_saldo_operation = 'Débito' OR NEW.recurrence_saldo_operation = 'Débito') AND NOT v_proc_debit THEN
        RAISE EXCEPTION 'Procedimento não permite operação de Débito.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===========================================
-- TRIGGERS DE VALIDAÇÃO
-- ===========================================

-- Para transações de saldo
CREATE TRIGGER trg_validate_operation_category_procedure_trans
BEFORE INSERT OR UPDATE ON transactions.transactions_saldo
FOR EACH ROW
EXECUTE FUNCTION transactions.validate_operation_category_procedure();

-- Para recorrências de saldo
CREATE TRIGGER trg_validate_operation_category_procedure_recur
BEFORE INSERT OR UPDATE ON transactions.recurrence_saldo
FOR EACH ROW
EXECUTE FUNCTION transactions.validate_operation_category_procedure();

-- ===========================================
-- FUNÇÃO DE VALIDAÇÃO PARA CARTÃO DE CRÉDITO
-- ===========================================

CREATE OR REPLACE FUNCTION transactions.validate_creditcard_operation_category()
RETURNS TRIGGER AS $$
DECLARE
    v_cat_credit BOOLEAN;
    v_cat_debit BOOLEAN;
    v_procedure TEXT;
BEGIN
    -- Descobre o procedimento (Crédito em Fatura ou Débito em Fatura)
    v_procedure := COALESCE(NEW.creditcard_transactions_procedure, NEW.creditcard_recurrence_procedure);

    -- Busca flags da categoria
    SELECT categories_credit, categories_debit
      INTO v_cat_credit, v_cat_debit
      FROM core.categories
     WHERE categories_id = COALESCE(NEW.creditcard_transactions_category_id, NEW.creditcard_recurrence_category_id);

    -- Validação categoria x procedimento
    IF v_procedure = 'Crédito em Fatura' AND NOT v_cat_credit THEN
        RAISE EXCEPTION 'Categoria não permite operação de Crédito em Fatura.';
    ELSIF v_procedure = 'Débito em Fatura' AND NOT v_cat_debit THEN
        RAISE EXCEPTION 'Categoria não permite operação de Débito em Fatura.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===========================================
-- TRIGGERS DE VALIDAÇÃO PARA CARTÃO DE CRÉDITO
-- ===========================================

-- Para transações de cartão de crédito
CREATE TRIGGER trg_validate_creditcard_operation_category_trans
BEFORE INSERT OR UPDATE ON transactions.creditcard_transactions
FOR EACH ROW
EXECUTE FUNCTION transactions.validate_creditcard_operation_category();

-- Para recorrências de cartão de crédito
CREATE TRIGGER trg_validate_creditcard_operation_category_recur
BEFORE INSERT OR UPDATE ON transactions.creditcard_recurrence
FOR EACH ROW
EXECUTE FUNCTION transactions.validate_creditcard_operation_category();

-- View: Extrato Unificado de Saldo e Cartão de Crédito (apenas tipo de conta e ID original)
CREATE OR REPLACE VIEW transactions.view_unified_statement_ids AS
SELECT
    'SALDO' AS tipo_conta,
    ts.transactions_saldo_id AS id_original
FROM
    transactions.transactions_saldo ts

UNION ALL

SELECT
    'CARTAO_CREDITO' AS tipo_conta,
    cct.creditcard_transactions_id AS id_original
FROM
    transactions.creditcard_transactions cct

UNION ALL

SELECT
    'CARTAO_CREDITO' AS tipo_conta,
    cci.creditcard_installments_id AS id_original
FROM
    transactions.creditcard_installments cci;

ALTER VIEW transactions.view_unified_statement_ids OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_unified_statement_ids IS 'Extrato unificado de IDs de transações de saldo e cartão de crédito, discriminando apenas o tipo de conta e o ID original.';

-- Remoção dos campos de valores da tabela original
ALTER TABLE transactions.currencies_transfers
    DROP COLUMN currencies_transfers_total_origin,
    DROP COLUMN currencies_transfers_total_destination,
    DROP COLUMN currencies_transfers_base_value_origin,
    DROP COLUMN currencies_transfers_fees_taxes_origin,
    DROP COLUMN currencies_transfers_exchange_rate_destination,
    DROP COLUMN currencies_transfers_additional_fees_destination;
    

-- Criação da tabela auxiliar para armazenar valores
CREATE TABLE transactions.currencies_transfers_values (
    currencies_transfers_values_id character varying(50) NOT NULL,
    currencies_transfers_values_transfer_id character varying(50) NOT NULL,
    currencies_transfers_values_base_value_origin numeric(15, 2) NOT NULL,
    currencies_transfers_values_fees_taxes_origin numeric(15, 2) NOT NULL DEFAULT 0,
    currencies_transfers_values_exchange_rate_destination numeric(15, 6) NOT NULL DEFAULT 1.0,
    currencies_transfers_values_additional_fees_destination numeric(15, 2) NOT NULL DEFAULT 0,
    currencies_transfers_values_total_origin numeric(15, 2) GENERATED ALWAYS AS (currencies_transfers_values_base_value_origin + currencies_transfers_values_fees_taxes_origin) STORED,
    currencies_transfers_values_total_destination numeric(15, 2) GENERATED ALWAYS AS ((currencies_transfers_values_base_value_origin - currencies_transfers_values_fees_taxes_origin) * currencies_transfers_values_exchange_rate_destination - currencies_transfers_values_additional_fees_destination) STORED,
    CONSTRAINT currencies_transfers_values_pkey PRIMARY KEY (currencies_transfers_values_id),
    CONSTRAINT fk_currencies_transfers_values_transfer 
        FOREIGN KEY (currencies_transfers_values_transfer_id) 
        REFERENCES transactions.currencies_transfers(currencies_transfers_id) 
        ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT chk_ct_positive_values CHECK (currencies_transfers_values_base_value_origin > 0 
        AND currencies_transfers_values_fees_taxes_origin >= 0 
        AND currencies_transfers_values_additional_fees_destination >= 0),
    CONSTRAINT chk_ct_positive_exchange_rate CHECK (currencies_transfers_values_exchange_rate_destination > 0)
);

-- Comentários da tabela
COMMENT ON TABLE transactions.currencies_transfers_values IS 'Armazena valores monetários associados às transferências de câmbio.';
COMMENT ON COLUMN transactions.currencies_transfers_values.currencies_transfers_values_id IS 'Identificador único do registro de valor (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.currencies_transfers_values.currencies_transfers_values_transfer_id IS 'Referência à transferência de câmbio (FK para currencies_transfers).';
COMMENT ON COLUMN transactions.currencies_transfers_values.currencies_transfers_values_base_value_origin IS 'Valor base na moeda de origem.';
COMMENT ON COLUMN transactions.currencies_transfers_values.currencies_transfers_values_fees_taxes_origin IS 'Taxas e impostos na moeda de origem.';
COMMENT ON COLUMN transactions.currencies_transfers_values.currencies_transfers_values_exchange_rate_destination IS 'Taxa de câmbio para conversão.';
COMMENT ON COLUMN transactions.currencies_transfers_values.currencies_transfers_values_additional_fees_destination IS 'Taxas adicionais na moeda de destino.';
COMMENT ON COLUMN transactions.currencies_transfers_values.currencies_transfers_values_total_origin IS 'Valor total debitado da origem (base + taxas origem).';
COMMENT ON COLUMN transactions.currencies_transfers_values.currencies_transfers_values_total_destination IS 'Valor total creditado no destino ((base - taxas origem) * taxa - taxas destino).';

-- Definir owner da tabela
ALTER TABLE transactions.currencies_transfers_values OWNER TO "SisFinance-adm";

-- Trigger para imutabilidade da PK
CREATE TRIGGER trigger_prevent_currencies_transfers_values_pk_update
BEFORE UPDATE ON transactions.currencies_transfers_values
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('currencies_transfers_values_id');

-- Trigger para auditoria
CREATE TRIGGER trigger_audit_currencies_transfers_values
AFTER INSERT OR UPDATE OR DELETE ON transactions.currencies_transfers_values
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('currencies_transfers_values_id');

-- Remoção dos campos de valores da tabela original
ALTER TABLE transactions.foreign_currency_transactions
    DROP COLUMN foreign_currency_transactions_subtotal,
    DROP COLUMN foreign_currency_transactions_total_effective,
    DROP COLUMN foreign_currency_transactions_base_value,
    DROP COLUMN foreign_currency_transactions_fees_taxes;
    

-- Criação da tabela auxiliar para armazenar valores
CREATE TABLE transactions.foreign_currency_transactions_values (
    foreign_currency_transactions_values_id character varying(50) NOT NULL,
    foreign_currency_transactions_values_transaction_id character varying(50) NOT NULL,
    foreign_currency_transactions_values_operation core.operation NOT NULL,
    foreign_currency_transactions_values_value numeric(15, 2) NOT NULL,
    CONSTRAINT foreign_currency_transactions_values_pkey PRIMARY KEY (foreign_currency_transactions_values_id),
    CONSTRAINT fk_foreign_currency_transactions_values_transaction
        FOREIGN KEY (foreign_currency_transactions_values_transaction_id)
        REFERENCES transactions.foreign_currency_transactions(foreign_currency_transactions_id)
        ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Comentários da tabela
COMMENT ON TABLE transactions.foreign_currency_transactions_values IS 'Armazena valores monetários associados às transações em moedas estrangeiras.';
COMMENT ON COLUMN transactions.foreign_currency_transactions_values.foreign_currency_transactions_values_id IS 'Identificador único do registro de valor (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.foreign_currency_transactions_values.foreign_currency_transactions_values_transaction_id IS 'Referência à transação em moeda estrangeira (FK para foreign_currency_transactions).';
COMMENT ON COLUMN transactions.foreign_currency_transactions_values.foreign_currency_transactions_values_operation IS 'Tipo de operação financeira (Crédito ou Débito).';

-- Definir owner da tabela
ALTER TABLE transactions.foreign_currency_transactions_values OWNER TO "SisFinance-adm";

-- Trigger para imutabilidade da PK
CREATE TRIGGER trigger_prevent_foreign_currency_transactions_values_pk_update
BEFORE UPDATE ON transactions.foreign_currency_transactions_values
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('foreign_currency_transactions_values_id');

-- Trigger para auditoria
CREATE TRIGGER trigger_audit_foreign_currency_transactions_values
AFTER INSERT OR UPDATE OR DELETE ON transactions.foreign_currency_transactions_values
FOR EACH ROW EXECUTE FUNCTION public.log_transactions_audit('foreign_currency_transactions_values_id');

-- =============================================================================
-- VIEWS PARA SISTEMA DE CÂMBIO
-- =============================================================================

-- View para saldos por moeda (exceto BRL)
CREATE OR REPLACE VIEW transactions.view_foreign_currency_balances AS
SELECT 
    uac.user_accounts_currencies_user_account_id,
    u.users_id,
    curr.currencies_iso,
    curr.currencies_name,
    COALESCE(SUM(
        CASE 
            WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
            ELSE -fctv.foreign_currency_transactions_values_value
        END
    ), 0) AS foreign_balance,
    curr.currencies_value AS exchange_rate_to_brl,
    COALESCE(SUM(
        CASE 
            WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
            ELSE -fctv.foreign_currency_transactions_values_value
        END
    ), 0) * curr.currencies_value AS balance_in_brl
FROM 
    core.user_accounts_currencies uac
    JOIN core.user_accounts ua ON uac.user_accounts_currencies_user_account_id = ua.user_accounts_id
    JOIN core.users u ON ua.user_accounts_user_id = u.users_id
    JOIN core.currencies curr ON uac.user_accounts_currencies_currency_id = curr.currencies_id
    LEFT JOIN transactions.foreign_currency_transactions fct ON uac.user_accounts_currencies_id = fct.foreign_currency_transactions_user_account_currency_id
    LEFT JOIN transactions.foreign_currency_transactions_values fctv ON fct.foreign_currency_transactions_id = fctv.foreign_currency_transactions_values_transaction_id
WHERE curr.currencies_id != '1' -- Excluir BRL
GROUP BY 
    uac.user_accounts_currencies_user_account_id, u.users_id, curr.currencies_iso, 
    curr.currencies_name, curr.currencies_value;

ALTER VIEW transactions.view_foreign_currency_balances OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_foreign_currency_balances IS 'Exibe saldos consolidados por moeda estrangeira para cada usuário, com conversão para BRL.';

-- =============================================================================
-- VIEWS PARA TRANSAÇÕES EM MOEDAS ESTRANGEIRAS POR PERÍODO
-- =============================================================================

-- View para transações em moedas estrangeiras do mês corrente
CREATE OR REPLACE VIEW transactions.view_foreign_currency_current_month AS
SELECT 
    fct.foreign_currency_transactions_id,
    fct.foreign_currency_transactions_user_account_currency_id,
    ua.user_accounts_user_id,
    curr.currencies_iso,
    curr.currencies_name,
    fctv.foreign_currency_transactions_values_operation,
    fct.foreign_currency_transactions_category_id,
    cat.categories_name,
    fct.foreign_currency_transactions_description_id,
    fct.foreign_currency_transactions_implementation_datetime,
    CASE 
        WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
        ELSE -fctv.foreign_currency_transactions_values_value
    END AS total_effective,
    curr.currencies_value AS exchange_rate_to_brl,
    CASE 
        WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
        ELSE -fctv.foreign_currency_transactions_values_value
    END * curr.currencies_value AS amount_in_brl
FROM 
    transactions.foreign_currency_transactions fct
    JOIN transactions.foreign_currency_transactions_values fctv ON fct.foreign_currency_transactions_id = fctv.foreign_currency_transactions_values_transaction_id
    JOIN core.user_accounts_currencies uac ON fct.foreign_currency_transactions_user_account_currency_id = uac.user_accounts_currencies_id
    JOIN core.user_accounts ua ON uac.user_accounts_currencies_user_account_id = ua.user_accounts_id
    JOIN core.currencies curr ON uac.user_accounts_currencies_currency_id = curr.currencies_id
    JOIN core.categories cat ON fct.foreign_currency_transactions_category_id = cat.categories_id
WHERE 
    fct.foreign_currency_transactions_implementation_datetime >= DATE_TRUNC('month', CURRENT_DATE)
    AND fct.foreign_currency_transactions_implementation_datetime < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month';

ALTER VIEW transactions.view_foreign_currency_current_month OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_foreign_currency_current_month IS 'Transações em moedas estrangeiras do 1º dia do mês corrente até o último dia do mês corrente.';

-- View para transações em moedas estrangeiras do mês subsequente
CREATE OR REPLACE VIEW transactions.view_foreign_currency_next_month AS
SELECT 
    fct.foreign_currency_transactions_id,
    fct.foreign_currency_transactions_user_account_currency_id,
    ua.user_accounts_user_id,
    curr.currencies_iso,
    curr.currencies_name,
    fctv.foreign_currency_transactions_values_operation,
    fct.foreign_currency_transactions_category_id,
    cat.categories_name,
    fct.foreign_currency_transactions_description_id,
    fct.foreign_currency_transactions_implementation_datetime,
    CASE 
        WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
        ELSE -fctv.foreign_currency_transactions_values_value
    END AS total_effective,
    curr.currencies_value AS exchange_rate_to_brl,
    CASE 
        WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
        ELSE -fctv.foreign_currency_transactions_values_value
    END * curr.currencies_value AS amount_in_brl
FROM 
    transactions.foreign_currency_transactions fct
    JOIN transactions.foreign_currency_transactions_values fctv ON fct.foreign_currency_transactions_id = fctv.foreign_currency_transactions_values_transaction_id
    JOIN core.user_accounts_currencies uac ON fct.foreign_currency_transactions_user_account_currency_id = uac.user_accounts_currencies_id
    JOIN core.user_accounts ua ON uac.user_accounts_currencies_user_account_id = ua.user_accounts_id
    JOIN core.currencies curr ON uac.user_accounts_currencies_currency_id = curr.currencies_id
    JOIN core.categories cat ON fct.foreign_currency_transactions_category_id = cat.categories_id
WHERE 
    fct.foreign_currency_transactions_implementation_datetime >= DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    AND fct.foreign_currency_transactions_implementation_datetime < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 months';

ALTER VIEW transactions.view_foreign_currency_next_month OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_foreign_currency_next_month IS 'Transações em moedas estrangeiras do mês subsequente ao mês corrente.';

-- View para transações em moedas estrangeiras do ano corrente
CREATE OR REPLACE VIEW transactions.view_foreign_currency_current_year AS
SELECT 
    fct.foreign_currency_transactions_id,
    fct.foreign_currency_transactions_user_account_currency_id,
    ua.user_accounts_user_id,
    curr.currencies_iso,
    curr.currencies_name,
    fctv.foreign_currency_transactions_values_operation,
    fct.foreign_currency_transactions_category_id,
    cat.categories_name,
    fct.foreign_currency_transactions_description_id,
    fct.foreign_currency_transactions_implementation_datetime,
    CASE 
        WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
        ELSE -fctv.foreign_currency_transactions_values_value
    END AS total_effective,
    curr.currencies_value AS exchange_rate_to_brl,
    CASE 
        WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
        ELSE -fctv.foreign_currency_transactions_values_value
    END * curr.currencies_value AS amount_in_brl
FROM 
    transactions.foreign_currency_transactions fct
    JOIN transactions.foreign_currency_transactions_values fctv ON fct.foreign_currency_transactions_id = fctv.foreign_currency_transactions_values_transaction_id
    JOIN core.user_accounts_currencies uac ON fct.foreign_currency_transactions_user_account_currency_id = uac.user_accounts_currencies_id
    JOIN core.user_accounts ua ON uac.user_accounts_currencies_user_account_id = ua.user_accounts_id
    JOIN core.currencies curr ON uac.user_accounts_currencies_currency_id = curr.currencies_id
    JOIN core.categories cat ON fct.foreign_currency_transactions_category_id = cat.categories_id
WHERE 
    EXTRACT(YEAR FROM fct.foreign_currency_transactions_implementation_datetime) = EXTRACT(YEAR FROM CURRENT_DATE);

ALTER VIEW transactions.view_foreign_currency_current_year OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_foreign_currency_current_year IS 'Transações em moedas estrangeiras do ano corrente (janeiro a dezembro).';

-- =============================================================================
-- VIEWS PARA TRANSAÇÕES EM MOEDAS ESTRANGEIRAS POR CATEGORIA E PERÍODO
-- =============================================================================

-- View para transações em moedas estrangeiras por categoria do mês corrente
CREATE OR REPLACE VIEW transactions.view_foreign_currency_by_category_current_month AS
SELECT 
    ua.user_accounts_user_id,
    curr.currencies_iso,
    curr.currencies_name,
    cat.categories_id,
    cat.categories_name,
    COUNT(*) AS transaction_count,
    SUM(
        CASE 
            WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
            ELSE -fctv.foreign_currency_transactions_values_value
        END
    ) AS total_amount,
    SUM(
        CASE 
            WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
            ELSE -fctv.foreign_currency_transactions_values_value
        END
        * curr.currencies_value
    ) AS total_amount_in_brl
FROM 
    transactions.foreign_currency_transactions fct
    JOIN transactions.foreign_currency_transactions_values fctv ON fct.foreign_currency_transactions_id = fctv.foreign_currency_transactions_values_transaction_id
    JOIN core.user_accounts_currencies uac ON fct.foreign_currency_transactions_user_account_currency_id = uac.user_accounts_currencies_id
    JOIN core.user_accounts ua ON uac.user_accounts_currencies_user_account_id = ua.user_accounts_id
    JOIN core.currencies curr ON uac.user_accounts_currencies_currency_id = curr.currencies_id
    JOIN core.categories cat ON fct.foreign_currency_transactions_category_id = cat.categories_id
WHERE 
    fct.foreign_currency_transactions_implementation_datetime >= DATE_TRUNC('month', CURRENT_DATE)
    AND fct.foreign_currency_transactions_implementation_datetime < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
GROUP BY 
    ua.user_accounts_user_id, curr.currencies_iso, curr.currencies_name, 
    cat.categories_id, cat.categories_name, curr.currencies_value;

ALTER VIEW transactions.view_foreign_currency_by_category_current_month OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_foreign_currency_by_category_current_month IS 'Transações em moedas estrangeiras agrupadas por categoria no mês corrente.';

-- View para transações em moedas estrangeiras por categoria do mês subsequente
-- View para transações em moedas estrangeiras por categoria do mês subsequente
CREATE OR REPLACE VIEW transactions.view_foreign_currency_by_category_next_month AS
SELECT 
    ua.user_accounts_user_id,
    curr.currencies_iso,
    curr.currencies_name,
    cat.categories_id,
    cat.categories_name,
    COUNT(*) AS transaction_count,
    SUM(
        CASE 
            WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
            ELSE -fctv.foreign_currency_transactions_values_value
        END
    ) AS total_amount,
    SUM(
        CASE 
            WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
            ELSE -fctv.foreign_currency_transactions_values_value
        END
        * curr.currencies_value
    ) AS total_amount_in_brl
FROM 
    transactions.foreign_currency_transactions fct
    JOIN transactions.foreign_currency_transactions_values fctv ON fct.foreign_currency_transactions_id = fctv.foreign_currency_transactions_values_transaction_id
    JOIN core.user_accounts_currencies uac ON fct.foreign_currency_transactions_user_account_currency_id = uac.user_accounts_currencies_id
    JOIN core.user_accounts ua ON uac.user_accounts_currencies_user_account_id = ua.user_accounts_id
    JOIN core.currencies curr ON uac.user_accounts_currencies_currency_id = curr.currencies_id
    JOIN core.categories cat ON fct.foreign_currency_transactions_category_id = cat.categories_id
WHERE 
    fct.foreign_currency_transactions_implementation_datetime >= DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    AND fct.foreign_currency_transactions_implementation_datetime < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 months'
GROUP BY 
    ua.user_accounts_user_id, curr.currencies_iso, curr.currencies_name, 
    cat.categories_id, cat.categories_name, curr.currencies_value;

ALTER VIEW transactions.view_foreign_currency_by_category_next_month OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_foreign_currency_by_category_next_month IS 'Transações em moedas estrangeiras agrupadas por categoria no mês subsequente.';

-- View para transações em moedas estrangeiras por categoria do ano corrente
CREATE OR REPLACE VIEW transactions.view_foreign_currency_by_category_current_year AS
SELECT 
    ua.user_accounts_user_id,
    curr.currencies_iso,
    curr.currencies_name,
    cat.categories_id,
    cat.categories_name,
    COUNT(*) AS transaction_count,
    SUM(
        CASE 
            WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
            ELSE -fctv.foreign_currency_transactions_values_value
        END
    ) AS total_amount,
    SUM(
        CASE 
            WHEN fctv.foreign_currency_transactions_values_operation = 'Crédito' THEN fctv.foreign_currency_transactions_values_value
            ELSE -fctv.foreign_currency_transactions_values_value
        END
        * curr.currencies_value
    ) AS total_amount_in_brl
FROM 
    transactions.foreign_currency_transactions fct
    JOIN transactions.foreign_currency_transactions_values fctv ON fct.foreign_currency_transactions_id = fctv.foreign_currency_transactions_values_transaction_id
    JOIN core.user_accounts_currencies uac ON fct.foreign_currency_transactions_user_account_currency_id = uac.user_accounts_currencies_id
    JOIN core.user_accounts ua ON uac.user_accounts_currencies_user_account_id = ua.user_accounts_id
    JOIN core.currencies curr ON uac.user_accounts_currencies_currency_id = curr.currencies_id
    JOIN core.categories cat ON fct.foreign_currency_transactions_category_id = cat.categories_id
WHERE 
    EXTRACT(YEAR FROM fct.foreign_currency_transactions_implementation_datetime) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 
    ua.user_accounts_user_id, curr.currencies_iso, curr.currencies_name, 
    cat.categories_id, cat.categories_name, curr.currencies_value;

ALTER VIEW transactions.view_foreign_currency_by_category_current_year OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_foreign_currency_by_category_current_year IS 'Transações em moedas estrangeiras agrupadas por categoria no ano corrente.';

-- =============================================================================
-- VIEWS CONSOLIDADAS (CARTÃO DE CRÉDITO + SALDO) POR PERÍODO
-- =============================================================================

-- View consolidada para transações do mês corrente
CREATE OR REPLACE VIEW transactions.view_consolidated_current_month AS
-- Transações de saldo
SELECT 
    'SALDO' AS transaction_source,
    ts.transactions_saldo_id AS transaction_id,
    ua.user_accounts_user_id,
    tsv.transactions_saldo_values_operation AS operation,
    ts.transactions_saldo_category_id AS category_id,
    cat.categories_name,
    ps.proceedings_name AS proceeding_name,
    ts.transactions_saldo_description AS description,
    ts.transactions_saldo_implementation_datetime AS reference_date,
    CASE 
        WHEN tsv.transactions_saldo_values_operation = 'Crédito' THEN tsv.transactions_saldo_values_value
        ELSE -tsv.transactions_saldo_values_value
    END AS amount,
    'BRL' AS currency
FROM 
    transactions.transactions_saldo ts
    JOIN transactions.transactions_saldo_values tsv ON ts.transactions_saldo_id = tsv.transactions_saldo_values_transaction_id
    JOIN core.user_accounts ua ON ts.transactions_saldo_user_accounts_id = ua.user_accounts_id
    JOIN core.categories cat ON ts.transactions_saldo_category_id = cat.categories_id
    JOIN core.proceedings_saldo ps ON ts.transactions_saldo_proceeding_id = ps.proceedings_id
WHERE 
    ts.transactions_saldo_implementation_datetime >= DATE_TRUNC('month', CURRENT_DATE)
    AND ts.transactions_saldo_implementation_datetime < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    AND ts.transactions_saldo_status = 'Efetuado'

UNION ALL

-- Transações de cartão não parceladas
SELECT 
    'CARTAO_NAO_PARCELADO' AS transaction_source,
    cct.creditcard_transactions_id AS transaction_id,
    uc.user_creditcard_user_id AS user_accounts_user_id,
    CASE 
        WHEN cctv.creditcard_transactions_values_procedure = 'Crédito em Fatura' THEN 'Crédito'::core.operation 
        ELSE 'Débito'::core.operation 
    END AS operation,
    cct.creditcard_transactions_category_id AS category_id,
    cat.categories_name,
    NULL AS proceeding_name,
    cct.creditcard_transactions_description AS description,
    cct.creditcard_transactions_implementation_datetime AS reference_date,
    CASE 
        WHEN cctv.creditcard_transactions_values_procedure = 'Crédito em Fatura' THEN cctv.creditcard_transactions_values_value
        ELSE -cctv.creditcard_transactions_values_value
    END AS amount,
    'BRL' AS currency
FROM 
    transactions.creditcard_transactions cct
    JOIN transactions.creditcard_transactions_values cctv ON cct.creditcard_transactions_id = cctv.creditcard_transactions_values_transaction_id
    JOIN transactions.creditcard_invoices ci ON cct.creditcard_transactions_invoice_id = ci.creditcard_invoices_id
    JOIN core.user_creditcard uc ON ci.creditcard_invoices_user_creditcard_id = uc.user_creditcard_id
    JOIN core.categories cat ON cct.creditcard_transactions_category_id = cat.categories_id
WHERE 
    cct.creditcard_transactions_implementation_datetime >= DATE_TRUNC('month', CURRENT_DATE)
    AND cct.creditcard_transactions_implementation_datetime < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    AND cct.creditcard_transactions_status = 'Efetuado'
    AND cct.creditcard_transactions_is_installment = FALSE

UNION ALL

-- Transações de cartão parceladas (baseado na data de vencimento da fatura)
SELECT 
    'CARTAO_PARCELADO' AS transaction_source,
    cci.creditcard_installments_id AS transaction_id,
    uc.user_creditcard_user_id AS user_accounts_user_id,
    'Débito'::core.operation AS operation,
    cct.creditcard_transactions_category_id AS category_id,
    cat.categories_name,
    NULL AS proceeding_name,
    cct.creditcard_transactions_description AS description,
    ci.creditcard_invoices_due_date AS reference_date,
    -cciv.creditcard_installments_values_value AS amount,
    'BRL' AS currency
FROM 
    transactions.creditcard_installments cci
    JOIN transactions.creditcard_installments_values cciv ON cci.creditcard_installments_id = cciv.creditcard_installments_values_installment_id
    JOIN transactions.creditcard_transactions cct ON cci.creditcard_installments_transaction_id = cct.creditcard_transactions_id
    JOIN transactions.creditcard_invoices ci ON cci.creditcard_installments_invoice_id = ci.creditcard_invoices_id
    JOIN core.user_creditcard uc ON ci.creditcard_invoices_user_creditcard_id = uc.user_creditcard_id
    JOIN core.categories cat ON cct.creditcard_transactions_category_id = cat.categories_id
WHERE 
    ci.creditcard_invoices_due_date >= DATE_TRUNC('month', CURRENT_DATE)
    AND ci.creditcard_invoices_due_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month';

ALTER VIEW transactions.view_consolidated_current_month OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_consolidated_current_month IS 'Transações consolidadas (saldo + cartão) do mês corrente, considerando datas de efetivação para saldo e cartão não parcelado, e data de vencimento da fatura para cartão parcelado.';

-- View consolidada para transações do mês subsequente
CREATE OR REPLACE VIEW transactions.view_consolidated_next_month AS
-- Transações de saldo
SELECT 
    'SALDO' AS transaction_source,
    ts.transactions_saldo_id AS transaction_id,
    ua.user_accounts_user_id,
    tsv.transactions_saldo_values_operation AS operation,
    ts.transactions_saldo_category_id AS category_id,
    cat.categories_name,
    ps.proceedings_name AS proceeding_name,
    ts.transactions_saldo_description AS description,
    ts.transactions_saldo_implementation_datetime AS reference_date,
    CASE 
        WHEN tsv.transactions_saldo_values_operation = 'Crédito' THEN tsv.transactions_saldo_values_value
        ELSE -tsv.transactions_saldo_values_value
    END AS amount,
    'BRL' AS currency
FROM 
    transactions.transactions_saldo ts
    JOIN transactions.transactions_saldo_values tsv ON ts.transactions_saldo_id = tsv.transactions_saldo_values_transaction_id
    JOIN core.user_accounts ua ON ts.transactions_saldo_user_accounts_id = ua.user_accounts_id
    JOIN core.categories cat ON ts.transactions_saldo_category_id = cat.categories_id
    JOIN core.proceedings_saldo ps ON ts.transactions_saldo_proceeding_id = ps.proceedings_id
WHERE 
    ts.transactions_saldo_implementation_datetime >= DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    AND ts.transactions_saldo_implementation_datetime < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 months'
    AND ts.transactions_saldo_status = 'Efetuado'

UNION ALL

-- Transações de cartão não parceladas
SELECT 
    'CARTAO_NAO_PARCELADO' AS transaction_source,
    cct.creditcard_transactions_id AS transaction_id,
    uc.user_creditcard_user_id AS user_accounts_user_id,
    CASE 
        WHEN cctv.creditcard_transactions_values_procedure = 'Crédito em Fatura' THEN 'Crédito'::core.operation 
        ELSE 'Débito'::core.operation 
    END AS operation,
    cct.creditcard_transactions_category_id AS category_id,
    cat.categories_name,
    NULL AS proceeding_name,
    cct.creditcard_transactions_description AS description,
    cct.creditcard_transactions_implementation_datetime AS reference_date,
    CASE 
        WHEN cctv.creditcard_transactions_values_procedure = 'Crédito em Fatura' THEN cctv.creditcard_transactions_values_value
        ELSE -cctv.creditcard_transactions_values_value
    END AS amount,
    'BRL' AS currency
FROM 
    transactions.creditcard_transactions cct
    JOIN transactions.creditcard_transactions_values cctv ON cct.creditcard_transactions_id = cctv.creditcard_transactions_values_transaction_id
    JOIN transactions.creditcard_invoices ci ON cct.creditcard_transactions_invoice_id = ci.creditcard_invoices_id
    JOIN core.user_creditcard uc ON ci.creditcard_invoices_user_creditcard_id = uc.user_creditcard_id
    JOIN core.categories cat ON cct.creditcard_transactions_category_id = cat.categories_id
WHERE 
    cct.creditcard_transactions_implementation_datetime >= DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    AND cct.creditcard_transactions_implementation_datetime < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 months'
    AND cct.creditcard_transactions_status = 'Efetuado'
    AND cct.creditcard_transactions_is_installment = FALSE

UNION ALL

-- Transações de cartão parceladas (baseado na data de vencimento da fatura)
SELECT 
    'CARTAO_PARCELADO' AS transaction_source,
    cci.creditcard_installments_id AS transaction_id,
    uc.user_creditcard_user_id AS user_accounts_user_id,
    'Débito'::core.operation AS operation,
    cct.creditcard_transactions_category_id AS category_id,
    cat.categories_name,
    NULL AS proceeding_name,
    cct.creditcard_transactions_description AS description,
    ci.creditcard_invoices_due_date AS reference_date,
    -cciv.creditcard_installments_values_value AS amount,
    'BRL' AS currency
FROM 
    transactions.creditcard_installments cci
    JOIN transactions.creditcard_installments_values cciv ON cci.creditcard_installments_id = cciv.creditcard_installments_values_installment_id
    JOIN transactions.creditcard_transactions cct ON cci.creditcard_installments_transaction_id = cct.creditcard_transactions_id
    JOIN transactions.creditcard_invoices ci ON cci.creditcard_installments_invoice_id = ci.creditcard_invoices_id
    JOIN core.user_creditcard uc ON ci.creditcard_invoices_user_creditcard_id = uc.user_creditcard_id
    JOIN core.categories cat ON cct.creditcard_transactions_category_id = cat.categories_id
WHERE 
    ci.creditcard_invoices_due_date >= DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    AND ci.creditcard_invoices_due_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 months';

ALTER VIEW transactions.view_consolidated_next_month OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_consolidated_next_month IS 'Transações consolidadas (saldo + cartão) do mês subsequente.';

-- View consolidada para transações do ano corrente
CREATE OR REPLACE VIEW transactions.view_consolidated_current_year AS
-- Transações de saldo
SELECT 
    'SALDO' AS transaction_source,
    ts.transactions_saldo_id AS transaction_id,
    ua.user_accounts_user_id,
    tsv.transactions_saldo_values_operation AS operation,
    ts.transactions_saldo_category_id AS category_id,
    cat.categories_name,
    ps.proceedings_name AS proceeding_name,
    ts.transactions_saldo_description AS description,
    ts.transactions_saldo_implementation_datetime AS reference_date,
    CASE 
        WHEN tsv.transactions_saldo_values_operation = 'Crédito' THEN tsv.transactions_saldo_values_value
        ELSE -tsv.transactions_saldo_values_value
    END AS amount,
    'BRL' AS currency
FROM 
    transactions.transactions_saldo ts
    JOIN transactions.transactions_saldo_values tsv ON ts.transactions_saldo_id = tsv.transactions_saldo_values_transaction_id
    JOIN core.user_accounts ua ON ts.transactions_saldo_user_accounts_id = ua.user_accounts_id
    JOIN core.categories cat ON ts.transactions_saldo_category_id = cat.categories_id
    JOIN core.proceedings_saldo ps ON ts.transactions_saldo_proceeding_id = ps.proceedings_id
WHERE 
    EXTRACT(YEAR FROM ts.transactions_saldo_implementation_datetime) = EXTRACT(YEAR FROM CURRENT_DATE)
    AND ts.transactions_saldo_status = 'Efetuado'

UNION ALL

-- Transações de cartão não parceladas
SELECT 
    'CARTAO_NAO_PARCELADO' AS transaction_source,
    cct.creditcard_transactions_id AS transaction_id,
    uc.user_creditcard_user_id AS user_accounts_user_id,
    CASE 
        WHEN cctv.creditcard_transactions_values_procedure = 'Crédito em Fatura' THEN 'Crédito'::core.operation 
        ELSE 'Débito'::core.operation 
    END AS operation,
    cct.creditcard_transactions_category_id AS category_id,
    cat.categories_name,
    NULL AS proceeding_name,
    cct.creditcard_transactions_description AS description,
    cct.creditcard_transactions_implementation_datetime AS reference_date,
    CASE 
        WHEN cctv.creditcard_transactions_values_procedure = 'Crédito em Fatura' THEN cctv.creditcard_transactions_values_value
        ELSE -cctv.creditcard_transactions_values_value
    END AS amount,
    'BRL' AS currency
FROM 
    transactions.creditcard_transactions cct
    JOIN transactions.creditcard_transactions_values cctv ON cct.creditcard_transactions_id = cctv.creditcard_transactions_values_transaction_id
    JOIN transactions.creditcard_invoices ci ON cct.creditcard_transactions_invoice_id = ci.creditcard_invoices_id
    JOIN core.user_creditcard uc ON ci.creditcard_invoices_user_creditcard_id = uc.user_creditcard_id
    JOIN core.categories cat ON cct.creditcard_transactions_category_id = cat.categories_id
WHERE 
    EXTRACT(YEAR FROM cct.creditcard_transactions_implementation_datetime) = EXTRACT(YEAR FROM CURRENT_DATE)
    AND cct.creditcard_transactions_status = 'Efetuado'
    AND cct.creditcard_transactions_is_installment = FALSE

UNION ALL

-- Transações de cartão parceladas (baseado na data de vencimento da fatura)
SELECT 
    'CARTAO_PARCELADO' AS transaction_source,
    cci.creditcard_installments_id AS transaction_id,
    uc.user_creditcard_user_id AS user_accounts_user_id,
    'Débito'::core.operation AS operation,
    cct.creditcard_transactions_category_id AS category_id,
    cat.categories_name,
    NULL AS proceeding_name,
    cct.creditcard_transactions_description AS description,
    ci.creditcard_invoices_due_date AS reference_date,
    -cciv.creditcard_installments_values_value AS amount,
    'BRL' AS currency
FROM 
    transactions.creditcard_installments cci
    JOIN transactions.creditcard_installments_values cciv ON cci.creditcard_installments_id = cciv.creditcard_installments_values_installment_id
    JOIN transactions.creditcard_transactions cct ON cci.creditcard_installments_transaction_id = cct.creditcard_transactions_id
    JOIN transactions.creditcard_invoices ci ON cci.creditcard_installments_invoice_id = ci.creditcard_invoices_id
    JOIN core.user_creditcard uc ON ci.creditcard_invoices_user_creditcard_id = uc.user_creditcard_id
    JOIN core.categories cat ON cct.creditcard_transactions_category_id = cat.categories_id
WHERE 
    EXTRACT(YEAR FROM ci.creditcard_invoices_due_date) = EXTRACT(YEAR FROM CURRENT_DATE);

ALTER VIEW transactions.view_consolidated_current_year OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_consolidated_current_year IS 'Transações consolidadas (saldo + cartão) do ano corrente.';

-- View: Saldo BRL por conta bancária (exceto Conta de Custódia)
CREATE OR REPLACE VIEW transactions.view_brl_balance_per_account AS
SELECT
    ua.user_accounts_id,
    ua.user_accounts_user_id,
    u.users_first_name,
    u.users_last_name,
    ua.user_accounts_institution_account_id,
    inst.financial_institutions_name,
    acc_type.account_types_name,
    SUM(
        CASE 
            WHEN tsv.transactions_saldo_values_operation = 'Crédito' THEN tsv.transactions_saldo_values_value
            ELSE -tsv.transactions_saldo_values_value
        END
    ) AS brl_balance
FROM
    transactions.transactions_saldo ts
    JOIN transactions.transactions_saldo_values tsv ON ts.transactions_saldo_id = tsv.transactions_saldo_values_transaction_id
    JOIN core.user_accounts ua ON ts.transactions_saldo_user_accounts_id = ua.user_accounts_id
    JOIN core.user_accounts_currencies uac ON ua.user_accounts_id = uac.user_accounts_currencies_user_account_id
    JOIN core.currencies curr ON uac.user_accounts_currencies_currency_id = curr.currencies_id
    JOIN core.users u ON ua.user_accounts_user_id = u.users_id
    JOIN core.institution_accounts ia ON ua.user_accounts_institution_account_id = ia.institution_accounts_id
    JOIN core.financial_institutions inst ON ia.institution_accounts_institution_id = inst.financial_institutions_id
    JOIN core.account_types acc_type ON ia.institution_accounts_type_id = acc_type.account_types_id
WHERE
    curr.currencies_iso = 'BRL'
    AND ts.transactions_saldo_status = 'Efetuado'
    AND acc_type.account_types_name <> 'Conta de Custódia'
GROUP BY
    ua.user_accounts_id,
    ua.user_accounts_user_id,
    u.users_first_name,
    u.users_last_name,
    ua.user_accounts_institution_account_id,
    inst.financial_institutions_name,
    acc_type.account_types_name;

ALTER VIEW transactions.view_brl_balance_per_account OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_brl_balance_per_account IS 'Balanço consolidado de saldo em BRL por conta bancária e usuário, exceto contas do tipo "Conta de Custódia".';