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

-- Configuração do search_path para incluir os 3 schemas e o schema public
ALTER DATABASE "SisFinance" SET search_path TO core, transactions, auditoria, public;

-- Garantir que o proprietário padrão tenha os privilégios necessários
ALTER SCHEMA core OWNER TO "SisFinance-adm";
ALTER SCHEMA transactions OWNER TO "SisFinance-adm";
ALTER SCHEMA auditoria OWNER TO "SisFinance-adm";

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
-- CRIAÇÃO ESPECÍFICA DA FUNÇÃO validate_email_format
-- =============================================================================

CREATE OR REPLACE FUNCTION public.validate_email_format(email_input TEXT)
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
    validate_email_format(users_email) IS NOT NULL
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

-- Tabela: recurrence_saldo
CREATE TABLE transactions.recurrence_saldo (
    recurrence_saldo_id character varying(50) NOT NULL,
    recurrence_saldo_user_account_id character varying(50) NOT NULL,
    recurrence_saldo_operation core.operation NOT NULL,
    recurrence_saldo_proceeding_id character varying(50) NOT NULL,
    recurrence_saldo_category_id character varying(50) NOT NULL,
    recurrence_saldo_operator_id character varying(50) NOT NULL,
    recurrence_saldo_status transactions.recurrence_status_ai NOT NULL DEFAULT 'Ativo',
    recurrence_saldo_description text,
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
COMMENT ON COLUMN transactions.recurrence_saldo.recurrence_saldo_description IS 'Descrição padrão para as transações geradas por esta recorrência (opcional).';
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
    CONSTRAINT fk_transactions_user_account FOREIGN KEY (transactions_saldo_user_accounts_id) REFERENCES core.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_proceeding FOREIGN KEY (transactions_saldo_proceeding_id) REFERENCES core.proceedings_saldo(proceedings_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_category FOREIGN KEY (transactions_saldo_category_id) REFERENCES core.categories(categories_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactions_operator FOREIGN KEY (transactions_saldo_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
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
COMMENT ON COLUMN transactions.transactions_saldo.transactions_saldo_description IS 'Descrição específica desta transação (opcional).';
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

-- Tabela: recurrence_creditcard
CREATE TABLE transactions.recurrence_creditcard (
    creditcard_recurrence_id character varying(50) NOT NULL,
    creditcard_recurrence_user_card_id character varying(50) NOT NULL,
    creditcard_recurrence_procedure transactions.creditcard_transaction_procedure NOT NULL DEFAULT 'Débito em Fatura',
    creditcard_recurrence_category_id character varying(50) NOT NULL,
    creditcard_recurrence_operator_id character varying(50) NOT NULL,
    creditcard_recurrence_status transactions.recurrence_status_ai NOT NULL DEFAULT 'Ativo',
    creditcard_recurrence_description text,
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
    CONSTRAINT chk_ccrecur_due_day_required CHECK (creditcard_recurrence_frequency = 'Semanal' OR creditcard_recurrence_due_day IS NOT NULL),
    CONSTRAINT chk_ccrecur_last_date_logic CHECK (creditcard_recurrence_last_due_date IS NULL OR creditcard_recurrence_last_due_date >= creditcard_recurrence_first_due_date),
    CONSTRAINT chk_ccrecur_determined_needs_last_date CHECK (creditcard_recurrence_type = 'Indeterminado' OR creditcard_recurrence_last_due_date IS NOT NULL)
);
ALTER TABLE transactions.recurrence_creditcard OWNER TO "SisFinance-adm";
COMMENT ON TABLE transactions.recurrence_creditcard IS 'Define transações recorrentes que ocorrem diretamente na fatura do cartão de crédito.';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_id IS 'Identificador único da recorrência de cartão (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_user_card_id IS 'Referência ao cartão específico do usuário afetado (FK para user_creditcard).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_procedure IS 'Procedimento a ser aplicado na fatura (Crédito ou Débito em Fatura).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_category_id IS 'Categoria da recorrência (FK para categories).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_operator_id IS 'Operador associado a esta recorrência (FK para operators).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_status IS 'Status atual da recorrência (Ativo ou Inativo).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_description IS 'Descrição para as transações geradas por esta recorrência (opcional).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_registration_datetime IS 'Data e hora de cadastro desta recorrência no sistema.';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_type IS 'Tipo de recorrência (Determinada ou Indeterminada).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_frequency IS 'Frequência com que a transação recorrente deve ocorrer.';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_due_day IS 'Dia do mês preferencial para lançamento (1-31), exceto para frequência Semanal.';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_first_due_date IS 'Data da primeira ocorrência desta recorrência.';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_last_due_date IS 'Data da última ocorrência (obrigatória para tipo Determinado).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_postpone_to_business_day IS 'Indica se a data, caso caia em dia não útil, deve ser adiada.';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_base_value IS 'Valor base da transação recorrente.';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_fees_taxes IS 'Taxas ou impostos adicionais relacionados. Padrão: 0.';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_subtotal IS 'Valor calculado: base_value + fees_taxes. Coluna Gerada.';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_total_effective IS 'Valor efetivo com sinal (positivo para crédito, negativo para débito).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_receipt_archive IS 'Caminho/ID para arquivo de comprovante modelo (opcional).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_receipt_image IS 'Caminho/ID para imagem de comprovante modelo (opcional).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_receipt_url IS 'URL externa para comprovante modelo (opcional).';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_relevance_ir IS 'Indica relevância para Imposto de Renda.';
COMMENT ON COLUMN transactions.recurrence_creditcard.creditcard_recurrence_last_update IS 'Timestamp da última atualização manual deste registro.';

-- Tabela: creditcard_transactions
CREATE TABLE transactions.creditcard_transactions (
    creditcard_transactions_id character varying(50) NOT NULL,
    creditcard_transactions_invoice_id character varying(50),
    creditcard_transactions_procedure transactions.creditcard_transaction_procedure NOT NULL DEFAULT 'Débito em Fatura',
    creditcard_transactions_status transactions.status NOT NULL,
    creditcard_transactions_category_id character varying(50) NOT NULL,
    creditcard_transactions_operator_id character varying(50) NOT NULL,
    creditcard_transactions_description text,
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
    CONSTRAINT fk_cctrans_recurrence FOREIGN KEY (creditcard_transactions_recurrence_id) REFERENCES transactions.recurrence_creditcard(creditcard_recurrence_id) ON DELETE SET NULL ON UPDATE NO ACTION,
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
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_description IS 'Descrição da transação (opcional).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_observations IS 'Observações adicionais sobre a transação (opcional).';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_registration_datetime IS 'Data e hora de registro da transação no sistema.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_is_recurrence IS 'Indica se foi gerada por uma recorrência. Padrão: FALSE.';
COMMENT ON COLUMN transactions.creditcard_transactions.creditcard_transactions_recurrence_id IS 'Recorrência que gerou esta transação, se aplicável (FK para recurrence_creditcard).';
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

-- Tabela: transaction_reports
CREATE TABLE transactions.transaction_reports (
    report_id character varying(50) NOT NULL,
    report_user_id character varying(50) NOT NULL,
    report_time_choice transactions.report_time_choice NOT NULL,
    report_type transactions.report_type NOT NULL,
    report_initial_month_launch transactions.month_enum NULL,
    report_initial_year_launch integer NULL CHECK (report_initial_year_launch IS NULL OR (report_initial_year_launch >= 2020 AND report_initial_year_launch <= 2099)),
    report_final_month_launch transactions.month_enum NULL,
    report_final_year_launch integer NULL CHECK (report_final_year_launch IS NULL OR (report_final_year_launch >= 2020 AND report_final_year_launch <= 2099)),
    report_initial_date date NULL,
    report_final_date date NULL,
    report_relative_period transactions.report_relative_period NULL,
    report_filter_by_account boolean NULL,
    report_account_id character varying(50) NULL,
    report_filter_by_creditcard boolean NULL,
    report_user_creditcard_id character varying(50) NULL,
    report_filter_by_operator boolean NOT NULL DEFAULT false,
    report_operator_id character varying(50) NULL,
    report_filter_by_description boolean NOT NULL DEFAULT false,
    report_description text NULL,
    report_filter_by_proceeding_saldo boolean NULL,
    report_proceeding_saldo_id character varying(50) NULL,
    report_filter_by_proceeding_creditcard boolean NULL,
    report_proceeding_creditcard transactions.creditcard_transaction_procedure NULL,
    report_filter_by_status boolean NOT NULL DEFAULT false,
    report_status transactions.status NULL,
    report_filter_by_recurrence_id boolean NOT NULL DEFAULT false,
    report_recurrence_id character varying(50) NULL,
    report_filter_by_category boolean NOT NULL DEFAULT false,
    report_category_id character varying(50) NULL,
    report_filter_by_ir_relevance boolean NOT NULL DEFAULT false,
    report_ir_relevance boolean NULL,
    report_filter_by_operation boolean NULL,
    report_operation core.operation NULL,
    report_filter_by_installments boolean NULL,
    report_installments boolean NULL,
    report_number_of_installments integer NULL CHECK (report_number_of_installments IS NULL OR (report_number_of_installments >= 1 AND report_number_of_installments <= 420)),
    report_send_to_operator_id character varying(50) NOT NULL,
    report_auto_generate boolean NOT NULL DEFAULT false,
    report_auto_frequency transactions.report_auto_frequency NULL,
    report_insights text NULL,
    report_generation_datetime timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    report_sent_datetime timestamp with time zone NULL,
    report_access_link text NULL,
    report_already_generated boolean NULL,
    report_recurring_status transactions.report_recurring_status NULL,
    CONSTRAINT transaction_reports_pkey PRIMARY KEY (report_id),
    CONSTRAINT fk_transactionreports_user FOREIGN KEY (report_user_id) REFERENCES core.users(users_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactionreports_acc FOREIGN KEY (report_account_id) REFERENCES core.user_accounts(user_accounts_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactionreports_cc FOREIGN KEY (report_user_creditcard_id) REFERENCES core.user_creditcard(user_creditcard_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactionreports_oper FOREIGN KEY (report_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactionreports_send_oper FOREIGN KEY (report_send_to_operator_id) REFERENCES core.operators(operators_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactionreports_procS FOREIGN KEY (report_proceeding_saldo_id) REFERENCES core.proceedings_saldo(proceedings_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_transactionreports_rec FOREIGN KEY (report_recurrence_id) REFERENCES transactions.recurrence_saldo(recurrence_saldo_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT fk_transactionreports_cat FOREIGN KEY (report_category_id) REFERENCES core.categories(categories_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT chk_time_choice_launch_fields CHECK ((report_time_choice = 'Por Lançamento' AND (report_initial_month_launch IS NOT NULL OR report_initial_year_launch IS NOT NULL OR report_final_month_launch IS NOT NULL OR report_final_year_launch IS NOT NULL)) OR (report_time_choice <> 'Por Lançamento' AND report_initial_month_launch IS NULL AND report_initial_year_launch IS NULL AND report_final_month_launch IS NULL AND report_final_year_launch IS NULL)),
    CONSTRAINT chk_time_choice_date_fields CHECK ((report_time_choice = 'Por Data' AND (report_initial_date IS NOT NULL OR report_final_date IS NOT NULL)) OR (report_time_choice <> 'Por Data' AND report_initial_date IS NULL AND report_final_date IS NULL)),
    CONSTRAINT chk_time_choice_period_field CHECK ((report_time_choice = 'Por Período' AND report_relative_period IS NOT NULL) OR (report_time_choice <> 'Por Período' AND report_relative_period IS NULL)),
    CONSTRAINT chk_account_filter_type CHECK ((report_type IN ('Saldo', 'Saldo e Cartão de Crédito') AND report_filter_by_account IS NOT NULL) OR (report_type = 'Cartão de Crédito' AND report_filter_by_account IS NULL)),
    CONSTRAINT chk_creditcard_filter_type CHECK ((report_type IN ('Cartão de Crédito', 'Saldo e Cartão de Crédito') AND report_filter_by_creditcard IS NOT NULL) OR (report_type = 'Saldo' AND report_filter_by_creditcard IS NULL)),
    CONSTRAINT chk_proceeding_saldo_type CHECK ((report_type IN ('Saldo', 'Saldo e Cartão de Crédito') AND report_filter_by_proceeding_saldo IS NOT NULL) OR (report_type = 'Cartão de Crédito' AND report_filter_by_proceeding_saldo IS NULL)),
    CONSTRAINT chk_proceeding_cc_type CHECK ((report_type IN ('Cartão de Crédito', 'Saldo e Cartão de Crédito') AND report_filter_by_proceeding_creditcard IS NOT NULL) OR (report_type = 'Saldo' AND report_filter_by_proceeding_creditcard IS NULL)),
    CONSTRAINT chk_operation_filter_type CHECK ((report_type IN ('Saldo', 'Saldo e Cartão de Crédito') AND report_filter_by_operation IS NOT NULL) OR (report_type = 'Cartão de Crédito' AND report_filter_by_operation IS NULL)),
    CONSTRAINT chk_installments_filter_type CHECK ((report_type IN ('Cartão de Crédito', 'Saldo e Cartão de Crédito') AND report_filter_by_installments IS NOT NULL) OR (report_type = 'Saldo' AND report_filter_by_installments IS NULL)),
    CONSTRAINT chk_account_conditional CHECK ((report_filter_by_account IS TRUE AND report_account_id IS NOT NULL) OR (report_filter_by_account IS NOT TRUE AND report_account_id IS NULL)),
    CONSTRAINT chk_creditcard_conditional CHECK ((report_filter_by_creditcard IS TRUE AND report_user_creditcard_id IS NOT NULL) OR (report_filter_by_creditcard IS NOT TRUE AND report_user_creditcard_id IS NULL)),
    CONSTRAINT chk_operator_conditional CHECK ((report_filter_by_operator IS TRUE AND report_operator_id IS NOT NULL) OR (report_filter_by_operator IS NOT TRUE AND report_operator_id IS NULL)),
    CONSTRAINT chk_description_conditional CHECK ((report_filter_by_description IS TRUE AND report_description IS NOT NULL) OR (report_filter_by_description IS NOT TRUE AND report_description IS NULL)),
    CONSTRAINT chk_proceeding_saldo_conditional CHECK ((report_filter_by_proceeding_saldo IS TRUE AND report_proceeding_saldo_id IS NOT NULL) OR (report_filter_by_proceeding_saldo IS NOT TRUE AND report_proceeding_saldo_id IS NULL)),
    CONSTRAINT chk_proceeding_cc_conditional CHECK ((report_filter_by_proceeding_creditcard IS TRUE AND report_proceeding_creditcard IS NOT NULL) OR (report_filter_by_proceeding_creditcard IS NOT TRUE AND report_proceeding_creditcard IS NULL)),
    CONSTRAINT chk_status_conditional CHECK ((report_filter_by_status IS TRUE AND report_status IS NOT NULL) OR (report_filter_by_status IS NOT TRUE AND report_status IS NULL)),
    CONSTRAINT chk_recurrence_conditional CHECK ((report_filter_by_recurrence_id IS TRUE AND report_recurrence_id IS NOT NULL) OR (report_filter_by_recurrence_id IS NOT TRUE AND report_recurrence_id IS NULL)),
    CONSTRAINT chk_category_conditional CHECK ((report_filter_by_category IS TRUE AND report_category_id IS NOT NULL) OR (report_filter_by_category IS NOT TRUE AND report_category_id IS NULL)),
    CONSTRAINT chk_ir_conditional CHECK ((report_filter_by_ir_relevance IS TRUE AND report_ir_relevance IS NOT NULL) OR (report_filter_by_ir_relevance IS NOT TRUE AND report_ir_relevance IS NULL)),
    CONSTRAINT chk_operation_conditional CHECK ((report_filter_by_operation IS TRUE AND report_operation IS NOT NULL) OR (report_filter_by_operation IS NOT TRUE AND report_operation IS NULL)),
    CONSTRAINT chk_installments_conditional CHECK ((report_filter_by_installments IS TRUE AND report_installments IS NOT NULL) OR (report_filter_by_installments IS NOT TRUE AND report_installments IS NULL)),
    CONSTRAINT chk_number_installments_conditional CHECK ((report_installments IS TRUE AND report_number_of_installments IS NOT NULL) OR (report_installments IS NOT TRUE AND report_number_of_installments IS NULL)),
    CONSTRAINT chk_auto_frequency_conditional CHECK ((report_auto_generate IS TRUE AND report_auto_frequency IS NOT NULL) OR (report_auto_generate IS NOT TRUE AND report_auto_frequency IS NULL)),
    CONSTRAINT chk_recurring_status_conditional CHECK ((report_auto_generate IS TRUE AND report_recurring_status IS NOT NULL) OR (report_auto_generate IS NOT TRUE AND report_recurring_status IS NULL)),
    CONSTRAINT chk_already_generated_conditional CHECK ((report_auto_generate IS TRUE) OR (report_auto_generate IS NOT TRUE AND report_already_generated IS NOT NULL)),
    CONSTRAINT chk_date_logic CHECK (report_initial_date IS NULL OR report_final_date IS NULL OR report_final_date >= report_initial_date),
    CONSTRAINT chk_year_logic CHECK (report_initial_year_launch IS NULL OR report_final_year_launch IS NULL OR report_final_year_launch >= report_initial_year_launch OR (report_final_year_launch = report_initial_year_launch AND (report_final_month_launch IS NULL OR report_initial_month_launch IS NULL)))
);
ALTER TABLE transactions.transaction_reports OWNER TO "SisFinance-adm";

COMMENT ON TABLE transactions.transaction_reports IS 'Armazena configurações para geração de relatórios de transações financeiras, incluindo filtros avançados, agendamentos automáticos, controle de envio e metadados de geração.';

COMMENT ON COLUMN transactions.transaction_reports.report_id IS 'Identificador único do relatório (PK, fornecido externamente).';
COMMENT ON COLUMN transactions.transaction_reports.report_user_id IS 'Usuário proprietário deste relatório (FK para core.users).';
COMMENT ON COLUMN transactions.transaction_reports.report_time_choice IS 'Define o tipo de filtro temporal do relatório (Por Lançamento, Por Data, Por Período).';
COMMENT ON COLUMN transactions.transaction_reports.report_type IS 'Tipo de transações incluídas no relatório (Cartão de Crédito, Saldo, ou ambos).';
COMMENT ON COLUMN transactions.transaction_reports.report_initial_month_launch IS 'Mês inicial para filtro por lançamento (só preenchido se time_choice = ''Por Lançamento'').';
COMMENT ON COLUMN transactions.transaction_reports.report_initial_year_launch IS 'Ano inicial YYYY para filtro por lançamento (só preenchido se time_choice = ''Por Lançamento'').';
COMMENT ON COLUMN transactions.transaction_reports.report_final_month_launch IS 'Mês final para filtro por lançamento (só preenchido se time_choice = ''Por Lançamento'').';
COMMENT ON COLUMN transactions.transaction_reports.report_final_year_launch IS 'Ano final YYYY para filtro por lançamento (só preenchido se time_choice = ''Por Lançamento'').';
COMMENT ON COLUMN transactions.transaction_reports.report_initial_date IS 'Data inicial para filtro por data específica (só preenchido se time_choice = ''Por Data'').';
COMMENT ON COLUMN transactions.transaction_reports.report_final_date IS 'Data final para filtro por data específica (só preenchido se time_choice = ''Por Data'').';
COMMENT ON COLUMN transactions.transaction_reports.report_relative_period IS 'Período relativo à data atual (só preenchido se time_choice = ''Por Período'').';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_account IS 'Indica se o relatório deve filtrar por conta específica (aplicável apenas para tipos que incluem transações de saldo).';
COMMENT ON COLUMN transactions.transaction_reports.report_account_id IS 'Conta específica para filtrar (FK para core.user_accounts), só preenchido se filter_by_account = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_creditcard IS 'Indica se o relatório deve filtrar por cartão específico (aplicável apenas para tipos que incluem transações de cartão).';
COMMENT ON COLUMN transactions.transaction_reports.report_user_creditcard_id IS 'Cartão específico para filtrar (FK para core.user_creditcard), só preenchido se filter_by_creditcard = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_operator IS 'Indica se o relatório deve filtrar por operador específico. Padrão: FALSE.';
COMMENT ON COLUMN transactions.transaction_reports.report_operator_id IS 'Operador específico para filtrar (FK para core.operators), só preenchido se filter_by_operator = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_description IS 'Indica se o relatório deve filtrar por texto na descrição. Padrão: FALSE.';
COMMENT ON COLUMN transactions.transaction_reports.report_description IS 'Texto para filtrar nas descrições das transações, só preenchido se filter_by_description = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_proceeding_saldo IS 'Indica se deve filtrar por procedimento de saldo específico (aplicável apenas para tipos que incluem transações de saldo).';
COMMENT ON COLUMN transactions.transaction_reports.report_proceeding_saldo_id IS 'Procedimento de saldo específico para filtrar (FK para core.proceedings_saldo), só preenchido se filter_by_proceeding_saldo = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_proceeding_creditcard IS 'Indica se deve filtrar por procedimento de cartão específico (aplicável apenas para tipos que incluem transações de cartão).';
COMMENT ON COLUMN transactions.transaction_reports.report_proceeding_creditcard IS 'Procedimento de cartão específico para filtrar (ENUM), só preenchido se filter_by_proceeding_creditcard = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_status IS 'Indica se o relatório deve filtrar por status específico (Efetuado/Pendente). Padrão: FALSE.';
COMMENT ON COLUMN transactions.transaction_reports.report_status IS 'Status específico para filtrar (ENUM), só preenchido se filter_by_status = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_recurrence_id IS 'Indica se o relatório deve filtrar por recorrência específica. Padrão: FALSE.';
COMMENT ON COLUMN transactions.transaction_reports.report_recurrence_id IS 'Recorrência específica para filtrar (FK para transactions.recurrence_saldo), só preenchido se filter_by_recurrence_id = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_category IS 'Indica se o relatório deve filtrar por categoria específica. Padrão: FALSE.';
COMMENT ON COLUMN transactions.transaction_reports.report_category_id IS 'Categoria específica para filtrar (FK para core.categories), só preenchido se filter_by_category = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_ir_relevance IS 'Indica se o relatório deve filtrar por relevância para Imposto de Renda. Padrão: FALSE.';
COMMENT ON COLUMN transactions.transaction_reports.report_ir_relevance IS 'Valor específico de relevância IR para filtrar (TRUE/FALSE), só preenchido se filter_by_ir_relevance = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_operation IS 'Indica se deve filtrar por tipo de operação específica (aplicável apenas para tipos que incluem transações de saldo).';
COMMENT ON COLUMN transactions.transaction_reports.report_operation IS 'Tipo de operação específica para filtrar (Crédito/Débito), só preenchido se filter_by_operation = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_filter_by_installments IS 'Indica se deve filtrar por transações parceladas (aplicável apenas para tipos que incluem transações de cartão).';
COMMENT ON COLUMN transactions.transaction_reports.report_installments IS 'Se deve incluir transações parceladas (TRUE) ou não parceladas (FALSE), só preenchido se filter_by_installments = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_number_of_installments IS 'Número específico de parcelas para filtrar (1-420), só preenchido se installments = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_send_to_operator_id IS 'Operador destinatário do relatório gerado (FK para core.operators).';
COMMENT ON COLUMN transactions.transaction_reports.report_auto_generate IS 'Indica se o relatório deve ser gerado automaticamente de forma recorrente. Padrão: FALSE.';
COMMENT ON COLUMN transactions.transaction_reports.report_auto_frequency IS 'Frequência de geração automática do relatório, só preenchido se auto_generate = TRUE.';
COMMENT ON COLUMN transactions.transaction_reports.report_insights IS 'Observações, análises ou comentários sobre o relatório (opcional).';
COMMENT ON COLUMN transactions.transaction_reports.report_generation_datetime IS 'Data e hora exatas (UTC) de geração do relatório. Preenchido automaticamente.';
COMMENT ON COLUMN transactions.transaction_reports.report_sent_datetime IS 'Data e hora exatas (UTC) de envio do relatório para o destinatário (opcional).';
COMMENT ON COLUMN transactions.transaction_reports.report_access_link IS 'Link ou URL para acessar o relatório gerado (opcional).';
COMMENT ON COLUMN transactions.transaction_reports.report_already_generated IS 'Indica se o relatório já foi gerado (NULL apenas para relatórios recorrentes que ainda não foram processados).';
COMMENT ON COLUMN transactions.transaction_reports.report_recurring_status IS 'Status da recorrência automática (Ativado/Desativado), NULL apenas para relatórios não-recorrentes.';


-- =============================================================================
-- CRIAÇÃO DAS TABELAS DO SCHEMA "auditoria"
-- =============================================================================

-- Tabela: core_audit_log (para auditar mudanças no schema "core")
CREATE TABLE auditoria.core_audit_log (
    core_audit_log_id character varying(50) NOT NULL,
    core_audit_log_timestamp timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    core_audit_log_user_id character varying(50) NULL,
    core_audit_log_user_name character varying(200) NULL,
    core_audit_log_ip_address character varying(45) NULL,
    core_audit_log_application character varying(100) NULL,
    core_audit_log_action auditoria.action_type NOT NULL,
    core_audit_log_table_name character varying(100) NOT NULL,
    core_audit_log_record_id character varying(100) NOT NULL,
    core_audit_log_old_data jsonb NULL,
    core_audit_log_new_data jsonb NULL,
    CONSTRAINT core_audit_log_pkey PRIMARY KEY (core_audit_log_id)
);
ALTER TABLE auditoria.core_audit_log OWNER TO "SisFinance-adm";
COMMENT ON TABLE auditoria.core_audit_log IS 'Registra todas as operações de inserção, atualização e exclusão realizadas nas tabelas do schema "core".';
COMMENT ON COLUMN auditoria.core_audit_log.core_audit_log_id IS 'Identificador único do registro de auditoria (PK, fornecido externamente).';
COMMENT ON COLUMN auditoria.core_audit_log.core_audit_log_timestamp IS 'Data e hora exatas em que a operação foi registrada no log de auditoria.';
COMMENT ON COLUMN auditoria.core_audit_log.core_audit_log_user_id IS 'ID do usuário que realizou a operação, se disponível/aplicável.';
COMMENT ON COLUMN auditoria.core_audit_log.core_audit_log_user_name IS 'Nome ou identificação textual do usuário que realizou a operação.';
COMMENT ON COLUMN auditoria.core_audit_log.core_audit_log_ip_address IS 'Endereço IP de onde a operação foi originada, se disponível.';
COMMENT ON COLUMN auditoria.core_audit_log.core_audit_log_application IS 'Nome ou identificação da aplicação que realizou a operação, se disponível.';
COMMENT ON COLUMN auditoria.core_audit_log.core_audit_log_action IS 'Tipo de operação realizada: INSERT, UPDATE ou DELETE.';
COMMENT ON COLUMN auditoria.core_audit_log.core_audit_log_table_name IS 'Nome da tabela do schema "core" que foi afetada pela operação.';
COMMENT ON COLUMN auditoria.core_audit_log.core_audit_log_record_id IS 'Identificador do registro que foi afetado pela operação.';
COMMENT ON COLUMN auditoria.core_audit_log.core_audit_log_old_data IS 'Estado anterior do registro antes da operação (para UPDATE e DELETE), armazenado como JSON.';
COMMENT ON COLUMN auditoria.core_audit_log.core_audit_log_new_data IS 'Novo estado do registro após a operação (para INSERT e UPDATE), armazenado como JSON.';

-- Tabela: transactions_audit_log (para auditar mudanças no schema "transactions")
CREATE TABLE auditoria.transactions_audit_log (
    transactions_audit_log_id character varying(50) NOT NULL,
    transactions_audit_log_timestamp timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    transactions_audit_log_user_id character varying(50) NULL,
    transactions_audit_log_user_name character varying(200) NULL,
    transactions_audit_log_ip_address character varying(45) NULL,
    transactions_audit_log_application character varying(100) NULL,
    transactions_audit_log_action auditoria.action_type NOT NULL,
    transactions_audit_log_table_name character varying(100) NOT NULL,
    transactions_audit_log_record_id character varying(100) NOT NULL,
    transactions_audit_log_old_data jsonb NULL,
    transactions_audit_log_new_data jsonb NULL,
    CONSTRAINT transactions_audit_log_pkey PRIMARY KEY (transactions_audit_log_id)
);
ALTER TABLE auditoria.transactions_audit_log OWNER TO "SisFinance-adm";
COMMENT ON TABLE auditoria.transactions_audit_log IS 'Registra todas as operações de inserção, atualização e exclusão realizadas nas tabelas do schema "transactions".';
COMMENT ON COLUMN auditoria.transactions_audit_log.transactions_audit_log_id IS 'Identificador único do registro de auditoria (PK, fornecido externamente).';
COMMENT ON COLUMN auditoria.transactions_audit_log.transactions_audit_log_timestamp IS 'Data e hora exatas em que a operação foi registrada no log de auditoria.';
COMMENT ON COLUMN auditoria.transactions_audit_log.transactions_audit_log_user_id IS 'ID do usuário que realizou a operação, se disponível/aplicável.';
COMMENT ON COLUMN auditoria.transactions_audit_log.transactions_audit_log_user_name IS 'Nome ou identificação textual do usuário que realizou a operação.';
COMMENT ON COLUMN auditoria.transactions_audit_log.transactions_audit_log_ip_address IS 'Endereço IP de onde a operação foi originada, se disponível.';
COMMENT ON COLUMN auditoria.transactions_audit_log.transactions_audit_log_application IS 'Nome ou identificação da aplicação que realizou a operação, se disponível.';
COMMENT ON COLUMN auditoria.transactions_audit_log.transactions_audit_log_action IS 'Tipo de operação realizada: INSERT, UPDATE ou DELETE.';
COMMENT ON COLUMN auditoria.transactions_audit_log.transactions_audit_log_table_name IS 'Nome da tabela do schema "transactions" que foi afetada pela operação.';
COMMENT ON COLUMN auditoria.transactions_audit_log.transactions_audit_log_record_id IS 'Identificador do registro que foi afetado pela operação.';
COMMENT ON COLUMN auditoria.transactions_audit_log.transactions_audit_log_old_data IS 'Estado anterior do registro antes da operação (para UPDATE e DELETE), armazenado como JSON.';
COMMENT ON COLUMN auditoria.transactions_audit_log.transactions_audit_log_new_data IS 'Novo estado do registro após a operação (para INSERT e UPDATE), armazenado como JSON.';

-- =============================================================================
-- RELACIONAMENTOS ENTRE TABELAS ATRAVÉS DE FOREIGN KEYS
-- =============================================================================

ALTER TABLE core.operators 
    VALIDATE CONSTRAINT fk_operators_user;

ALTER TABLE core.institution_accounts 
    VALIDATE CONSTRAINT fk_institution_accounts_institution,
    VALIDATE CONSTRAINT fk_institution_accounts_type;

ALTER TABLE core.user_accounts 
    VALIDATE CONSTRAINT fk_user_accounts_user,
    VALIDATE CONSTRAINT fk_user_accounts_account;

ALTER TABLE core.user_accounts_pix_keys 
    VALIDATE CONSTRAINT fk_uapix_user_account;

ALTER TABLE core.creditcard 
    VALIDATE CONSTRAINT fk_creditcard_financial_institution;

ALTER TABLE core.user_creditcard 
    VALIDATE CONSTRAINT fk_usercred_user,
    VALIDATE CONSTRAINT fk_usercred_card,
    VALIDATE CONSTRAINT fk_usercred_payment_account;

ALTER TABLE transactions.recurrence_saldo 
    VALIDATE CONSTRAINT fk_recurrence_user_account,
    VALIDATE CONSTRAINT fk_recurrence_proceeding,
    VALIDATE CONSTRAINT fk_recurrence_category,
    VALIDATE CONSTRAINT fk_recurrence_operator;

ALTER TABLE transactions.transactions_saldo 
    VALIDATE CONSTRAINT fk_transactions_user_account,
    VALIDATE CONSTRAINT fk_transactions_proceeding,
    VALIDATE CONSTRAINT fk_transactions_category,
    VALIDATE CONSTRAINT fk_transactions_operator,
    VALIDATE CONSTRAINT fk_transactions_recurrence;

ALTER TABLE transactions.internal_transfers 
    VALIDATE CONSTRAINT fk_inttransf_origin,
    VALIDATE CONSTRAINT fk_inttransf_destination,
    VALIDATE CONSTRAINT fk_inttransf_operator;

ALTER TABLE transactions.creditcard_invoices 
    VALIDATE CONSTRAINT fk_invoice_usercard;

ALTER TABLE transactions.recurrence_creditcard 
    VALIDATE CONSTRAINT fk_ccrecur_usercard,
    VALIDATE CONSTRAINT fk_ccrecur_category,
    VALIDATE CONSTRAINT fk_ccrecur_operator;

ALTER TABLE transactions.creditcard_transactions 
    VALIDATE CONSTRAINT fk_cctrans_invoice,
    VALIDATE CONSTRAINT fk_cctrans_category,
    VALIDATE CONSTRAINT fk_cctrans_operator,
    VALIDATE CONSTRAINT fk_cctrans_recurrence;

ALTER TABLE transactions.creditcard_installments 
    VALIDATE CONSTRAINT fk_ccinstall_transaction,
    VALIDATE CONSTRAINT fk_ccinstall_invoice;

ALTER TABLE transactions.transaction_reports 
    VALIDATE CONSTRAINT fk_transactionreports_user,
    VALIDATE CONSTRAINT fk_transactionreports_acc,
    VALIDATE CONSTRAINT fk_transactionreports_cc,
    VALIDATE CONSTRAINT fk_transactionreports_oper,
    VALIDATE CONSTRAINT fk_transactionreports_send_oper,
    VALIDATE CONSTRAINT fk_transactionreports_procS,
    VALIDATE CONSTRAINT fk_transactionreports_rec,
    VALIDATE CONSTRAINT fk_transactionreports_cat;

ANALYZE;

-- =============================================================================
-- CRIAÇÃO DE TRIGGERS DE IMUTABILIDADE DE PRIMARY KEY
-- =============================================================================

-- Função genérica para impedir update de PK
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
$$ LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION public.prevent_generic_pk_update() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.prevent_generic_pk_update() IS 'Função de Trigger genérica que impede a atualização da coluna de chave primária especificada como argumento. Garante a imutabilidade dos identificadores primários.';

-- Função para validar chaves PIX
CREATE OR REPLACE FUNCTION public.validate_pix_key()
RETURNS TRIGGER AS $$
BEGIN
    -- Validação para chave PIX do tipo CPF
    IF NEW.user_accounts_pix_keys_type = 'CPF' THEN
        -- Remove caracteres não numéricos
        NEW.user_accounts_pix_keys_key := regexp_replace(NEW.user_accounts_pix_keys_key, '[^0-9]', '', 'g');
        
        -- Verifica se tem exatamente 11 dígitos
        IF length(NEW.user_accounts_pix_keys_key) != 11 THEN
            RAISE EXCEPTION 'CPF deve conter exatamente 11 dígitos numéricos. CPF informado: %', NEW.user_accounts_pix_keys_key;
        END IF;
        
        -- Verifica se não são todos os dígitos iguais
        IF NEW.user_accounts_pix_keys_key ~ '^(.)\1{10}$' THEN
            RAISE EXCEPTION 'CPF inválido: todos os dígitos são iguais. CPF informado: %', NEW.user_accounts_pix_keys_key;
        END IF;
        
        -- Validação do dígito verificador do CPF
        DECLARE
            v_cpf TEXT := NEW.user_accounts_pix_keys_key;
            v_soma INTEGER := 0;
            v_resto INTEGER;
            v_dv1 INTEGER;
            v_dv2 INTEGER;
            i INTEGER;
        BEGIN
            -- Cálculo do primeiro dígito verificador
            FOR i IN 1..9 LOOP
                v_soma := v_soma + (substring(v_cpf, i, 1)::INTEGER * (11 - i));
            END LOOP;
            
            v_resto := v_soma % 11;
            IF v_resto < 2 THEN
                v_dv1 := 0;
            ELSE
                v_dv1 := 11 - v_resto;
            END IF;
            
            -- Verifica o primeiro dígito
            IF v_dv1 != substring(v_cpf, 10, 1)::INTEGER THEN
                RAISE EXCEPTION 'CPF inválido: primeiro dígito verificador incorreto. CPF informado: %', NEW.user_accounts_pix_keys_key;
            END IF;
            
            -- Cálculo do segundo dígito verificador
            v_soma := 0;
            FOR i IN 1..10 LOOP
                v_soma := v_soma + (substring(v_cpf, i, 1)::INTEGER * (12 - i));
            END LOOP;
            
            v_resto := v_soma % 11;
            IF v_resto < 2 THEN
                v_dv2 := 0;
            ELSE
                v_dv2 := 11 - v_resto;
            END IF;
            
            -- Verifica o segundo dígito
            IF v_dv2 != substring(v_cpf, 11, 1)::INTEGER THEN
                RAISE EXCEPTION 'CPF inválido: segundo dígito verificador incorreto. CPF informado: %', NEW.user_accounts_pix_keys_key;
            END IF;
        END;
    END IF;
    
    -- Validação para chave PIX do tipo E-mail
    IF NEW.user_accounts_pix_keys_type = 'E-mail' THEN
        NEW.user_accounts_pix_keys_key := validate_email_format(NEW.user_accounts_pix_keys_key);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION public.validate_pix_key() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.validate_pix_key() IS 'Função de trigger para validar chaves PIX do tipo CPF (validação completa com dígitos verificadores) e E-mail (validação de formato RFC).';

-- Criação do trigger de validação das chaves PIX
CREATE TRIGGER trigger_validate_pix_key
    BEFORE INSERT OR UPDATE ON core.user_accounts_pix_keys
    FOR EACH ROW EXECUTE FUNCTION public.validate_pix_key();

COMMENT ON TRIGGER trigger_validate_pix_key ON core.user_accounts_pix_keys IS 'Trigger para validar automaticamente chaves PIX do tipo CPF e E-mail antes de inserir ou atualizar.';

-- Trigger para users
CREATE TRIGGER trigger_prevent_users_pk_update
BEFORE UPDATE ON core.users
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('users_id');
COMMENT ON TRIGGER trigger_prevent_users_pk_update ON core.users IS 'Trigger para impedir atualização da PK em users.';

-- Trigger para categories
CREATE TRIGGER trigger_prevent_categories_pk_update
BEFORE UPDATE ON core.categories
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('categories_id');
COMMENT ON TRIGGER trigger_prevent_categories_pk_update ON core.categories IS 'Trigger para impedir atualização da PK em categories.';

-- Trigger para proceedings_saldo
CREATE TRIGGER trigger_prevent_proceedings_pk_update
BEFORE UPDATE ON core.proceedings_saldo
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('proceedings_id');
COMMENT ON TRIGGER trigger_prevent_proceedings_pk_update ON core.proceedings_saldo IS 'Trigger para impedir atualização da PK em proceedings_saldo.';

-- Trigger para financial_institutions
CREATE TRIGGER trigger_prevent_fin_inst_pk_update
BEFORE UPDATE ON core.financial_institutions
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('financial_institutions_id');
COMMENT ON TRIGGER trigger_prevent_fin_inst_pk_update ON core.financial_institutions IS 'Trigger para impedir atualização da PK em financial_institutions.';

-- Trigger para account_types
CREATE TRIGGER trigger_prevent_acc_types_pk_update
BEFORE UPDATE ON core.account_types
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('account_types_id');
COMMENT ON TRIGGER trigger_prevent_acc_types_pk_update ON core.account_types IS 'Trigger para impedir atualização da PK em account_types.';

-- Trigger para institution_accounts
CREATE TRIGGER trigger_prevent_inst_acc_pk_update
BEFORE UPDATE ON core.institution_accounts
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('institution_accounts_id');
COMMENT ON TRIGGER trigger_prevent_inst_acc_pk_update ON core.institution_accounts IS 'Trigger para impedir atualização da PK em institution_accounts.';

-- Trigger para operators
CREATE TRIGGER trigger_prevent_operators_pk_update
BEFORE UPDATE ON core.operators
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('operators_id');
COMMENT ON TRIGGER trigger_prevent_operators_pk_update ON core.operators IS 'Trigger para impedir atualização da PK em operators.';

-- Trigger para user_accounts
CREATE TRIGGER trigger_prevent_user_acc_pk_update
BEFORE UPDATE ON core.user_accounts
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('user_accounts_id');
COMMENT ON TRIGGER trigger_prevent_user_acc_pk_update ON core.user_accounts IS 'Trigger para impedir atualização da PK em user_accounts.';

-- Trigger para user_accounts_pix_keys
CREATE TRIGGER trigger_prevent_uapix_pk_update
BEFORE UPDATE ON core.user_accounts_pix_keys
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('user_accounts_pix_keys_id');
COMMENT ON TRIGGER trigger_prevent_uapix_pk_update ON core.user_accounts_pix_keys IS 'Trigger para impedir atualização da PK em user_accounts_pix_keys.';

-- Trigger para creditcard
CREATE TRIGGER trigger_prevent_cc_pk_update
BEFORE UPDATE ON core.creditcard
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_id');
COMMENT ON TRIGGER trigger_prevent_cc_pk_update ON core.creditcard IS 'Trigger para impedir atualização da PK em creditcard.';

-- Trigger para user_creditcard
CREATE TRIGGER trigger_prevent_user_cc_pk_update
BEFORE UPDATE ON core.user_creditcard
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('user_creditcard_id');
COMMENT ON TRIGGER trigger_prevent_user_cc_pk_update ON core.user_creditcard IS 'Trigger para impedir atualização da PK em user_creditcard.';

-- Trigger para recurrence_saldo
CREATE TRIGGER trigger_prevent_recurr_saldo_pk_update
BEFORE UPDATE ON transactions.recurrence_saldo
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('recurrence_saldo_id');
COMMENT ON TRIGGER trigger_prevent_recurr_saldo_pk_update ON transactions.recurrence_saldo IS 'Trigger para impedir atualização da PK em recurrence_saldo.';

-- Trigger para transactions_saldo (usando a função específica)
CREATE TRIGGER trigger_prevent_trans_saldo_pk_update
BEFORE UPDATE ON transactions.transactions_saldo
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('transactions_saldo_id');
COMMENT ON TRIGGER trigger_prevent_trans_saldo_pk_update ON transactions.transactions_saldo IS 'Trigger para impedir atualização da PK em transactions_saldo.';

-- Trigger para transaction_reports (usando a função específica)
CREATE TRIGGER trigger_prevent_trans_reports_pk_update
BEFORE UPDATE ON transactions.transaction_reports
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('report_id');
COMMENT ON TRIGGER trigger_prevent_trans_reports_pk_update ON transactions.transaction_reports IS 'Trigger para impedir atualização da PK em transactions_reports.';

-- Trigger para internal_transfers
CREATE TRIGGER trigger_prevent_internal_transfers_pk_update
BEFORE UPDATE ON transactions.internal_transfers
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('internal_transfers_id');
COMMENT ON TRIGGER trigger_prevent_internal_transfers_pk_update ON transactions.internal_transfers IS 'Trigger para impedir atualização da PK em internal_transfers.';

-- Trigger para creditcard_invoices
CREATE TRIGGER trigger_prevent_cc_invoice_pk_update
BEFORE UPDATE ON transactions.creditcard_invoices
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_invoices_id');
COMMENT ON TRIGGER trigger_prevent_cc_invoice_pk_update ON transactions.creditcard_invoices IS 'Trigger para impedir atualização da PK em creditcard_invoices.';

-- Trigger para recurrence_creditcard
CREATE TRIGGER trigger_prevent_recurr_cc_pk_update
BEFORE UPDATE ON transactions.recurrence_creditcard
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_recurrence_id');
COMMENT ON TRIGGER trigger_prevent_recurr_cc_pk_update ON transactions.recurrence_creditcard IS 'Trigger para impedir atualização da PK em recurrence_creditcard.';

-- Trigger para creditcard_transactions
CREATE TRIGGER trigger_prevent_cctrans_pk_update
BEFORE UPDATE ON transactions.creditcard_transactions
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_transactions_id');
COMMENT ON TRIGGER trigger_prevent_cctrans_pk_update ON transactions.creditcard_transactions IS 'Trigger para impedir atualização da PK em creditcard_transactions.';

-- Trigger para creditcard_installments
CREATE TRIGGER trigger_prevent_ccinstall_pk_update
BEFORE UPDATE ON transactions.creditcard_installments
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('creditcard_installments_id');
COMMENT ON TRIGGER trigger_prevent_ccinstall_pk_update ON transactions.creditcard_installments IS 'Trigger para impedir atualização da PK em creditcard_installments.';

-- Trigger para core_audit_log
CREATE TRIGGER trigger_prevent_core_audit_pk_update
BEFORE UPDATE ON auditoria.core_audit_log
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('core_audit_log_id');
COMMENT ON TRIGGER trigger_prevent_core_audit_pk_update ON auditoria.core_audit_log IS 'Trigger para impedir atualização da PK em core_audit_log.';

-- Trigger para transactions_audit_log
CREATE TRIGGER trigger_prevent_trans_audit_pk_update
BEFORE UPDATE ON auditoria.transactions_audit_log
FOR EACH ROW EXECUTE FUNCTION public.prevent_generic_pk_update('transactions_audit_log_id');
COMMENT ON TRIGGER trigger_prevent_trans_audit_pk_update ON auditoria.transactions_audit_log IS 'Trigger para impedir atualização da PK em transactions_audit_log.';

-- =============================================================================
-- CRIAÇÃO DE FUNÇÕES SQL
-- =============================================================================

-- Função de Validação Operation/Proceeding (Saldo)
CREATE OR REPLACE FUNCTION public.check_operation_proceeding_compatibility(
    p_operation core.operation,
    p_proceeding_id character varying(50)
)
RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN p_operation = 'Crédito' THEN
            COALESCE((SELECT proceedings_credit FROM core.proceedings_saldo WHERE proceedings_id = p_proceeding_id), FALSE)
        WHEN p_operation = 'Débito' THEN
            COALESCE((SELECT proceedings_debit FROM core.proceedings_saldo WHERE proceedings_id = p_proceeding_id), FALSE)
        ELSE FALSE
    END;
$$;
ALTER FUNCTION public.check_operation_proceeding_compatibility(core.operation, character varying) OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.check_operation_proceeding_compatibility(core.operation, character varying) IS 'Verifica se a natureza da Operação (Crédito/Débito) é compatível com as permissões (credit/debit) do Procedimento especificado.';

-- Função de Validação Operation/Category (Saldo)
CREATE OR REPLACE FUNCTION public.check_operation_category_compatibility(
    p_operation core.operation,
    p_category_id character varying(50)
)
RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN p_operation = 'Crédito' THEN
            COALESCE((SELECT categories_credit FROM core.categories WHERE categories_id = p_category_id), FALSE)
        WHEN p_operation = 'Débito' THEN
            COALESCE((SELECT categories_debit FROM core.categories WHERE categories_id = p_category_id), FALSE)
        ELSE FALSE
    END;
$$;
ALTER FUNCTION public.check_operation_category_compatibility(core.operation, character varying) OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.check_operation_category_compatibility(core.operation, character varying) IS 'Verifica se a natureza da Operação (Crédito/Débito) é compatível com as permissões (credit/debit) da Categoria especificada.';

-- Função de Validação Procedure CC / Category
CREATE OR REPLACE FUNCTION public.check_procedure_category_compatibility_cc(
    p_procedure transactions.creditcard_transaction_procedure,
    p_category_id character varying(50)
)
RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN p_procedure = 'Crédito em Fatura' THEN
            COALESCE((SELECT categories_credit FROM core.categories WHERE categories_id = p_category_id), FALSE) -- Crédito na fatura geralmente se alinha com categoria de crédito (ex: estorno de compra)
        WHEN p_procedure = 'Débito em Fatura' THEN
            COALESCE((SELECT categories_debit FROM core.categories WHERE categories_id = p_category_id), FALSE) -- Débito na fatura se alinha com categoria de débito (ex: compra)
        ELSE FALSE
    END;
$$;
ALTER FUNCTION public.check_procedure_category_compatibility_cc(transactions.creditcard_transaction_procedure, character varying) OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.check_procedure_category_compatibility_cc(transactions.creditcard_transaction_procedure, character varying) IS 'Verifica se o Procedimento de transação de Cartão de Crédito é compatível com as permissões da Categoria especificada.';

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
    SELECT proceedings_id INTO v_proc_id FROM core.proceedings_saldo WHERE proceedings_name = v_proceeding_name;
    SELECT categories_id INTO v_cat_id FROM core.categories WHERE categories_name = v_category_name;

    IF v_proc_id IS NULL THEN
        RAISE EXCEPTION 'Procedimento padrão "%" não encontrado na tabela proceedings_saldo. Verifique se foi criado e se o nome está correto na função do trigger.', v_proceeding_name;
    END IF;
    IF v_cat_id IS NULL THEN
        RAISE EXCEPTION 'Categoria padrão "%" não encontrada na tabela categories. Verifique se foi criada e se o nome está correto na função do trigger.', v_category_name;
    END IF;

    IF (TG_OP = 'INSERT') THEN
        v_debit_txn_id := NEW.internal_transfers_id || '-D';
        v_credit_txn_id := NEW.internal_transfers_id || '-C';
        v_credit_registration_datetime := NEW.internal_transfers_registration_datetime;
        v_credit_implementation_datetime := NEW.internal_transfers_implementation_datetime;

        INSERT INTO transactions.transactions_saldo (
            transactions_saldo_id, transactions_saldo_user_accounts_id,
            transactions_saldo_operation, transactions_saldo_proceeding_id, transactions_saldo_status,
            transactions_saldo_category_id, transactions_saldo_operator_id, transactions_saldo_description,
            transactions_saldo_observations, transactions_saldo_registration_datetime, transactions_saldo_is_recurrence,
            transactions_saldo_recurrence_id, transactions_saldo_schedule_datetime, transactions_saldo_implementation_datetime,
            transactions_saldo_base_value, transactions_saldo_fees_taxes, transactions_saldo_receipt_image,
            transactions_saldo_relevance_ir, transactions_saldo_last_update
        ) VALUES (
            v_debit_txn_id, NEW.internal_transfers_origin_user_account_id,
            'Débito'::core.operation, v_proc_id, 'Efetuado'::transactions.status, v_cat_id, NEW.internal_transfers_operator_id, v_description,
            NEW.internal_transfers_observations, NEW.internal_transfers_registration_datetime, FALSE, NULL, NULL, NEW.internal_transfers_implementation_datetime,
            NEW.internal_transfers_base_value, NEW.internal_transfers_fees_taxes, NEW.internal_transfers_receipt_image, FALSE, NEW.internal_transfers_last_update
        );
        INSERT INTO transactions.transactions_saldo (
            transactions_saldo_id, transactions_saldo_user_accounts_id,
            transactions_saldo_operation, transactions_saldo_proceeding_id, transactions_saldo_status,
            transactions_saldo_category_id, transactions_saldo_operator_id, transactions_saldo_description,
            transactions_saldo_observations, transactions_saldo_registration_datetime, transactions_saldo_is_recurrence,
            transactions_saldo_recurrence_id, transactions_saldo_schedule_datetime, transactions_saldo_implementation_datetime,
            transactions_saldo_base_value, transactions_saldo_fees_taxes, transactions_saldo_receipt_image,
            transactions_saldo_relevance_ir, transactions_saldo_last_update
        ) VALUES (
            v_credit_txn_id, NEW.internal_transfers_destination_user_account_id,
            'Crédito'::core.operation, v_proc_id, 'Efetuado'::transactions.status, v_cat_id, NEW.internal_transfers_operator_id, v_description,
            NEW.internal_transfers_observations, v_credit_registration_datetime, FALSE, NULL, NULL, v_credit_implementation_datetime,
            NEW.internal_transfers_base_value, 0, NEW.internal_transfers_receipt_image, FALSE, NEW.internal_transfers_last_update
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        v_debit_txn_id := NEW.internal_transfers_id || '-D';
        v_credit_txn_id := NEW.internal_transfers_id || '-C';
        v_credit_registration_datetime := NEW.internal_transfers_registration_datetime + INTERVAL '1 millisecond';
        v_credit_implementation_datetime := NEW.internal_transfers_implementation_datetime + INTERVAL '1 millisecond';

        UPDATE transactions.transactions_saldo SET
            transactions_saldo_user_accounts_id = NEW.internal_transfers_origin_user_account_id,
            transactions_saldo_operator_id = NEW.internal_transfers_operator_id, transactions_saldo_description = v_description,
            transactions_saldo_observations = NEW.internal_transfers_observations, transactions_saldo_registration_datetime = NEW.internal_transfers_registration_datetime,
            transactions_saldo_schedule_datetime = NULL, transactions_saldo_implementation_datetime = NEW.internal_transfers_implementation_datetime,
            transactions_saldo_base_value = NEW.internal_transfers_base_value, transactions_saldo_fees_taxes = NEW.internal_transfers_fees_taxes,
            transactions_saldo_receipt_image = NEW.internal_transfers_receipt_image, transactions_saldo_last_update = NEW.internal_transfers_last_update,
            transactions_saldo_proceeding_id = v_proc_id, transactions_saldo_category_id = v_cat_id
        WHERE transactions_saldo_id = v_debit_txn_id;

        UPDATE transactions.transactions_saldo SET
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
        DELETE FROM transactions.transactions_saldo WHERE transactions_saldo_id = v_debit_txn_id;
        DELETE FROM transactions.transactions_saldo WHERE transactions_saldo_id = v_credit_txn_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.sync_internal_transfer_to_transactions() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.sync_internal_transfer_to_transactions() IS 'Sincroniza inserções, atualizações e exclusões da tabela internal_transfers para a tabela transactions_saldo, criando/modificando/removendo automaticamente os pares de transações (débito e crédito) correspondentes.';

-- Aplicar o trigger de sincronização para internal_transfers
CREATE TRIGGER trigger_sync_internal_transfer
AFTER INSERT OR UPDATE OR DELETE ON transactions.internal_transfers
FOR EACH ROW EXECUTE FUNCTION public.sync_internal_transfer_to_transactions();
COMMENT ON TRIGGER trigger_sync_internal_transfer ON transactions.internal_transfers IS 'Trigger para sincronizar internal_transfers com transactions_saldo.';

ALTER FUNCTION public.validate_email_format(TEXT) OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.validate_email_format(TEXT) IS 'Função para validação e normalização de formato de e-mail. Retorna o e-mail normalizado (lowercase, trimmed) ou gera exceção se inválido.';

-- Função para registrar auditoria no schema "core"
CREATE OR REPLACE FUNCTION public.log_core_audit()
RETURNS TRIGGER AS $$
DECLARE
    v_audit_id VARCHAR(50);
    v_old_data JSONB := NULL;
    v_new_data JSONB := NULL;
    v_user_name VARCHAR(200) := current_setting('app.current_user_name', TRUE);
    v_user_id VARCHAR(50) := current_setting('app.current_user_id', TRUE);
    v_app_name VARCHAR(100) := current_setting('app.application_name', TRUE);
    v_ip_address VARCHAR(45) := current_setting('app.client_ip', TRUE);
    v_action auditoria.action_type;
BEGIN
    -- Gerar ID de auditoria (timestamp em microssegundos + 8 caracteres aleatórios)
    v_audit_id := to_char(clock_timestamp(), 'YYYYMMDDHH24MISSUS') || substr(md5(random()::text), 1, 8);
    
    -- Determinar ação e dados
    IF (TG_OP = 'INSERT') THEN
        v_action := 'INSERT'::auditoria.action_type;
        v_new_data := to_jsonb(NEW);
    ELSIF (TG_OP = 'UPDATE') THEN
        v_action := 'UPDATE'::auditoria.action_type;
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
    ELSIF (TG_OP = 'DELETE') THEN
        v_action := 'DELETE'::auditoria.action_type;
        v_old_data := to_jsonb(OLD);
    END IF;
    
    -- Tratar variáveis nulas - usar valores de fallback
    v_user_name := COALESCE(v_user_name, 'system');
    v_user_id := COALESCE(v_user_id, 'system');
    v_app_name := COALESCE(v_app_name, TG_NAME);
    v_ip_address := COALESCE(v_ip_address, '0.0.0.0');

    -- Inserir log na tabela de auditoria do core
    INSERT INTO auditoria.core_audit_log (
        core_audit_log_id,
        core_audit_log_timestamp,
        core_audit_log_user_id,
        core_audit_log_user_name,
        core_audit_log_ip_address,
        core_audit_log_application,
        core_audit_log_action,
        core_audit_log_table_name,
        core_audit_log_record_id,
        core_audit_log_old_data,
        core_audit_log_new_data
    ) VALUES (
        v_audit_id,
        clock_timestamp(),
        v_user_id,
        v_user_name,
        v_ip_address,
        v_app_name,
        v_action,
        TG_TABLE_NAME,
        CASE 
            WHEN TG_OP = 'DELETE' THEN (v_old_data->>(TG_ARGV[0]))::VARCHAR
            ELSE (v_new_data->>(TG_ARGV[0]))::VARCHAR
        END,
        v_old_data,
        v_new_data
    );
    
    RETURN NULL; -- para trigger AFTER
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.log_core_audit() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.log_core_audit() IS 'Função para registrar logs de auditoria para tabelas do schema "core". Deve ser chamada com o nome da coluna da PK como primeiro argumento.';

-- Função para registrar auditoria no schema "transactions"
CREATE OR REPLACE FUNCTION public.log_transactions_audit()
RETURNS TRIGGER AS $$
DECLARE
    v_audit_id VARCHAR(50);
    v_old_data JSONB := NULL;
    v_new_data JSONB := NULL;
    v_user_name VARCHAR(200) := current_setting('app.current_user_name', TRUE);
    v_user_id VARCHAR(50) := current_setting('app.current_user_id', TRUE);
    v_app_name VARCHAR(100) := current_setting('app.application_name', TRUE);
    v_ip_address VARCHAR(45) := current_setting('app.client_ip', TRUE);
    v_action auditoria.action_type;
BEGIN
    -- Gerar ID de auditoria (timestamp em microssegundos + 8 caracteres aleatórios)
    v_audit_id := to_char(clock_timestamp(), 'YYYYMMDDHH24MISSUS') || substr(md5(random()::text), 1, 8);
    
    -- Determinar ação e dados
    IF (TG_OP = 'INSERT') THEN
        v_action := 'INSERT'::auditoria.action_type;
        v_new_data := to_jsonb(NEW);
    ELSIF (TG_OP = 'UPDATE') THEN
        v_action := 'UPDATE'::auditoria.action_type;
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
    ELSIF (TG_OP = 'DELETE') THEN
        v_action := 'DELETE'::auditoria.action_type;
        v_old_data := to_jsonb(OLD);
    END IF;
    
    -- Tratar variáveis nulas - usar valores de fallback
    v_user_name := COALESCE(v_user_name, 'system');
    v_user_id := COALESCE(v_user_id, 'system');
    v_app_name := COALESCE(v_app_name, TG_NAME);
    v_ip_address := COALESCE(v_ip_address, '0.0.0.0');

    -- Inserir log na tabela de auditoria de transactions
    INSERT INTO auditoria.transactions_audit_log (
        transactions_audit_log_id,
        transactions_audit_log_timestamp,
        transactions_audit_log_user_id,
        transactions_audit_log_user_name,
        transactions_audit_log_ip_address,
        transactions_audit_log_application,
        transactions_audit_log_action,
        transactions_audit_log_table_name,
        transactions_audit_log_record_id,
        transactions_audit_log_old_data,
        transactions_audit_log_new_data
    ) VALUES (
        v_audit_id,
        clock_timestamp(),
        v_user_id,
        v_user_name,
        v_ip_address,
        v_app_name,
        v_action,
        TG_TABLE_NAME,
        CASE 
            WHEN TG_OP = 'DELETE' THEN (v_old_data->>(TG_ARGV[0]))::VARCHAR
            ELSE (v_new_data->>(TG_ARGV[0]))::VARCHAR
        END,
        v_old_data,
        v_new_data
    );
    
    RETURN NULL; -- para trigger AFTER
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.log_transactions_audit() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.log_transactions_audit() IS 'Função para registrar logs de auditoria para tabelas do schema "transactions". Deve ser chamada com o nome da coluna da PK como primeiro argumento.';

-- Função para calcular saldo de conta
CREATE OR REPLACE FUNCTION public.calculate_account_balance(
    p_user_account_id VARCHAR(50)
)
RETURNS NUMERIC(15,2) AS $$
DECLARE
    v_balance NUMERIC(15,2);
BEGIN
    SELECT COALESCE(SUM(transactions_saldo_total_effective), 0)
    INTO v_balance
    FROM transactions.transactions_saldo
    WHERE transactions_saldo_user_accounts_id = p_user_account_id
      AND transactions_saldo_status = 'Efetuado';

    RETURN v_balance;
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.calculate_account_balance(VARCHAR) OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.calculate_account_balance(VARCHAR) IS 'Calcula o saldo de uma conta específica, considerando todas as transações efetuadas';

-- Função para calcular valor total de uma fatura
CREATE OR REPLACE FUNCTION public.calculate_invoice_amount(
    p_invoice_id VARCHAR(50)
)
RETURNS NUMERIC(15,2) AS $$
DECLARE
    v_amount NUMERIC(15,2);
BEGIN
    -- Calcular com base nas transações diretas
    SELECT COALESCE(SUM(creditcard_transactions_total_effective), 0)
    INTO v_amount
    FROM transactions.creditcard_transactions
    WHERE creditcard_transactions_invoice_id = p_invoice_id;
    
    -- Adicionar o valor das parcelas
    v_amount := v_amount + (
        SELECT COALESCE(SUM(creditcard_installments_total_effective), 0)
        FROM transactions.creditcard_installments
        WHERE creditcard_installments_invoice_id = p_invoice_id
    );
    
    RETURN v_amount;
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.calculate_invoice_amount(VARCHAR) OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.calculate_invoice_amount(VARCHAR) IS 'Calcula o valor total de uma fatura específica somando transações diretas e parcelas de cartão de crédito.';

-- Função para atualizar o status de uma fatura automaticamente
CREATE OR REPLACE FUNCTION public.update_invoice_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Se o valor pago for igual ao valor total da fatura
    IF NEW.creditcard_invoices_paid_amount >= ABS(NEW.creditcard_invoices_amount) AND NEW.creditcard_invoices_amount != 0 THEN
        NEW.creditcard_invoices_status := 'Paga'::transactions.invoice_status;
    -- Se o valor pago for maior que zero mas menor que o valor total
    ELSIF NEW.creditcard_invoices_paid_amount > 0 AND NEW.creditcard_invoices_paid_amount < ABS(NEW.creditcard_invoices_amount) THEN
        NEW.creditcard_invoices_status := 'Paga Parcialmente'::transactions.invoice_status;
    -- Se a fatura estiver fechada e a data de vencimento já passou
    ELSIF NEW.creditcard_invoices_status = 'Fechada' AND NEW.creditcard_invoices_due_date < CURRENT_DATE AND NEW.creditcard_invoices_paid_amount = 0 THEN
        NEW.creditcard_invoices_status := 'Vencida'::transactions.invoice_status;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.update_invoice_status() OWNER TO "SisFinance-adm";
COMMENT ON FUNCTION public.update_invoice_status() IS 'Função de trigger para atualizar automaticamente o status de uma fatura com base no valor pago e data de vencimento.';

-- Aplicar o trigger de status de fatura
CREATE TRIGGER trigger_update_invoice_status
BEFORE UPDATE ON transactions.creditcard_invoices
FOR EACH ROW
WHEN (OLD.creditcard_invoices_amount IS DISTINCT FROM NEW.creditcard_invoices_amount 
   OR OLD.creditcard_invoices_paid_amount IS DISTINCT FROM NEW.creditcard_invoices_paid_amount
   OR OLD.creditcard_invoices_due_date IS DISTINCT FROM NEW.creditcard_invoices_due_date)
EXECUTE FUNCTION public.update_invoice_status();
COMMENT ON TRIGGER trigger_update_invoice_status ON transactions.creditcard_invoices IS 'Atualiza automaticamente o status da fatura quando valores ou data de vencimento são alterados.';

-- =============================================================================
-- CRIAÇÃO DE VIEWS PARA FACILITAR CONSULTAS COMUNS
-- =============================================================================

-- View para visualização de saldos de contas dos usuários
CREATE OR REPLACE VIEW transactions.view_user_account_balances AS
SELECT 
    ua.user_accounts_id,
    u.users_id,
    fi.financial_institutions_name AS bank_name,
    fi.financial_institutions_id AS bank_id,
    at.account_types_name AS account_type, 
    ua.user_accounts_agency AS agency,
    ua.user_accounts_number AS account_number,
    COALESCE(b.balance, 0.00) AS current_balance
FROM 
    core.user_accounts ua
    JOIN core.users u ON ua.user_accounts_user_id = u.users_id
    JOIN core.institution_accounts ia ON ua.user_accounts_institution_account_id = ia.institution_accounts_id
    JOIN core.financial_institutions fi ON ia.institution_accounts_institution_id = fi.financial_institutions_id
    JOIN core.account_types at ON ia.institution_accounts_type_id = at.account_types_id
    LEFT JOIN (
        SELECT 
            transactions_saldo_user_accounts_id,
            SUM(transactions_saldo_total_effective) AS balance
        FROM 
            transactions.transactions_saldo 
        WHERE 
            transactions_saldo_status = 'Efetuado'
        GROUP BY 
            transactions_saldo_user_accounts_id
    ) b ON ua.user_accounts_id = b.transactions_saldo_user_accounts_id
WHERE 
    u.users_status = 'Ativo';

ALTER VIEW transactions.view_user_account_balances OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_user_account_balances IS 'Exibe os saldos atuais de todas as contas de usuários ativos, facilitando a visualização rápida da situação financeira de cada conta.';

-- View para visualização de transações com saldo do mês atual
CREATE OR REPLACE VIEW transactions.view_current_month_transactions AS
SELECT *
FROM transactions.transactions_saldo
WHERE 
    transactions_saldo_implementation_datetime >= date_trunc('month', CURRENT_DATE)
    AND transactions_saldo_implementation_datetime < date_trunc('month', CURRENT_DATE + INTERVAL '1 month');

ALTER VIEW transactions.view_current_month_transactions OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_current_month_transactions IS 'Exibe todas as transações de saldo realizadas no mês atual, filtrando apenas por data de implementação.';

-- View para visualização de transações com saldo realizadas a partir do 1º dia do mês atual.
CREATE OR REPLACE VIEW transactions.view_month_transactions AS
SELECT *
FROM transactions.transactions_saldo
WHERE transactions_saldo_implementation_datetime >= date_trunc('month', CURRENT_DATE);

ALTER VIEW transactions.view_month_transactions OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_month_transactions IS 'Exibe todas as transações de saldo realizadas a partir do início do mês atual.';

-- View para visualização de transações com cartão de crédito do mês atual
CREATE OR REPLACE VIEW transactions.view_current_month_creditcard_transactions AS
SELECT *
FROM transactions.creditcard_transactions
WHERE 
    creditcard_transactions_implementation_datetime >= date_trunc('month', CURRENT_DATE)
    AND creditcard_transactions_implementation_datetime < date_trunc('month', CURRENT_DATE + INTERVAL '1 month');

ALTER VIEW transactions.view_current_month_creditcard_transactions OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_current_month_creditcard_transactions IS 'Exibe todas as transações de cartão de crédito realizadas no mês atual, filtrando apenas por data de implementação.';

-- View para visualização de transações com cartão de crédito realizadas a partir do 1º dia do mês atual.
CREATE OR REPLACE VIEW transactions.view_month_creditcard_transactions AS
SELECT *
FROM transactions.creditcard_transactions
WHERE creditcard_transactions_implementation_datetime >= date_trunc('month', CURRENT_DATE);

ALTER VIEW transactions.view_month_creditcard_transactions OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_month_creditcard_transactions IS 'Exibe todas as transações de cartão de crédito realizadas a partir do início do mês atual.';

-- View para visualização de transações com saldo realizadas por procedimento no mês atual.
CREATE OR REPLACE VIEW transactions.view_current_month_proceeding_totals AS
SELECT 
    ua.user_accounts_user_id AS user_id,
    ps.proceedings_name AS proceeding_name,
    ps.proceedings_id AS proceeding_id,
    SUM(ts.transactions_saldo_total_effective) AS total_amount,
    COUNT(ts.transactions_saldo_id) AS transaction_count
FROM 
    transactions.transactions_saldo ts
    JOIN core.user_accounts ua ON ts.transactions_saldo_user_accounts_id = ua.user_accounts_id
    JOIN core.proceedings_saldo ps ON ts.transactions_saldo_proceeding_id = ps.proceedings_id
WHERE 
    ts.transactions_saldo_status = 'Efetuado'
    AND ts.transactions_saldo_implementation_datetime >= date_trunc('month', CURRENT_DATE)
    AND ts.transactions_saldo_implementation_datetime < date_trunc('month', CURRENT_DATE + INTERVAL '1 month')
GROUP BY 
    ua.user_accounts_user_id, ps.proceedings_id, ps.proceedings_name;
ALTER VIEW transactions.view_current_month_proceeding_totals OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_current_month_proceeding_totals IS 'Exibe a soma dos valores de transações de saldo do mês atual, agrupadas por usuário e procedimento.';

-- View para visualização de transações com saldo realizadas por procedimento no próximo mês.
CREATE OR REPLACE VIEW transactions.view_next_month_proceeding_totals AS
SELECT 
    ua.user_accounts_user_id AS user_id,
    ps.proceedings_name AS proceeding_name,
    ps.proceedings_id AS proceeding_id,
    SUM(ts.transactions_saldo_total_effective) AS total_amount,
    COUNT(ts.transactions_saldo_id) AS transaction_count
FROM 
    transactions.transactions_saldo ts
    JOIN core.user_accounts ua ON ts.transactions_saldo_user_accounts_id = ua.user_accounts_id
    JOIN core.proceedings_saldo ps ON ts.transactions_saldo_proceeding_id = ps.proceedings_id
WHERE 
    ts.transactions_saldo_status = 'Efetuado'
    AND ts.transactions_saldo_implementation_datetime >= date_trunc('month', CURRENT_DATE + INTERVAL '1 month')
    AND ts.transactions_saldo_implementation_datetime < date_trunc('month', CURRENT_DATE + INTERVAL '2 month')
GROUP BY 
    ua.user_accounts_user_id, ps.proceedings_id, ps.proceedings_name;
ALTER VIEW transactions.view_next_month_proceeding_totals OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_next_month_proceeding_totals IS 'Exibe a soma dos valores de transações de saldo do próximo mês, agrupadas por usuário e procedimento.';

-- View para visualização de transações com saldo por procedimento realizadas no total.
CREATE OR REPLACE VIEW transactions.view_all_time_proceeding_totals AS
SELECT 
    ua.user_accounts_user_id AS user_id,
    ps.proceedings_name AS proceeding_name,
    ps.proceedings_id AS proceeding_id,
    SUM(ts.transactions_saldo_total_effective) AS total_amount,
    COUNT(ts.transactions_saldo_id) AS transaction_count,
    MIN(ts.transactions_saldo_implementation_datetime) AS first_transaction_date,
    MAX(ts.transactions_saldo_implementation_datetime) AS last_transaction_date
FROM 
    transactions.transactions_saldo ts
    JOIN core.user_accounts ua ON ts.transactions_saldo_user_accounts_id = ua.user_accounts_id
    JOIN core.proceedings_saldo ps ON ts.transactions_saldo_proceeding_id = ps.proceedings_id
WHERE 
    ts.transactions_saldo_status = 'Efetuado'
GROUP BY 
    ua.user_accounts_user_id, ps.proceedings_id, ps.proceedings_name;
ALTER VIEW transactions.view_all_time_proceeding_totals OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_all_time_proceeding_totals IS 'Exibe a soma total dos valores de transações de saldo de todos os tempos, agrupadas por usuário e procedimento.';

-- View para visualização de transações com saldo e cartão de crédito realizadas por categoria no mês atual.
CREATE OR REPLACE VIEW transactions.view_current_month_category_totals AS
WITH saldo_totals AS (
    SELECT 
        ua.user_accounts_user_id AS user_id,
        c.categories_id AS category_id,
        c.categories_name AS category_name,
        SUM(ts.transactions_saldo_total_effective) AS saldo_amount,
        COUNT(ts.transactions_saldo_id) AS saldo_count
    FROM 
        transactions.transactions_saldo ts
        JOIN core.user_accounts ua ON ts.transactions_saldo_user_accounts_id = ua.user_accounts_id
        JOIN core.categories c ON ts.transactions_saldo_category_id = c.categories_id
    WHERE 
        ts.transactions_saldo_status = 'Efetuado'
        AND ts.transactions_saldo_implementation_datetime >= date_trunc('month', CURRENT_DATE)
        AND ts.transactions_saldo_implementation_datetime < date_trunc('month', CURRENT_DATE + INTERVAL '1 month')
    GROUP BY 
        ua.user_accounts_user_id, c.categories_id, c.categories_name
),
card_totals AS (
    SELECT 
        uc.user_creditcard_user_id AS user_id,
        c.categories_id AS category_id,
        c.categories_name AS category_name,
        SUM(CASE 
            WHEN ct.creditcard_transactions_is_installment = FALSE THEN ct.creditcard_transactions_total_effective
            ELSE 0
        END) AS card_amount,
        COUNT(CASE WHEN ct.creditcard_transactions_is_installment = FALSE THEN 1 ELSE NULL END) AS card_count
    FROM 
        transactions.creditcard_transactions ct
        JOIN transactions.creditcard_invoices inv ON ct.creditcard_transactions_invoice_id = inv.creditcard_invoices_id
        JOIN core.user_creditcard uc ON inv.creditcard_invoices_user_creditcard_id = uc.user_creditcard_id
        JOIN core.categories c ON ct.creditcard_transactions_category_id = c.categories_id
    WHERE 
        ct.creditcard_transactions_status = 'Efetuado'
        AND ct.creditcard_transactions_implementation_datetime >= date_trunc('month', CURRENT_DATE)
        AND ct.creditcard_transactions_implementation_datetime < date_trunc('month', CURRENT_DATE + INTERVAL '1 month')
    GROUP BY 
        uc.user_creditcard_user_id, c.categories_id, c.categories_name
    
    UNION ALL
    
    SELECT 
        uc.user_creditcard_user_id AS user_id,
        c.categories_id AS category_id,
        c.categories_name AS category_name,
        SUM(ci.creditcard_installments_total_effective) AS card_amount,
        COUNT(ci.creditcard_installments_id) AS card_count
    FROM 
        transactions.creditcard_installments ci
        JOIN transactions.creditcard_transactions ct ON ci.creditcard_installments_transaction_id = ct.creditcard_transactions_id
        JOIN transactions.creditcard_invoices inv ON ci.creditcard_installments_invoice_id = inv.creditcard_invoices_id
        JOIN core.user_creditcard uc ON inv.creditcard_invoices_user_creditcard_id = uc.user_creditcard_id
        JOIN core.categories c ON ct.creditcard_transactions_category_id = c.categories_id
    WHERE 
        ct.creditcard_transactions_status = 'Efetuado'
        AND ct.creditcard_transactions_is_installment = TRUE
        AND ci.creditcard_installments_number = 1
        AND ct.creditcard_transactions_implementation_datetime >= date_trunc('month', CURRENT_DATE)
        AND ct.creditcard_transactions_implementation_datetime < date_trunc('month', CURRENT_DATE + INTERVAL '1 month')
    GROUP BY 
        uc.user_creditcard_user_id, c.categories_id, c.categories_name
),
combined_card_totals AS (
    SELECT
        user_id,
        category_id,
        category_name,
        SUM(card_amount) AS card_amount,
        SUM(card_count) AS card_count
    FROM
        card_totals
    GROUP BY
        user_id, category_id, category_name
)
SELECT 
    COALESCE(s.user_id, c.user_id) AS user_id,
    COALESCE(s.category_id, c.category_id) AS category_id,
    COALESCE(s.category_name, c.category_name) AS category_name,
    COALESCE(s.saldo_amount, 0) AS saldo_amount,
    COALESCE(s.saldo_count, 0) AS saldo_count,
    COALESCE(c.card_amount, 0) AS card_amount,
    COALESCE(c.card_count, 0) AS card_count,
    COALESCE(s.saldo_amount, 0) + COALESCE(c.card_amount, 0) AS total_amount
FROM 
    saldo_totals s
    FULL OUTER JOIN combined_card_totals c ON s.user_id = c.user_id AND s.category_id = c.category_id;
ALTER VIEW transactions.view_current_month_category_totals OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_current_month_category_totals IS 'Exibe a soma dos valores de transações de saldo e cartão de crédito do mês atual, agrupadas por categoria e usuário.';

-- View: Totais por categoria no próximo mês (sem nome do usuário)
CREATE OR REPLACE VIEW transactions.view_next_month_category_totals AS
WITH saldo_totals AS (
    SELECT 
        ua.user_accounts_user_id AS user_id,
        c.categories_id AS category_id,
        c.categories_name AS category_name,
        SUM(ts.transactions_saldo_total_effective) AS saldo_amount,
        COUNT(ts.transactions_saldo_id) AS saldo_count
    FROM 
        transactions.transactions_saldo ts
        JOIN core.user_accounts ua ON ts.transactions_saldo_user_accounts_id = ua.user_accounts_id
        JOIN core.categories c ON ts.transactions_saldo_category_id = c.categories_id
    WHERE 
        ts.transactions_saldo_status = 'Efetuado'
        AND ts.transactions_saldo_implementation_datetime >= date_trunc('month', CURRENT_DATE + INTERVAL '1 month')
        AND ts.transactions_saldo_implementation_datetime < date_trunc('month', CURRENT_DATE + INTERVAL '2 month')
    GROUP BY 
        ua.user_accounts_user_id, c.categories_id, c.categories_name
),
card_totals AS (
    SELECT 
        uc.user_creditcard_user_id AS user_id,
        c.categories_id AS category_id,
        c.categories_name AS category_name,
        SUM(CASE 
            WHEN ct.creditcard_transactions_is_installment = FALSE THEN ct.creditcard_transactions_total_effective
            ELSE 0
        END) AS card_amount,
        COUNT(CASE WHEN ct.creditcard_transactions_is_installment = FALSE THEN 1 ELSE NULL END) AS card_count
    FROM 
        transactions.creditcard_transactions ct
        JOIN transactions.creditcard_invoices inv ON ct.creditcard_transactions_invoice_id = inv.creditcard_invoices_id
        JOIN core.user_creditcard uc ON inv.creditcard_invoices_user_creditcard_id = uc.user_creditcard_id
        JOIN core.categories c ON ct.creditcard_transactions_category_id = c.categories_id
    WHERE 
        ct.creditcard_transactions_status = 'Efetuado'
        AND ct.creditcard_transactions_implementation_datetime >= date_trunc('month', CURRENT_DATE + INTERVAL '1 month')
        AND ct.creditcard_transactions_implementation_datetime < date_trunc('month', CURRENT_DATE + INTERVAL '2 month')
    GROUP BY 
        uc.user_creditcard_user_id, c.categories_id, c.categories_name
    
    UNION ALL
    
    SELECT 
        uc.user_creditcard_user_id AS user_id,
        c.categories_id AS category_id,
        c.categories_name AS category_name,
        SUM(ci.creditcard_installments_total_effective) AS card_amount,
        COUNT(ci.creditcard_installments_id) AS card_count
    FROM 
        transactions.creditcard_installments ci
        JOIN transactions.creditcard_transactions ct ON ci.creditcard_installments_transaction_id = ct.creditcard_transactions_id
        JOIN transactions.creditcard_invoices inv ON ci.creditcard_installments_invoice_id = inv.creditcard_invoices_id
        JOIN core.user_creditcard uc ON inv.creditcard_invoices_user_creditcard_id = uc.user_creditcard_id
        JOIN core.categories c ON ct.creditcard_transactions_category_id = c.categories_id
    WHERE 
        ct.creditcard_transactions_status = 'Efetuado'
        AND ct.creditcard_transactions_is_installment = TRUE
        AND inv.creditcard_invoices_due_date >= date_trunc('month', CURRENT_DATE + INTERVAL '1 month')
        AND inv.creditcard_invoices_due_date < date_trunc('month', CURRENT_DATE + INTERVAL '2 month')
    GROUP BY 
        uc.user_creditcard_user_id, c.categories_id, c.categories_name
),
combined_card_totals AS (
    SELECT
        user_id,
        category_id,
        category_name,
        SUM(card_amount) AS card_amount,
        SUM(card_count) AS card_count
    FROM
        card_totals
    GROUP BY
        user_id, category_id, category_name
)
SELECT 
    COALESCE(s.user_id, c.user_id) AS user_id,
    COALESCE(s.category_id, c.category_id) AS category_id,
    COALESCE(s.category_name, c.category_name) AS category_name,
    COALESCE(s.saldo_amount, 0) AS saldo_amount,
    COALESCE(s.saldo_count, 0) AS saldo_count,
    COALESCE(c.card_amount, 0) AS card_amount,
    COALESCE(c.card_count, 0) AS card_count,
    COALESCE(s.saldo_amount, 0) + COALESCE(c.card_amount, 0) AS total_amount
FROM 
    saldo_totals s
    FULL OUTER JOIN combined_card_totals c ON s.user_id = c.user_id AND s.category_id = c.category_id;
ALTER VIEW transactions.view_next_month_category_totals OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_next_month_category_totals IS 'Exibe a soma dos valores de transações de saldo e cartão de crédito do próximo mês, agrupadas por categoria e usuário, incluindo parcelas de cartão que vencem no período.';

-- View: Totais por categoria em todo o período 
CREATE OR REPLACE VIEW transactions.view_all_time_category_totals AS
WITH saldo_totals AS (
    SELECT 
        ua.user_accounts_user_id AS user_id,
        c.categories_id AS category_id,
        c.categories_name AS category_name,
        SUM(ts.transactions_saldo_total_effective) AS saldo_amount,
        COUNT(ts.transactions_saldo_id) AS saldo_count,
        MIN(ts.transactions_saldo_implementation_datetime) AS first_saldo_date,
        MAX(ts.transactions_saldo_implementation_datetime) AS last_saldo_date
    FROM 
        transactions.transactions_saldo ts
        JOIN core.user_accounts ua ON ts.transactions_saldo_user_accounts_id = ua.user_accounts_id
        JOIN core.categories c ON ts.transactions_saldo_category_id = c.categories_id
    WHERE 
        ts.transactions_saldo_status = 'Efetuado'
    GROUP BY 
        ua.user_accounts_user_id, c.categories_id, c.categories_name
),
card_totals AS (
    SELECT 
        uc.user_creditcard_user_id AS user_id,
        c.categories_id AS category_id,
        c.categories_name AS category_name,
        SUM(ct.creditcard_transactions_total_effective) AS card_amount,
        COUNT(ct.creditcard_transactions_id) AS card_count,
        MIN(ct.creditcard_transactions_implementation_datetime) AS first_card_date,
        MAX(ct.creditcard_transactions_implementation_datetime) AS last_card_date
    FROM 
        transactions.creditcard_transactions ct
        JOIN transactions.creditcard_invoices inv ON ct.creditcard_transactions_invoice_id = inv.creditcard_invoices_id
        JOIN core.user_creditcard uc ON inv.creditcard_invoices_user_creditcard_id = uc.user_creditcard_id
        JOIN core.categories c ON ct.creditcard_transactions_category_id = c.categories_id
    WHERE 
        ct.creditcard_transactions_status = 'Efetuado'
    GROUP BY 
        uc.user_creditcard_user_id, c.categories_id, c.categories_name
)
SELECT 
    COALESCE(s.user_id, c.user_id) AS user_id,
    COALESCE(s.category_id, c.category_id) AS category_id,
    COALESCE(s.category_name, c.category_name) AS category_name,
    COALESCE(s.saldo_amount, 0) AS saldo_amount,
    COALESCE(s.saldo_count, 0) AS saldo_count,
    COALESCE(c.card_amount, 0) AS card_amount,
    COALESCE(c.card_count, 0) AS card_count,
    COALESCE(s.saldo_amount, 0) + COALESCE(c.card_amount, 0) AS total_amount,
    LEAST(
        COALESCE(s.first_saldo_date, '9999-12-31'::timestamp with time zone),
        COALESCE(c.first_card_date, '9999-12-31'::timestamp with time zone)
    ) AS first_transaction_date,
    GREATEST(
        COALESCE(s.last_saldo_date, '1900-01-01'::timestamp with time zone),
        COALESCE(c.last_card_date, '1900-01-01'::timestamp with time zone)
    ) AS last_transaction_date
FROM 
    saldo_totals s
    FULL OUTER JOIN card_totals c ON s.user_id = c.user_id AND s.category_id = c.category_id;
ALTER VIEW transactions.view_all_time_category_totals OWNER TO "SisFinance-adm";
COMMENT ON VIEW transactions.view_all_time_category_totals IS 'Exibe a soma total dos valores de transações de saldo e cartão de crédito de todos os tempos, agrupadas por categoria e usuário. Inclui datas da primeira e última transação.';