-- =============================================================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS "SisFinance" COM SCHEMAS
-- =============================================================================
-- Proprietário Padrão dos Objetos: "SisFinance-adm"
-- Nome do Banco de Dados: "SisFinance"
-- Descrição: Banco de dados para o sistema de controle financeiro pessoal SisFinance, abrangendo todas as funcionalidades de gestão de contas, transações em moeda nacional ou estrangeira, cartões de crédito, investimentos e recorrências.

-- =============================================================================
-- CRIAÇÃO DOS SCHEMAS "essencial", "transacional" e "auditoria"
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS essencial;
COMMENT ON SCHEMA essencial IS 'Armazenar as entidades fundamentais do sistema.';
ALTER SCHEMA essencial OWNER TO "SisFinance-adm";

CREATE SCHEMA IF NOT EXISTS transacional;
COMMENT ON SCHEMA transacional IS 'Armazenar as entidades relacionadas a transações financeiras.';
ALTER SCHEMA transacional OWNER TO "SisFinance-adm";

CREATE SCHEMA IF NOT EXISTS auditoria;
COMMENT ON SCHEMA auditoria IS 'Armazenar logs de auditoria das modificações.';
ALTER SCHEMA auditoria OWNER TO "SisFinance-adm";

-- =============================================================================
-- CRIAÇÃO DE FUNÇÃO GENÉRICA PARA PREVER A VALIDAÇÃO DE EMAIL
-- =============================================================================

CREATE OR REPLACE FUNCTION essencial.validar_formato_do_email(email_input TEXT)
RETURNS TEXT AS $$
DECLARE
    clean_email TEXT;
    local_part TEXT;
    domain_part TEXT;
    at_position INTEGER;
BEGIN
    -- Validação de entrada nula ou vazia
    IF email_input IS NULL OR trim(email_input) = '' THEN
        RAISE EXCEPTION 'E-mail inválido: Campo obrigatório não pode estar vazio';
    END IF;
    
    -- Normalização: trim e lowercase
    clean_email := lower(trim(email_input));
    
    -- Verifica comprimento antes de outras validações (otimização de performance)
    IF length(clean_email) > 254 THEN
        RAISE EXCEPTION 'E-mail inválido: Muito longo (máximo 254 caracteres). E-mail informado: %', email_input;
    END IF;
    
    -- Verifica se contém exatamente um @ e divide local/domínio
    at_position := position('@' IN clean_email);
    IF at_position = 0 THEN
        RAISE EXCEPTION 'E-mail inválido: Deve conter o símbolo @. E-mail informado: %', email_input;
    END IF;
    
    -- Conta quantos @ existem (deve ser exatamente 1)
    IF (length(clean_email) - length(replace(clean_email, '@', ''))) > 1 THEN
        RAISE EXCEPTION 'E-mail inválido: Deve conter apenas um símbolo @. E-mail informado: %', email_input;
    END IF;
    
    -- Extrai partes local e domínio
    local_part := substring(clean_email FROM 1 FOR at_position - 1);
    domain_part := substring(clean_email FROM at_position + 1);
    
    -- Validações da parte local (antes do @)
    IF length(local_part) = 0 OR length(local_part) > 64 THEN
        RAISE EXCEPTION 'E-mail inválido: Parte local deve ter entre 1 e 64 caracteres. E-mail informado: %', email_input;
    END IF;
    
    -- Verifica se a parte local não começa ou termina com ponto
    IF local_part ~ '^\.|\.$' THEN
        RAISE EXCEPTION 'E-mail inválido: Parte local não pode começar ou terminar com ponto. E-mail informado: %', email_input;
    END IF;
    
    -- Verifica se não tem pontos consecutivos na parte local
    IF local_part ~ '\.\.' THEN
        RAISE EXCEPTION 'E-mail inválido: Parte local não pode conter pontos consecutivos. E-mail informado: %', email_input;
    END IF;
    
    -- Validações da parte do domínio (após o @)
    IF length(domain_part) = 0 OR length(domain_part) > 253 THEN
        RAISE EXCEPTION 'E-mail inválido: Domínio deve ter entre 1 e 253 caracteres. E-mail informado: %', email_input;
    END IF;
    
    -- Verifica formato da parte local com regex mais específica
    IF NOT (local_part ~ '^[a-z0-9._%-]+$') THEN
        RAISE EXCEPTION 'E-mail inválido: Parte local contém caracteres inválidos. E-mail informado: %', email_input;
    END IF;
    
    -- Verifica formato do domínio com regex mais rigorosa
    IF NOT (domain_part ~ '^[a-z0-9.-]+\.[a-z]{2,}$') THEN
        RAISE EXCEPTION 'E-mail inválido: Formato de domínio incorreto. E-mail informado: %', email_input;
    END IF;
    
    -- Verifica se o domínio não começa ou termina com hífen ou ponto
    IF domain_part ~ '^[-.]|[-.]$' THEN
        RAISE EXCEPTION 'E-mail inválido: Domínio não pode começar ou terminar com hífen ou ponto. E-mail informado: %', email_input;
    END IF;
    
    -- Verifica se não tem pontos ou hífens consecutivos no domínio
    IF domain_part ~ '\.\.|\-\-' THEN
        RAISE EXCEPTION 'E-mail inválido: Domínio não pode conter pontos ou hífens consecutivos. E-mail informado: %', email_input;
    END IF;
    
    RETURN clean_email;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION essencial.validar_formato_do_email(TEXT) IS 'Validação do formato do e-mail para garantir conformidade.';

-- =============================================================================
-- CRIAÇÃO DAS TABELAS DO SCHEMA "essencial"
-- =============================================================================

-- Operacionalização da tabela 'usuarios'

CREATE TYPE essencial.usuario_tipo AS ENUM ('Administrador', 'Usuário');
CREATE TYPE essencial.situacao AS ENUM ('Ativo', 'Inativo', 'Pendente');

CREATE TABLE essencial.usuarios (
    id character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    sobrenome character varying(100) NULL,
    email character varying(255) NOT NULL,
    phone character varying(50) NOT NULL,
    tipo_de_usuario essencial.usuario_tipo NOT NULL,
    situacao essencial.situacao NOT NULL DEFAULT 'Ativo',
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT usuarios_id_pk PRIMARY KEY (id),
    CONSTRAINT usuarios_email_unique UNIQUE (email),
    CONSTRAINT usuarios_verificacao_email CHECK (lower(email) = email)
);
COMMENT ON TABLE essencial.usuarios IS 'Armazena informações sobre os usuários do sistema.';
COMMENT ON COLUMN essencial.usuarios.id IS 'Identificador único e exclusivo para cada usuário (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.usuarios.nome IS 'Primeiro nome do usuário.';
COMMENT ON COLUMN essencial.usuarios.sobrenome IS 'Sobrenome(s) do usuário (opcional).';
COMMENT ON COLUMN essencial.usuarios.email IS 'Endereço de e-mail principal do usuário (único e obrigatório).';
COMMENT ON COLUMN essencial.usuarios.phone IS 'Número de telefone do usuário (obrigatório).';
COMMENT ON COLUMN essencial.usuarios.tipo_de_usuario IS 'Define o papel do usuário no sistema (Administrador ou Usuario), utilizando o tipo ENUM usuario_tipo.';
COMMENT ON COLUMN essencial.usuarios.situacao IS 'Indica o estado atual da conta do usuário (Ativo, Inativo, Pendente), utilizando o tipo ENUM usuario_situacao. Padrão: Ativo.';
COMMENT ON COLUMN essencial.usuarios.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro da instituição foi criado.';
COMMENT ON COLUMN essencial.usuarios.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'categorias'

CREATE TABLE essencial.categorias (
    id character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    credito boolean NOT NULL DEFAULT false,
    debito boolean NOT NULL DEFAULT false,
    CONSTRAINT categorias_id_pk PRIMARY KEY (id),
    CONSTRAINT categorias_nome_unique UNIQUE (nome),
    CONSTRAINT categorias_verificar_credito_debito CHECK (credito IS TRUE OR debito IS TRUE)
);
COMMENT ON TABLE essencial.categorias IS 'Catálogo de categorias para classificar transações e recorrências, indicando se são aplicáveis a operações de crédito, débito ou ambas.';
COMMENT ON COLUMN essencial.categorias.id IS 'Identificador único da categoria (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.categorias.nome IS 'Nome descritivo e único da categoria (Ex: Salário, Moradia).';
COMMENT ON COLUMN essencial.categorias.credito IS 'Indica se esta categoria pode ser associada a operações de Crédito (entrada de valor). Padrão: FALSE.';
COMMENT ON COLUMN essencial.categorias.debito IS 'Indica se esta categoria pode ser associada a operações de Débito (saída de valor). Padrão: FALSE.';

-- Operacionalização da tabela 'procedimentos_saldo'

CREATE TABLE essencial.procedimentos_saldo (
    id character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    credito boolean NOT NULL DEFAULT false,
    debito boolean NOT NULL DEFAULT false,
    transferencias boolean NOT NULL DEFAULT false,
    CONSTRAINT procedimentos_saldo_id_pk PRIMARY KEY (id),
    CONSTRAINT procedimentos_saldo_nome_unique UNIQUE (nome),
    CONSTRAINT procedimentos_saldo_verificar_credito_debito CHECK (credito IS TRUE OR debito IS TRUE)
);
COMMENT ON TABLE essencial.procedimentos_saldo IS 'Catálogo dos métodos ou instrumentos utilizados em transações de saldo (Ex: PIX, Boleto, Compra no Débito).';
COMMENT ON COLUMN essencial.procedimentos_saldo.id IS 'Identificador único do procedimento (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.procedimentos_saldo.nome IS 'Nome descritivo e único do procedimento/método.';
COMMENT ON COLUMN essencial.procedimentos_saldo.credito IS 'Flag booleana que indica se este procedimento pode originar uma operação de Crédito. Padrão: FALSE.';
COMMENT ON COLUMN essencial.procedimentos_saldo.debito IS 'Flag booleana que indica se este procedimento pode originar uma operação de Débito. Padrão: FALSE.';
COMMENT ON COLUMN essencial.procedimentos_saldo.transferencias IS 'Flag booleana que indica se este procedimento pode originar uma transferência. Padrão: FALSE.';

-- Operacionalização da tabela 'instituicoes_financeiras'

CREATE TABLE essencial.instituicoes_financeiras (
    id character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    nome_oficial character varying(255) NOT NULL,
    compensacao char(3) NULL,
    logo_url text NULL,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT instituicoes_financeiras_id_pk PRIMARY KEY (id),
    CONSTRAINT instituicoes_financeiras_nome_unique UNIQUE (nome)
);
COMMENT ON TABLE essencial.instituicoes_financeiras IS 'Catálogo das instituições financeiras (bancos, fintechs, etc.).';
COMMENT ON COLUMN essencial.instituicoes_financeiras.id IS 'Identificador único da instituição (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.instituicoes_financeiras.nome IS 'Nome comum ou fantasia da instituição (único).';
COMMENT ON COLUMN essencial.instituicoes_financeiras.nome_oficial IS 'Nome oficial completo da instituição.';
COMMENT ON COLUMN essencial.instituicoes_financeiras.compensacao IS 'Código de compensação bancária (COMPE), se aplicável.';
COMMENT ON COLUMN essencial.instituicoes_financeiras.logo_url IS 'URL para o logo da instituição (opcional).';
COMMENT ON COLUMN essencial.instituicoes_financeiras.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro da instituição foi criado.';
COMMENT ON COLUMN essencial.instituicoes_financeiras.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'conta_instituicao'

CREATE TYPE essencial.tipos_conta AS ENUM ('Conta Corrente', 'Conta Poupança', 'Conta de Pagamento', 'Conta de Benefícios', 'Conta de Custódia');

CREATE TABLE essencial.conta_instituicao (
    id character varying(50) NOT NULL,
    id_instituicao_financeira character varying(50) NOT NULL,
    tipo_conta essencial.tipos_conta NOT NULL,
    investimentos BOOLEAN NOT NULL DEFAULT TRUE,
    nome character varying(150) NULL,
    processamento text NULL,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT conta_instituicao_id_pk PRIMARY KEY (id),
    CONSTRAINT conta_instituicao_unique UNIQUE (id_instituicao_financeira, tipo_conta),
    CONSTRAINT conta_instituicao_fk_instituicao FOREIGN KEY (id_instituicao_financeira) REFERENCES essencial.instituicoes_financeiras(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT conta_instituicao_verificar_custodia_investimentos CHECK (tipo_conta <> 'Conta de Custódia' OR investimentos IS TRUE);
);
COMMENT ON TABLE essencial.conta_instituicao IS 'Define os "produtos" financeiros específicos oferecidos, ligando uma instituição a um tipo de conta.';
COMMENT ON COLUMN essencial.conta_instituicao.id IS 'Identificador único do produto financeiro (PK, fornecido externamente). Ex: "bb_cc_ouro".';
COMMENT ON COLUMN essencial.conta_instituicao.id_instituicao_financeira IS 'Referência à instituição financeira que oferece este produto (FK para instituicoes_financeiras).';
COMMENT ON COLUMN essencial.conta_instituicao.tipo_conta IS 'Referência ao tipo genérico de conta deste produto (FK para tipo_conta).';
COMMENT ON COLUMN essencial.conta_instituicao.investimentos IS 'Se a conta aceita ou não investimentos.';
COMMENT ON COLUMN essencial.conta_instituicao.nome IS 'Nome específico do produto (Ex: "NuConta", "Conta Fácil"), se diferente do tipo genérico (opcional).';
COMMENT ON COLUMN essencial.conta_instituicao.processamento IS 'Informações sobre horários/dias de processamento para este produto específico (opcional).';
COMMENT ON COLUMN essencial.conta_instituicao.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN essencial.conta_instituicao.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'operadores'

CREATE TABLE essencial.operadores (
    id character varying(50) NOT NULL,
    id_usuario character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    email character varying(255) NULL,
    prioridade boolean NOT NULL DEFAULT false,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT operadores_id_pk PRIMARY KEY (id),
    CONSTRAINT operadores_nome_unique UNIQUE (nome),
    CONSTRAINT operadores_fk_usuario FOREIGN KEY (id_usuario) REFERENCES essencial.usuarios(id) ON DELETE RESTRICT ON UPDATE CASCADE
);
COMMENT ON TABLE essencial.operadores IS 'Cadastro de operadores (pessoas ou sistemas) associados a um usuário, responsáveis por registrar transações.';
COMMENT ON COLUMN essencial.operadores.id IS 'Identificador único do operador (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.operadores.id_usuario IS 'Referência ao usuário do sistema associado a este operador (FK para usuarios.id).';
COMMENT ON COLUMN essencial.operadores.nome IS 'Nome identificador do operador (único).';
COMMENT ON COLUMN essencial.operadores.email IS 'E-mail do operador (até 255 caracteres, pode ser nulo).';
COMMENT ON COLUMN essencial.operadores.prioridade IS 'Indica se este é o operador prioritário ou padrão para o usuário associado.';
COMMENT ON COLUMN essencial.operadores.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN essencial.operadores.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'usuario_contas'

CREATE TABLE essencial.usuario_contas (
    id character varying(50) NOT NULL,
    id_usuario character varying(50) NOT NULL,
    id_conta_instituicao character varying(50) NOT NULL,
    agencia character varying(10) NULL,
    numero character varying(100) NULL,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT usuario_contas_id_pk PRIMARY KEY (id),
    CONSTRAINT usuario_contas_unique UNIQUE (id_usuario, id_conta_instituicao),
    CONSTRAINT usuario_contas_fk_usuario FOREIGN KEY (id_usuario) REFERENCES essencial.usuarios(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT usuario_contas_fk_conta_instituicao FOREIGN KEY (id_conta_instituicao) REFERENCES essencial.conta_instituicao(id) ON DELETE RESTRICT ON UPDATE CASCADE
);
COMMENT ON TABLE essencial.usuario_contas IS 'Associação entre usuários e os produtos financeiros específicos que eles possuem (Ex: a conta corrente específica do Usuário X no Banco Y).';
COMMENT ON COLUMN essencial.usuario_contas.id IS 'Identificador único da associação usuário-produto (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.usuario_contas.id_usuario IS 'Referência ao usuário proprietário desta conta (FK para usuarios).';
COMMENT ON COLUMN essencial.usuario_contas.id_conta_instituicao IS 'Referência ao produto financeiro específico que o usuário possui (FK para conta_instituicao).';
COMMENT ON COLUMN essencial.usuario_contas.agencia IS 'Número da agência bancária associada a esta conta do usuário, se aplicável (opcional).';
COMMENT ON COLUMN essencial.usuario_contas.numero IS 'Número da conta bancária (ou identificador similar) associada a esta conta do usuário, se aplicável (opcional).';
COMMENT ON COLUMN essencial.usuario_contas.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN essencial.usuario_contas.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'contas_chaves_pix'

CREATE TYPE essencial.pix_key_type AS ENUM ('CPF', 'E-mail', 'Telefone', 'Aleatória');

CREATE TABLE essencial.contas_chaves_pix (
    id character varying(50) NOT NULL,
    id_usuario_conta character varying(50) NOT NULL,
    tipo_chave essencial.pix_key_type NOT NULL,
    chave text NOT NULL,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT contas_chaves_pix_id_pk PRIMARY KEY (id),
    CONSTRAINT contas_chaves_pix_unique UNIQUE (id_usuario_conta, chave),
    CONSTRAINT contas_chaves_pix_fk_usuario_conta FOREIGN KEY (id_usuario_conta) REFERENCES essencial.usuario_contas(id) ON DELETE CASCADE ON UPDATE CASCADE
);
COMMENT ON TABLE essencial.contas_chaves_pix IS 'Armazena as chaves PIX individuais associadas a uma conta específica de um usuário (referenciando usuario_contas).';
COMMENT ON COLUMN essencial.contas_chaves_pix.id IS 'Identificador único para esta entrada de chave PIX (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.contas_chaves_pix.id_usuario_conta IS 'Referência à associação usuário-conta específica à qual esta chave PIX pertence (FK para usuario_contas).';
COMMENT ON COLUMN essencial.contas_chaves_pix.tipo_chave IS 'Tipo da chave PIX (CPF, E-mail, Telefone, Aleatória).';
COMMENT ON COLUMN essencial.contas_chaves_pix.chave IS 'A chave PIX em si (e-mail, telefone, CPF/CNPJ, chave aleatória).';
COMMENT ON COLUMN essencial.contas_chaves_pix.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN essencial.contas_chaves_pix.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'cartao_credito'

CREATE TABLE essencial.cartao_credito (
    id character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    bandeira character varying(150) NOT NULL,
    id_instituicao_financeira character varying(50) NOT NULL,
    adiamento_dia_util boolean NOT NULL DEFAULT true,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT cartao_credito_id_pk PRIMARY KEY (id),
    CONSTRAINT cartao_credito_nome_unique UNIQUE (nome, id_instituicao_financeira),
    CONSTRAINT cartao_credito_fk_instituicao FOREIGN KEY (id_instituicao_financeira) REFERENCES essencial.instituicoes_financeiras(id) ON DELETE RESTRICT ON UPDATE CASCADE
);
COMMENT ON TABLE essencial.cartao_credito IS 'Catálogo dos produtos de cartão de crédito oferecidos pelas instituições financeiras.';
COMMENT ON COLUMN essencial.cartao_credito.id IS 'Identificador único do produto cartão de crédito (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.cartao_credito.nome IS 'Nome comercial do cartão de crédito (Ex: Platinum, Gold).';
COMMENT ON COLUMN essencial.cartao_credito.bandeira IS 'Bandeira do cartão (Ex: Visa, Mastercard, Elo).';
COMMENT ON COLUMN essencial.cartao_credito.id_instituicao_financeira IS 'Referência à instituição financeira emissora do cartão (FK para instituicoes_financeiras).';
COMMENT ON COLUMN essencial.cartao_credito.adiamento_dia_util IS 'Indica se o vencimento da fatura é adiado para o próximo dia útil caso caia em dia não útil. Padrão: TRUE.';
COMMENT ON COLUMN essencial.cartao_credito.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN essencial.cartao_credito.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'usuario_cartao_credito'

CREATE TYPE essencial.metodo_pagamento_cartao AS ENUM ('Débito Automático', 'Boleto Bancário');

CREATE TABLE essencial.usuario_cartao_credito (
    id character varying(50) NOT NULL,
    id_cartao_credito character varying(50) NOT NULL,
    id_usuario_conta character varying(50) NOT NULL,
    metodo_de_pagamento essencial.metodo_pagamento_cartao NOT NULL,
    fechamento integer NOT NULL CHECK (fechamento >= 1 AND fechamento <= 31),
    vencimento integer NOT NULL CHECK (vencimento >= 1 AND vencimento <= 31),
    limite numeric(15, 2) NOT NULL DEFAULT 0,
    situacao boolean NOT NULL DEFAULT true,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT usuario_cartao_credito_id_pk PRIMARY KEY (id),
    CONSTRAINT usuario_cartao_credito_unique UNIQUE (id_usuario_conta, id_cartao_credito),
    CONSTRAINT usuario_cartao_credito_fk_cartao FOREIGN KEY (id_cartao_credito) REFERENCES essencial.cartao_credito(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT usuario_cartao_credito_fk_usuario_conta FOREIGN KEY (id_usuario_conta) REFERENCES essencial.usuario_contas(id) ON DELETE CASCADE ON UPDATE CASCADE
);
COMMENT ON TABLE essencial.usuario_cartao_credito IS 'Associação entre usuários e os cartões de crédito que possuem, definindo limites, forma de pagamento e status.';
COMMENT ON COLUMN essencial.usuario_cartao_credito.id IS 'Identificador único da associação usuário-cartão (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.usuario_cartao_credito.id_cartao_credito IS 'Referência ao produto cartão de crédito que o usuário possui (FK para cartao_credito).';
COMMENT ON COLUMN essencial.usuario_cartao_credito.id_usuario_conta IS 'Referência à conta do usuário usada para pagar a fatura deste cartão (FK para usuario_contas).';
COMMENT ON COLUMN essencial.usuario_cartao_credito.metodo_de_pagamento IS 'Forma de pagamento da fatura deste cartão (Débito Automático ou Boleto Bancário).';
COMMENT ON COLUMN essencial.usuario_cartao_credito.fechamento IS 'Dia do mês em que a fatura deste cartão fecha (1-31).';
COMMENT ON COLUMN essencial.usuario_cartao_credito.vencimento IS 'Dia do mês em que a fatura deste cartão vence (1-31).';
COMMENT ON COLUMN essencial.usuario_cartao_credito.limite IS 'Limite de crédito do usuário neste cartão. Padrão: 0.';
COMMENT ON COLUMN essencial.usuario_cartao_credito.situacao IS 'Status do cartão para este usuário (TRUE = Ativo, FALSE = Desativado/Cancelado). Padrão: TRUE.';
COMMENT ON COLUMN essencial.usuario_cartao_credito.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN essencial.usuario_cartao_credito.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'indexadores_investimentos'

CREATE TABLE essencial.indexadores_investimentos (
    id character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT indexadores_investimentos_pk PRIMARY KEY (id),
    CONSTRAINT indexadores_investimentos_unique UNIQUE (nome)
);
COMMENT ON TABLE essencial.indexadores_investimentos IS 'Catálogo de indexadores para investimentos em renda fixa.';
COMMENT ON COLUMN essencial.indexadores_investimentos.id IS 'Identificador único da associação usuário-cartão (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.indexadores_investimentos.nome IS 'Nome do índice de referência (ex: CDI, IPCA).';
COMMENT ON COLUMN essencial.indexadores_investimentos.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN essencial.indexadores_investimentos.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'historico_indexadores_investimentos'

CREATE TABLE essencial.indexadores_investimentos_historico (
    id character varying(50) NOT NULL,
    id_indexadores_investimentos character varying(50) NOT NULL,
    data_referencia date NOT NULL,
    valor numeric(15,6) NOT NULL,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT indexadores_investimentos_historico_pk PRIMARY KEY (id),
    CONSTRAINT indexadores_investimentos_historico_fk_indexadores_investimentos FOREIGN KEY (id_indexadores_investimentos) REFERENCES essencial.indexadores_investimentos(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT indexadores_investimentos_historico_unique UNIQUE (id_indexadores_investimentos, data_referencia),
);
COMMENT ON TABLE essencial.indexadores_investimentos_historico IS 'Histórico de valores dos índices de referência.';
COMMENT ON COLUMN essencial.indexadores_investimentos_historico.id IS 'Identificador único do registro histórico (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.indexadores_investimentos_historico.id_indexadores_investimentos IS 'Referência ao índice (FK para investment_indexes).';
COMMENT ON COLUMN essencial.indexadores_investimentos_historico.data_referencia IS 'Data do valor registrado.';
COMMENT ON COLUMN essencial.indexadores_investimentos_historico.valor IS 'Valor do índice na data especificada.';
COMMENT ON COLUMN essencial.indexadores_investimentos_historico.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN essencial.indexadores_investimentos_historico.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'emissores_renda_fixa'

CREATE TABLE essencial.emissores_renda_fixa (
    id character varying(50) NOT NULL,
    nome text NOT NULL,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT emissores_renda_fixa_pk PRIMARY KEY (id),
    CONSTRAINT emissores_renda_fixa_unique UNIQUE (nome)
);
COMMENT ON TABLE essencial.emissores_renda_fixa IS 'Catálogo de emissores de investimentos de renda fixa.';
COMMENT ON COLUMN essencial.emissores_renda_fixa.id IS 'Identificador único do emissor (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.emissores_renda_fixa.nome IS 'Nome do emissor (ex: Tesouro Nacional, Banco do Brasil).';
COMMENT ON COLUMN essencial.emissores_renda_fixa.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN essencial.emissores_renda_fixa.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'tipos_renda_variavel'

CREATE TABLE essencial.tipos_renda_variavel (
    id character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text NOT NULL,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT tipos_renda_variavel_pk PRIMARY KEY (id),
    CONSTRAINT tipos_renda_variavel_unique UNIQUE (nome, descricao)
);
COMMENT ON TABLE essencial.tipos_renda_variavel IS 'Armazena os diferentes tipos de renda variável disponíveis, com nome e descrição.';

COMMENT ON COLUMN essencial.tipos_renda_variavel.id IS 'Identificador único do tipo de renda variável (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.tipos_renda_variavel.nome IS 'Nome do tipo de renda variável, deve ser único em combinação com a descrição.';
COMMENT ON COLUMN essencial.tipos_renda_variavel.descricao IS 'Descrição detalhada do tipo de renda variável, deve ser única em combinação com o nome.';
COMMENT ON COLUMN essencial.tipos_renda_variavel.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN essencial.tipos_renda_variavel.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'bolsas_de_valores'

CREATE TABLE essencial.bolsas_de_valores (
    id character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao character varying(100),
    CONSTRAINT bolsas_de_valores_pk PRIMARY KEY (id),
    CONSTRAINT bolsas_de_valores_unique UNIQUE (nome)
);
COMMENT ON TABLE essencial.bolsas_de_valores IS 'Armazena as informações sobre as bolsas de valores disponíveis, incluindo nome e descrição.';

COMMENT ON COLUMN essencial.bolsas_de_valores.id IS 'Identificador único da bolsa de valores (PK, fornecido externamente).';
COMMENT ON COLUMN essencial.bolsas_de_valores.nome IS 'Nome da bolsa de valores, deve ser único.';
COMMENT ON COLUMN essencial.bolsas_de_valores.descricao IS 'Descrição adicional ou informativa sobre a bolsa de valores (opcional).';


-- =============================================================================
-- CRIAÇÃO DAS TABELAS DO SCHEMA "transacional"  relacionadas à transações
-- =============================================================================

-- Operacionalização da tabela 'descricao'

CREATE TABLE transacional.descricao (
    id character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    observacoes text,
    CONSTRAINT descricao_id_pk PRIMARY KEY (id)
);
COMMENT ON TABLE transacional.descricao IS 'Catálogo de descrições detalhadas para transações, recorrências e lançamentos.';
COMMENT ON COLUMN transacional.descricao.id IS 'Identificador único da descrição (PK, fornecido externamente).';
COMMENT ON COLUMN transacional.descricao.nome IS 'Nome ou título da descrição.';
COMMENT ON COLUMN transacional.descricao.observacoes IS 'Observações adicionais à descrição.';

-- Operacionalização da tabela 'transacoes_recorrentes_saldo'

CREATE TYPE transacional.operacao AS ENUM ('Crédito', 'Débito');
CREATE TYPE transacional.tipo_recorrencia AS ENUM ('Prazo Determinado', 'Prazo Indeterminado');
CREATE TYPE transacional.periodicidade AS ENUM ('Semanal', 'Mensal', 'Bimestral', 'Trimestral', 'Semestral', 'Anual');

CREATE TABLE transacional.transacoes_recorrentes_saldo (
    id character varying(50) NOT NULL,
    id_usuario_conta character varying(50) NOT NULL,
    id_operador character varying(50) NOT NULL,
    id_procedimento character varying(50) NOT NULL,
    id_categoria character varying(50) NOT NULL,
    id_descricao character varying(50) NOT NULL,
    situacao essencial.situacao NOT NULL DEFAULT 'Ativo',
    tipo_recorrencia transacional.tipo_recorrencia NOT NULL,
    periodicidade transacional.periodicidade NOT NULL,
    vencimento_padrao integer,
    primeiro_vencimento date NOT NULL,
    ultimo_vencimento date,
    adiamento_por_dia_util boolean NOT NULL DEFAULT false,
    termos_servico text,
    relevancia_ir boolean NOT NULL DEFAULT false,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transacoes_recorrentes_saldo_id_pk PRIMARY KEY (id),
    CONSTRAINT transacoes_recorrentes_saldo_fk_usuario_conta FOREIGN KEY (id_usuario_conta) REFERENCES essencial.usuario_contas(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_recorrentes_saldo_fk_procedimento FOREIGN KEY (id_procedimento) REFERENCES essencial.procedimentos_saldo(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_recorrentes_saldo_fk_categoria FOREIGN KEY (id_categoria) REFERENCES essencial.categorias(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_recorrentes_saldo_fk_operador FOREIGN KEY (id_operador) REFERENCES essencial.operadores(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_recorrentes_saldo_fk_descricao FOREIGN KEY (id_descricao) REFERENCES transacional.descricao(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_recorrentes_saldo_verificar_vencimento_padrao CHECK (vencimento_padrao IS NULL OR (vencimento_padrao >= 1 AND vencimento_padrao <= 31)),
    CONSTRAINT transacoes_recorrentes_saldo_verificar_vencimento_obrigatorio CHECK (periodicidade = 'Semanal' OR vencimento_padrao IS NOT NULL),
    CONSTRAINT transacoes_recorrentes_saldo_verificar_logica_data_final CHECK (ultimo_vencimento IS NULL OR ultimo_vencimento >= primeiro_vencimento),
    CONSTRAINT transacoes_recorrentes_saldo_verificar_data_final_obrigatoria CHECK (tipo_recorrencia = 'Prazo Indeterminado' OR ultimo_vencimento IS NOT NULL)
);
COMMENT ON TABLE transacional.transacoes_recorrentes_saldo IS 'Armazena os modelos/agendamentos de transações financeiras de saldo recorrentes.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.id IS 'Identificador único da recorrência de saldo (PK, fornecido externamente).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.id_usuario_conta IS 'Referência à associação usuário-conta específica afetada pela recorrência (FK para usuario_contas).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.id_procedimento IS 'Procedimento/método padrão das transações recorrentes (FK para procedimentos_saldo).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.id_categoria IS 'Categoria padrão das transações recorrentes (FK para categorias).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.id_operador IS 'Operador padrão associado às transações desta recorrência (FK para operadores).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.situacao IS 'Status atual da recorrência (Ativo ou Inativo).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.id_descricao IS 'Descrição padrão para as transações geradas por esta recorrência.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.tipo_recorrencia IS 'Tipo de recorrência (Prazo Determinado com data final, ou Prazo Indeterminado).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.periodicidade IS 'Frequência com que a transação deve ocorrer (Semanal, Mensal, etc.).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.vencimento_padrao IS 'Dia preferencial do mês para vencimento (1-31), obrigatório se a frequência não for Semanal (opcional).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.primeiro_vencimento IS 'Data do primeiro vencimento ou da primeira ocorrência desta recorrência.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.ultimo_vencimento IS 'Data do último vencimento ou da última ocorrência (para tipo Prazo Determinado) (opcional).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.adiamento_por_dia_util IS 'Indica se o vencimento, caso caia em dia não útil, deve ser adiado para o próximo dia útil. Padrão: FALSE.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.termos_servico IS 'Termos de serviço ou informações contratuais para esta recorrência.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.relevancia_ir IS 'Indica se as transações geradas por esta recorrência são relevantes para declaração de Imposto de Renda. Padrão: FALSE.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_saldo.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'transacoes_recorrentes_saldo_valores'

CREATE TYPE transacional.categoria_valores AS ENUM ('Base','Imposto','Desconto','Taxa Diversa','Juros','Multa','Reembolso','Seguro','Acréscimo','Retenção','Serviço','Bônus','Antecipação','Estorno');

CREATE TABLE transacional.transacoes_recorrentes_saldo_valores (
    id character varying(50) NOT NULL,
    id_transacoes_recorrentes_saldo character varying(50) NOT NULL,
    operacao transacional.operacao NOT NULL,
    categoria transacional.categoria_valores NOT NULL DEFAULT 'Base',
    observacoes text,
    valor numeric(15, 2) NOT NULL,
    CONSTRAINT transacoes_recorrentes_saldo_valores_id_pk PRIMARY KEY (id),
    CONSTRAINT transacoes_recorrentes_saldo_valores_fk_transacoes_recorrentes_saldo FOREIGN KEY (id_transacoes_recorrentes_saldo) REFERENCES transacional.transacoes_recorrentes_saldo(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE OR REPLACE FUNCTION transacional.transacoes_recorrentes_saldo_valores_iniciais()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT'
    THEN
        
        INSERT INTO transacional.transacoes_recorrentes_saldo_valores (
            id,
            id_transacoes_recorrentes_saldo,
            operacao,
            data_efetivacao,
            valor
        ) VALUES (
            NEW.id || '1',
            NEW.id,
            'Crédito',
            NEW.data_efetivacao,
            '0.00'
        );

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER transacoes_recorrentes_saldo_valores_iniciais
AFTER INSERT ON transacional.transacoes_recorrentes_saldo
FOR EACH ROW EXECUTE FUNCTION transacional.transacoes_recorrentes_saldo_valores_iniciais();

-- Operacionalização da tabela 'transacoes_saldo'

CREATE TYPE transacional.situacao AS ENUM ('Efetuado', 'Pendente', 'Reembolsado');

CREATE TABLE transacional.transacoes_saldo (
    id character varying(50) NOT NULL,
    id_usuario_conta character varying(50) NOT NULL,
    id_operador character varying(50) NOT NULL,
    id_procedimento character varying(50) NOT NULL,
    id_categoria character varying(50) NOT NULL,
    id_descricao character varying(50) NOT NULL,
    situacao transacional.situacao NOT NULL DEFAULT 'Efetuado',
    data_programada timestamp with time zone,
    data_efetivacao timestamp with time zone,
    termos_servico text,
    comprovante text,
    nota_fiscal text,
    relevancia_ir boolean NOT NULL DEFAULT false,
    observacoes text,
    id_recorrencia character varying(50),
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transacoes_saldo_id_pk PRIMARY KEY (id),
    CONSTRAINT transacoes_saldo_fk_usuario_conta FOREIGN KEY (id_usuario_conta) REFERENCES essencial.usuario_contas(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_saldo_fk_procedimento FOREIGN KEY (id_procedimento) REFERENCES essencial.procedimentos_saldo(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_saldo_fk_categoria FOREIGN KEY (id_categoria) REFERENCES essencial.categorias(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_saldo_fk_operador FOREIGN KEY (id_operador) REFERENCES essencial.operadores(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_saldo_fk_descricao FOREIGN KEY (id_descricao) REFERENCES transacional.descricao(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_saldo_fk_recorrencia FOREIGN KEY (id_recorrencia) REFERENCES transacional.transacoes_recorrentes_saldo(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT transacoes_saldo_verificar_data_efetivacao_maior_igual_programada CHECK (data_programada IS NULL OR data_efetivacao >= data_programada),
    CONSTRAINT transacoes_saldo_verificar_efetivacao_nao_pendente CHECK ((situacao = 'Pendente' AND data_efetivacao IS NULL) OR (situacao <> 'Pendente' AND data_efetivacao IS NOT NULL))
);
COMMENT ON TABLE transacional.transacoes_saldo IS 'Armazena registros de transações financeiras de saldo realizadas no sistema.';
COMMENT ON COLUMN transacional.transacoes_saldo.id IS 'Identificador único da transação de saldo (PK, fornecido externamente).';
COMMENT ON COLUMN transacional.transacoes_saldo.id_usuario_conta IS 'Referência à associação usuário-conta específica afetada por esta transação (FK para usuario_contas).';
COMMENT ON COLUMN transacional.transacoes_saldo.id_operador IS 'Operador associado à transação de saldo (FK para operadores).';
COMMENT ON COLUMN transacional.transacoes_saldo.id_procedimento IS 'Procedimento/método da transação de saldo (FK para procedimentos_saldo).';
COMMENT ON COLUMN transacional.transacoes_saldo.id_categoria IS 'Categoria da transação de saldo (FK para categorias).';
COMMENT ON COLUMN transacional.transacoes_saldo.id_descricao IS 'Descrição associada à transação de saldo (opcional, FK para descricao).';
COMMENT ON COLUMN transacional.transacoes_saldo.situacao IS 'Status atual da transação (por exemplo: Efetuado, Pendente, Cancelado).';
COMMENT ON COLUMN transacional.transacoes_saldo.data_programada IS 'Data e hora programadas para a transação de saldo (opcional).';
COMMENT ON COLUMN transacional.transacoes_saldo.data_efetivacao IS 'Data e hora em que a transação de saldo foi efetivada no sistema.';
COMMENT ON COLUMN transacional.transacoes_saldo.termos_servico IS 'Termos de serviço ou informações contratuais relacionadas à transação.';
COMMENT ON COLUMN transacional.transacoes_saldo.comprovante IS 'Informações ou referência ao comprovante da transação de saldo (opcional).';
COMMENT ON COLUMN transacional.transacoes_saldo.nota_fiscal IS 'Informações ou referência à nota fiscal associada à transação de saldo (opcional).';
COMMENT ON COLUMN transacional.transacoes_saldo.relevancia_ir IS 'Indica se a transação de saldo é relevante para declaração de Imposto de Renda. Padrão: FALSE.';
COMMENT ON COLUMN transacional.transacoes_saldo.observacoes IS 'Observações adicionais ou informações complementares sobre a transação de saldo.';
COMMENT ON COLUMN transacional.transacoes_saldo.id_recorrencia IS 'Referência à recorrência responsável por esta transação (opcional, FK para transacoes_recorrentes_saldo).';
COMMENT ON COLUMN transacional.transacoes_saldo.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN transacional.transacoes_saldo.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'transacoes_saldo_valores'

CREATE TABLE transacional.transacoes_saldo_valores (
    id character varying(50) NOT NULL,
    id_transacoes_saldo character varying(50) NOT NULL,
    operacao transacional.operacao NOT NULL,
    data_efetivacao timestamp with time zone NOT NULL,
    categoria transacional.categoria_valores NOT NULL DEFAULT 'Base',
    observacoes text,
    valor numeric(15, 2) NOT NULL,
    CONSTRAINT transacoes_saldo_valores_id_pk PRIMARY KEY (id),
    CONSTRAINT transacoes_saldo_valores_fk_transacoes_recorrentes_saldo FOREIGN KEY (id_transacoes_saldo) REFERENCES transacional.transacoes_saldo(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE OR REPLACE FUNCTION transacional.transacoes_saldo_valores_iniciais()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT'
    THEN
        
        INSERT INTO transacional.transacoes_saldo_valores (
            id,
            id_transacoes_saldo,
            operacao,
            data_efetivacao,
            valor
        ) VALUES (
            NEW.id || '1',
            NEW.id,
            'Crédito',
            NEW.data_efetivacao,
            '0.00'
        );

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER transacoes_saldo_valores_iniciais
AFTER INSERT ON transacional.transacoes_saldo
FOR EACH ROW EXECUTE FUNCTION transacional.transacoes_saldo_valores_iniciais();

-- Operacionalização da tabela 'transacoes_saldo'

CREATE TABLE transacional.transferencias_internas (
    id character varying(50) NOT NULL,
    id_usuario_conta_origem character varying(50) NOT NULL,
    id_usuario_conta_destino character varying(50) NOT NULL,
    id_operador character varying(50) NOT NULL,
    id_procedimento character varying(50) NOT NULL,
    situacao transacional.situacao NOT NULL DEFAULT 'Efetuado',
    data_programada timestamp with time zone,
    data_efetivacao timestamp with time zone,
    comprovante text,
    observacoes text,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transferencias_internas_id_pk PRIMARY KEY (id),
    CONSTRAINT transferencias_internas_fk_usuario_conta_origem FOREIGN KEY (id_usuario_conta_origem) REFERENCES essencial.usuario_contas(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transferencias_internas_fk_usuario_conta_destino FOREIGN KEY (id_usuario_conta_destino) REFERENCES essencial.usuario_contas(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transferencias_internas_fk_procedimento FOREIGN KEY (id_procedimento) REFERENCES essencial.procedimentos_saldo(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transferencias_internas_fk_operador FOREIGN KEY (id_operador) REFERENCES essencial.operadores(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transferencias_internas_verificar_data_efetivacao_maior_igual_programada CHECK (data_programada IS NULL OR data_efetivacao >= data_programada),
    CONSTRAINT transferencias_internas_verificar_efetivacao_nao_pendente CHECK ((situacao = 'Pendente' AND data_efetivacao IS NULL) OR (situacao <> 'Pendente' AND data_efetivacao IS NOT NULL)),
    CONSTRAINT transferencias_internas_verificar_contas_diferentes CHECK (id_usuario_conta_origem <> id_usuario_conta_destino)
);
COMMENT ON TABLE transacional.transferencias_internas IS 'Armazena registros de transações financeiras de saldo realizadas no sistema.';
COMMENT ON COLUMN transacional.transferencias_internas.id IS 'Identificador único da transação de saldo (PK, fornecido externamente).';
COMMENT ON COLUMN transacional.transferencias_internas.id_usuario_conta_origem IS 'Referência à associação usuário-conta específica de origem afetada por esta transação (FK para usuario_contas).';
COMMENT ON COLUMN transacional.transferencias_internas.id_usuario_conta_destino IS 'Referência à associação usuário-conta específica de destino afetada por esta transação (FK para usuario_contas).';
COMMENT ON COLUMN transacional.transferencias_internas.id_operador IS 'Operador associado à transação de saldo (FK para operadores).';
COMMENT ON COLUMN transacional.transferencias_internas.id_procedimento IS 'Procedimento/método da transação de saldo (FK para procedimentos_saldo).';
COMMENT ON COLUMN transacional.transferencias_internas.situacao IS 'Status atual da transação (por exemplo: Efetuado, Pendente, Cancelado).';
COMMENT ON COLUMN transacional.transferencias_internas.data_programada IS 'Data e hora programadas para a transação de saldo (opcional).';
COMMENT ON COLUMN transacional.transferencias_internas.data_efetivacao IS 'Data e hora em que a transação de saldo foi efetivada no sistema.';
COMMENT ON COLUMN transacional.transferencias_internas.comprovante IS 'Informações ou referência ao comprovante da transação de saldo (opcional).';
COMMENT ON COLUMN transacional.transferencias_internas.observacoes IS 'Observações adicionais ou informações complementares sobre a transação de saldo.';
COMMENT ON COLUMN transacional.transferencias_internas.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN transacional.transferencias_internas.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Trigger para garantir que o procedimento permite transferências

CREATE OR REPLACE FUNCTION transacional.verificar_procedimento_transferencia()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM essencial.procedimentos_saldo
        WHERE id = NEW.id_procedimento
          AND transferencias = TRUE
    ) THEN
        RAISE EXCEPTION 'O procedimento escolhido não permite transferências.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER transferencias_internas_verificar_procedimento
BEFORE INSERT OR UPDATE ON transacional.transferencias_internas
FOR EACH ROW
EXECUTE FUNCTION transacional.verificar_procedimento_transferencia();

-- Operacionalização da tabela 'transferencias_internas_valores'

CREATE TABLE transacional.transferencias_internas_valores (
    id character varying(50) NOT NULL,
    id_transferencias_internas character varying(50) NOT NULL,
    operacao transacional.operacao NOT NULL,
    data_efetivacao timestamp with time zone NOT NULL,
    categoria transacional.categoria_valores NOT NULL DEFAULT 'Base',
    observacoes text,
    valor numeric(15, 2) NOT NULL,
    CONSTRAINT transferencias_internas_valores_id_pk PRIMARY KEY (id),
    CONSTRAINT transferencias_internas_valores_fk_transacoes_recorrentes_saldo FOREIGN KEY (id_transferencias_internas) REFERENCES transacional.transferencias_internas(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Trigger para garantir a criação e alteração de dados de Transferências Internas na tabela 'transacoes_saldo'

INSERT INTO essencial.categorias (id, nome, credito, debito)
VALUES ('transferencias_internas', 'Transferências Internas', TRUE, TRUE);

INSERT INTO transacional.descricao (id, nome, observacoes)
VALUES ('transferencias_internas', 'Transferência Interna', 'Descrição padrão para transferências entre contas do mesmo usuário ou entre usuários do sistema.');

CREATE OR REPLACE FUNCTION transacional.transferencia_interna_sincronizacao()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' 
    THEN
        
        IF TG_OP = 'UPDATE' THEN
            DELETE FROM transacional.transacoes_saldo WHERE id IN (OLD.id || '-D', OLD.id || '-C');
        END IF;
        
        INSERT INTO transacional.transacoes_saldo (
            id,
            id_usuario_conta,
            id_operador,
            id_procedimento,
            id_categoria,
            id_descricao,
            situacao,
            data_programada,
            data_efetivacao,
            comprovante,
            observacoes,
            relevancia_ir,
            datahora_criacao,
            datahora_atualizacao
        ) VALUES (
            NEW.id || '-D',
            NEW.id_usuario_conta_origem,
            NEW.id_operador,
            NEW.id_procedimento,
            'transferencias_internas',
            'transferencias_internas',
            NEW.situacao,
            NEW.data_programada,
            NEW.data_efetivacao,
            NEW.comprovante,
            NEW.observacoes,
            false,
            NEW.datahora_criacao,
            NEW.datahora_atualizacao
        );
        
        INSERT INTO transacional.transacoes_saldo (
            id,
            id_usuario_conta,
            id_operador,
            id_procedimento,
            id_categoria,
            id_descricao,
            situacao,
            data_programada,
            data_efetivacao,
            comprovante,
            observacoes,
            relevancia_ir,
            datahora_criacao,
            datahora_atualizacao
        ) VALUES (
            NEW.id || '-C',
            NEW.id_usuario_conta_destino,
            NEW.id_operador,
            NEW.id_procedimento,
            'transferencias_internas',
            'transferencias_internas',
            NEW.situacao,
            NEW.data_programada,
            NEW.data_efetivacao,
            NEW.comprovante,
            NEW.observacoes,
            false,
            NEW.datahora_criacao,
            NEW.datahora_atualizacao
        );
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        DELETE FROM transacional.transacoes_saldo WHERE id IN (OLD.id || '-D', OLD.id || '-C');
        RETURN OLD;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sincronizacao_transferencias_internas
AFTER INSERT OR UPDATE OR DELETE ON transacional.transferencias_internas
FOR EACH ROW EXECUTE FUNCTION transacional.transferencia_interna_sincronizacao();

CREATE OR REPLACE FUNCTION transacional.transferencia_interna_sincronizacao_valores()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        IF TG_OP = 'UPDATE' THEN
            DELETE FROM transacional.transacoes_saldo_valores 
            WHERE id IN (OLD.id || '-D', OLD.id || '-C');
        END IF;
        
        INSERT INTO transacional.transacoes_saldo_valores (
            id,
            id_transacoes_saldo,
            operacao,
            data_efetivacao,
            observacoes,
            valor
        ) VALUES (
            NEW.id || '-D',
            NEW.id_transferencias_internas || '-D',
            'Débito',
            NEW.data_efetivacao,
            NEW.observacoes,
            NEW.valor
        );
        
        INSERT INTO transacional.transacoes_saldo_valores (
            id,
            id_transacoes_saldo,
            operacao,
            data_efetivacao,
            observacoes,
            valor
        ) VALUES (
            NEW.id || '-C',
            NEW.id_transferencias_internas || '-C',
            'Crédito',
            NEW.data_efetivacao,
            NEW.observacoes,
            NEW.valor
        );
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        DELETE FROM transacional.transacoes_saldo_valores 
        WHERE id IN (OLD.id || '-D', OLD.id || '-C');
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER sincronizacao_transferencias_internas_valores
AFTER INSERT OR UPDATE OR DELETE ON transacional.transferencias_internas_valores
FOR EACH ROW EXECUTE FUNCTION transacional.transferencia_interna_sincronizacao_valores();

-- Operacionalização da tabela 'faturas_cartao_credito'

CREATE TYPE transacional.situacao_fatura AS ENUM ('Aberta', 'Fechada', 'Paga', 'Paga Parcialmente', 'Vencida');

CREATE TABLE transacional.faturas_cartao_credito (
    id character varying(50) NOT NULL,
    id_usuario_cartao_credito character varying(50) NOT NULL,
    abertura date NOT NULL,
    fechamento date NOT NULL,
    vencimento date NOT NULL,
    valor numeric(15, 2) NOT NULL DEFAULT 0,
    valor_pago numeric(15, 2) NOT NULL DEFAULT 0,
    data_de_pagamento date,
    situacao transacional.situacao_fatura NOT NULL DEFAULT 'Aberta',
    fatura text,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT faturas_cartao_credito_pk PRIMARY KEY (id),
    CONSTRAINT faturas_cartao_credito_fk_usuario_cartao_credito FOREIGN KEY (id_usuario_cartao_credito) REFERENCES essencial.usuario_cartao_credito(id) ON DELETE RESTRICT ON UPDATE CASCADE
);
COMMENT ON TABLE transacional.faturas_cartao_credito IS 'Armazena os registros das faturas de cartão de crédito dos usuários.';
COMMENT ON COLUMN transacional.faturas_cartao_credito.id IS 'Identificador único da fatura do cartão de crédito (PK, fornecido externamente).';
COMMENT ON COLUMN transacional.faturas_cartao_credito.id_usuario_cartao_credito IS 'Referência à associação do usuário ao cartão de crédito (FK para essencial.usuario_cartao_credito).';
COMMENT ON COLUMN transacional.faturas_cartao_credito.abertura IS 'Data de abertura do período da fatura.';
COMMENT ON COLUMN transacional.faturas_cartao_credito.fechamento IS 'Data de fechamento do período da fatura, quando novas cobranças deixam de ser incluídas.';
COMMENT ON COLUMN transacional.faturas_cartao_credito.vencimento IS 'Data limite para o pagamento da fatura sem encargos.';
COMMENT ON COLUMN transacional.faturas_cartao_credito.valor IS 'Valor total calculado da fatura, somando todas as despesas do período.';
COMMENT ON COLUMN transacional.faturas_cartao_credito.valor_pago IS 'Valor efetivamente pago pelo usuário para a fatura correspondente.';
COMMENT ON COLUMN transacional.faturas_cartao_credito.data_de_pagamento IS 'Data em que o pagamento da fatura foi realizado (opcional).';
COMMENT ON COLUMN transacional.faturas_cartao_credito.situacao IS 'Status atual da fatura (ex: Aberta, Fechada, Paga, Vencida).';
COMMENT ON COLUMN transacional.faturas_cartao_credito.fatura IS 'Campo para armazenar informações detalhadas ou uma referência ao documento da fatura (ex: caminho para um arquivo PDF).';
COMMENT ON COLUMN transacional.faturas_cartao_credito.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro da fatura foi criado.';
COMMENT ON COLUMN transacional.faturas_cartao_credito.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'transacoes_recorrentes_cartao_credito'

CREATE TYPE transacional.procedimento_cartao_credito AS ENUM ('Crédito em Fatura', 'Débito em Fatura');

CREATE TABLE transacional.transacoes_recorrentes_cartao_credito (
    id character varying(50) NOT NULL,
    id_usuario_cartao_credito character varying(50) NOT NULL,
    id_operador character varying(50) NOT NULL,
    procedimento transacional.procedimento_cartao_credito NOT NULL DEFAULT 'Débito em Fatura',
    id_categoria character varying(50) NOT NULL,
    id_descricao character varying(50) NOT NULL,
    situacao essencial.situacao NOT NULL DEFAULT 'Ativo',
    tipo_recorrencia transacional.tipo_recorrencia NOT NULL,
    periodicidade transacional.periodicidade NOT NULL,
    vencimento_padrao integer,
    primeiro_vencimento date NOT NULL,
    ultimo_vencimento date,
    adiamento_por_dia_util boolean NOT NULL DEFAULT false,
    termos_servico text,
    relevancia_ir boolean NOT NULL DEFAULT false,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transacoes_recorrentes_cartao_credito_id_pk PRIMARY KEY (id),
    CONSTRAINT transacoes_recorrentes_cartao_credito_fk_usuario_cartao_credito FOREIGN KEY (id_usuario_cartao_credito) REFERENCES essencial.usuario_cartao_credito(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_recorrentes_cartao_credito_fk_categoria FOREIGN KEY (id_categoria) REFERENCES essencial.categorias(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_recorrentes_cartao_credito_fk_operador FOREIGN KEY (id_operador) REFERENCES essencial.operadores(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_recorrentes_cartao_credito_fk_descricao FOREIGN KEY (id_descricao) REFERENCES transacional.descricao(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_recorrentes_cartao_credito_verificar_vencimento_padrao CHECK (vencimento_padrao IS NULL OR (vencimento_padrao >= 1 AND vencimento_padrao <= 31)),
    CONSTRAINT transacoes_recorrentes_cartao_credito_verificar_vencimento_obrigatorio CHECK (periodicidade = 'Semanal' OR vencimento_padrao IS NOT NULL),
    CONSTRAINT transacoes_recorrentes_cartao_credito_verificar_logica_data_final CHECK (ultimo_vencimento IS NULL OR ultimo_vencimento >= primeiro_vencimento),
    CONSTRAINT transacoes_recorrentes_cartao_credito_verificar_data_final_obrigatoria CHECK (tipo_recorrencia = 'Prazo Indeterminado' OR ultimo_vencimento IS NOT NULL) 
);
COMMENT ON TABLE transacional.transacoes_recorrentes_cartao_credito IS 'Armazena os modelos/agendamentos de transações financeiras com cartão de crédito recorrentes.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.id IS 'Identificador único da recorrência de saldo (PK, fornecido externamente).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.id_usuario_cartao_credito IS 'Referência à associação do usuário ao cartão de crédito (FK para essencial.usuario_cartao_credito).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.procedimento IS 'Procedimento/método padrão das transações recorrentes.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.id_categoria IS 'Categoria padrão das transações recorrentes (FK para categorias).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.id_operador IS 'Operador padrão associado às transações desta recorrência (FK para operadores).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.situacao IS 'Status atual da recorrência (Ativo ou Inativo).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.id_descricao IS 'Descrição padrão para as transações geradas por esta recorrência.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.tipo_recorrencia IS 'Tipo de recorrência (Prazo Determinado com data final, ou Prazo Indeterminado).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.periodicidade IS 'Frequência com que a transação deve ocorrer (Semanal, Mensal, etc.).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.vencimento_padrao IS 'Dia preferencial do mês para vencimento (1-31), obrigatório se a frequência não for Semanal (opcional).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.primeiro_vencimento IS 'Data do primeiro vencimento ou da primeira ocorrência desta recorrência.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.ultimo_vencimento IS 'Data do último vencimento ou da última ocorrência (para tipo Prazo Determinado) (opcional).';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.adiamento_por_dia_util IS 'Indica se o vencimento, caso caia em dia não útil, deve ser adiado para o próximo dia útil. Padrão: FALSE.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.termos_servico IS 'Termos de serviço ou informações contratuais para esta recorrência.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.relevancia_ir IS 'Indica se as transações geradas por esta recorrência são relevantes para declaração de Imposto de Renda. Padrão: FALSE.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN transacional.transacoes_recorrentes_cartao_credito.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

-- Operacionalização da tabela 'transacoes_recorrentes_cartao_credito_valores'

CREATE TABLE transacional.transacoes_recorrentes_cartao_credito_valores (
    id character varying(50) NOT NULL,
    id_transacoes_recorrentes_cartao_credito character varying(50) NOT NULL,
    operacao transacional.procedimento_cartao_credito NOT NULL,
    categoria transacional.categoria_valores NOT NULL DEFAULT 'Base',
    observacoes text,
    valor numeric(15, 2) NOT NULL,
    CONSTRAINT transacoes_recorrentes_cartao_credito_valores_id_pk PRIMARY KEY (id),
    CONSTRAINT transacoes_recorrentes_cartao_credito_fk_transacoes_recorrentes_cartao_credito FOREIGN KEY (id_transacoes_recorrentes_cartao_credito) REFERENCES transacional.transacoes_recorrentes_cartao_credito(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE OR REPLACE FUNCTION transacional.transacoes_recorrentes_cartao_credito_valores_iniciais()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT'
    THEN
        
        INSERT INTO transacional.transacoes_recorrentes_cartao_credito_valores (
            id,
            id_transacoes_recorrentes_cartao_credito,
            operacao,
            valor
        ) VALUES (
            NEW.id || '1',
            NEW.id,
            'Débito em Fatura',
            '0.00'
        );

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER transacoes_recorrentes_cartao_credito_valores_iniciais
AFTER INSERT ON transacional.transacoes_recorrentes_cartao_credito
FOR EACH ROW EXECUTE FUNCTION transacional.transacoes_recorrentes_cartao_credito_valores_iniciais();

-- Operacionalização da tabela 'transacoes_cartao_credito'

CREATE TABLE transacional.transacoes_cartao_credito (
    id character varying(50) NOT NULL,
    id_fatura character varying(50) NOT NULL,
    id_operador character varying(50) NOT NULL,
    procedimento transacional.procedimento_cartao_credito NOT NULL DEFAULT 'Débito em Fatura',
    id_categoria character varying(50) NOT NULL,
    id_descricao character varying(50) NOT NULL,
    parcelas integer NOT NULL DEFAULT 1,
    situacao transacional.situacao NOT NULL DEFAULT 'Efetuado',
    data_programada timestamp with time zone,
    data_efetivacao timestamp with time zone,
    termos_servico text,
    comprovante text,
    nota_fiscal text,
    relevancia_ir boolean NOT NULL DEFAULT false,
    observacoes text,
    id_recorrencia character varying(50),
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transacoes_cartao_credito_id_pk PRIMARY KEY (id),
    CONSTRAINT transacoes_cartao_credito_credito_fk_fatura FOREIGN KEY (id_fatura) REFERENCES transacional.faturas_cartao_credito(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_cartao_credito_fk_categoria FOREIGN KEY (id_categoria) REFERENCES essencial.categorias(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_cartao_credito_fk_operador FOREIGN KEY (id_operador) REFERENCES essencial.operadores(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_cartao_credito_fk_descricao FOREIGN KEY (id_descricao) REFERENCES transacional.descricao(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_cartao_credito_fk_recorrencia FOREIGN KEY (id_recorrencia) REFERENCES transacional.transacoes_recorrentes_cartao_credito(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT transacoes_cartao_credito_verificar_data_efetivacao_maior_igual_programada CHECK (data_programada IS NULL OR data_efetivacao >= data_programada),
    CONSTRAINT transacoes_cartao_credito_verificar_efetivacao_nao_pendente CHECK ((situacao = 'Pendente' AND data_efetivacao IS NULL) OR (situacao <> 'Pendente' AND data_efetivacao IS NOT NULL))
);
COMMENT ON TABLE transacional.transacoes_cartao_credito IS 'Armazena todas as transações individuais realizadas com cartões de crédito.';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.id IS 'Identificador único da transação de cartão de crédito (PK, fornecido externamente).';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.id_fatura IS 'Referência à fatura na qual a transação foi lançada (FK para transacional.faturas_cartao_credito).';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.id_operador IS 'Referência ao operador/estabelecimento onde a transação foi realizada (FK para essencial.operadores).';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.procedimento IS 'Tipo de procedimento da transação".';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.id_categoria IS 'Referência à categoria da despesa ou receita (FK para essencial.categorias).';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.id_descricao IS 'Referência à descrição detalhada da transação (FK para transacional.descricao).';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.parcelas IS 'Número total de parcelas da transação. Para compras à vista, o valor é 1.';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.situacao IS 'Status atual da transação (ex: Efetuado, Pendente, Cancelado).';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.data_programada IS 'Data em que a transação foi agendada para ocorrer (opcional).';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.data_efetivacao IS 'Data em que a transação foi efetivamente processada e lançada.';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.termos_servico IS 'Campo para armazenar termos de serviço ou informações contratuais relacionadas à transação.';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.comprovante IS 'Armazena o texto ou caminho para o comprovante digital da transação.';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.nota_fiscal IS 'Armazena o texto ou caminho para a nota fiscal eletrônica (NF-e) da transação.';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.relevancia_ir IS 'Indica se a transação é relevante para a declaração de Imposto de Renda. Padrão: FALSE.';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.observacoes IS 'Campo de texto livre para anotações ou observações adicionais sobre a transação.';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.id_recorrencia IS 'Referência ao modelo de transação recorrente que originou esta transação (FK para transacional.transacoes_recorrentes_cartao_credito, opcional).';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro da transação foi criado.';
COMMENT ON COLUMN transacional.transacoes_cartao_credito.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação neste registro de transação.';


-- Operacionalização da tabela 'transacoes_cartao_credito_credito_valores'

CREATE TABLE transacional.transacoes_cartao_credito_credito_valores (
    id character varying(50) NOT NULL,
    id_transacoes_cartao_credito character varying(50) NOT NULL,
    operacao transacional.procedimento_cartao_credito NOT NULL,
    data_efetivacao timestamp with time zone NOT NULL,
    categoria transacional.categoria_valores NOT NULL DEFAULT 'Base',
    observacoes text,
    valor numeric(15, 2) NOT NULL,
    CONSTRAINT transacoes_cartao_credito_credito_valores_id_pk PRIMARY KEY (id),
    CONSTRAINT transacoes_cartao_credito_credito_valores_fk_transacoes_cartao_credito FOREIGN KEY (id_transacoes_cartao_credito) REFERENCES transacional.transacoes_cartao_credito(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE OR REPLACE FUNCTION transacional.transacoes_cartao_credito_valores_iniciais()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT'
    THEN
        
        INSERT INTO transacional.transacoes_cartao_credito_credito_valores (
            id,
            id_transacoes_recorrentes_cartao_credito,
            operacao,
            valor
        ) VALUES (
            NEW.id || '1',
            NEW.id,
            'Débito em Fatura',
            '0.00'
        );

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER transacoes_cartao_credito_credito_valores_iniciais
AFTER INSERT ON transacional.transacoes_cartao_credito
FOR EACH ROW EXECUTE FUNCTION transacional.transacoes_cartao_credito_valores_iniciais();

-- Operacionalização da tabela 'parcelamentos_cartao_credito'

CREATE TABLE transacional.parcelamentos_cartao_credito (
    id character varying(50) NOT NULL,
    id_fatura character varying(50) NOT NULL,
    id_transacoes_cartao_credito character varying(50) NOT NULL,
    parcela integer NOT NULL DEFAULT 1,
    observacoes text,
    valor numeric(15,2) NOT NULL,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT parcelamentos_cartao_credito_id_pk PRIMARY KEY (id),
    CONSTRAINT parcelamentos_cartao_credito_credito_fk_fatura FOREIGN KEY (id_fatura) REFERENCES transacional.faturas_cartao_credito(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT parcelamentos_cartao_credito_credito_fk_transacoes_cartao_credito FOREIGN KEY (id_transacoes_cartao_credito) REFERENCES transacional.transacoes_cartao_credito(id) ON DELETE CASCADE ON UPDATE CASCADE
);
COMMENT ON TABLE transacional.parcelamentos_cartao_credito IS 'Armazena o detalhamento de cada parcela individual de uma transação de cartão de crédito que foi parcelada.';
COMMENT ON COLUMN transacional.parcelamentos_cartao_credito.id IS 'Identificador único do registro de parcelamento (PK, fornecido externamente).';
COMMENT ON COLUMN transacional.parcelamentos_cartao_credito.id_fatura IS 'Referência à fatura específica onde esta parcela foi lançada (FK para transacional.faturas_cartao_credito).';
COMMENT ON COLUMN transacional.parcelamentos_cartao_credito.id_transacoes_cartao_credito IS 'Referência à transação original que foi parcelada (FK para transacional.transacoes_cartao_credito).';
COMMENT ON COLUMN transacional.parcelamentos_cartao_credito.parcela IS 'Número da parcela atual (ex: 1, 2, 3...).';
COMMENT ON COLUMN transacional.parcelamentos_cartao_credito.observacoes IS 'Campo de texto livre para anotações ou observações sobre esta parcela específica.';
COMMENT ON COLUMN transacional.parcelamentos_cartao_credito.valor IS 'Campo de valor, com limite de 2 casas decimais, para registro da parcela.';
COMMENT ON COLUMN transacional.parcelamentos_cartao_credito.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro da parcela foi criado.';
COMMENT ON COLUMN transacional.parcelamentos_cartao_credito.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação neste registro de parcela.';

-- =============================================================================
-- CRIAÇÃO DAS TABELAS DO SCHEMA "transacional" relacionadas à investimentos
-- =============================================================================

-- Operacionalização da tabela 'produtos_renda_fixa'

CREATE TABLE transacional.produtos_renda_fixa (
    id character varying(50) NOT NULL,
    id_emissores_renda_fixa character varying(50) NOT NULL,
    id_indexadores_investimentos character varying(50) NOT NULL,
    id_usuario_conta_investimento character varying(50) NOT NULL,
    id_usuario character varying(50) NOT NULL,
    descricao text NOT NULL,
    rendimento numeric(4,2),
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT produtos_renda_fixa_pk PRIMARY KEY (id),
    CONSTRAINT produtos_renda_fixa_fk_emissores_renda_fixa FOREIGN KEY (id_emissores_renda_fixa) REFERENCES essencial.emissores_renda_fixa(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT produtos_renda_fixa_fk_indexadores_investimentos FOREIGN KEY (id_indexadores_investimentos) REFERENCES essencial.indexadores_investimentos(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT produtos_renda_fixa_fk_usuarios FOREIGN KEY (id_usuario) REFERENCES essencial.usuarios(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT produtos_renda_fixa_fk_usuario_conta_investimento FOREIGN KEY (id_usuario_conta_investimento) REFERENCES essencial.usuario_contas(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT produtos_renda_fixa_unique UNIQUE (id_emissores_renda_fixa, id_indexadores_investimentos, descricao)
);
COMMENT ON TABLE transacional.produtos_renda_fixa IS 'Armazena os produtos de renda fixa disponíveis, com informações sobre emissores, indexadores e rendimento.';
COMMENT ON COLUMN transacional.produtos_renda_fixa.id IS 'Identificador único do produto de renda fixa (PK, fornecido externamente).';
COMMENT ON COLUMN transacional.produtos_renda_fixa.id_emissores_renda_fixa IS 'Referência ao emissor do produto de renda fixa (FK para essencial.emissores_renda_fixa).';
COMMENT ON COLUMN transacional.produtos_renda_fixa.id_indexadores_investimentos IS 'Referência ao indexador relacionado ao produto (FK para essencial.indexadores_investimentos).';
COMMENT ON COLUMN transacional.produtos_renda_fixa.id_usuario_conta_investimento IS 'Referência à conta de investimento/custódia onde o produto está registrado (FK para usuario_contas).';
COMMENT ON COLUMN transacional.produtos_renda_fixa.id_usuario IS 'Referência ao usuário (FK para essencial.usuarios).';
COMMENT ON COLUMN transacional.produtos_renda_fixa.descricao IS 'Descrição detalhada do produto de renda fixa.';
COMMENT ON COLUMN transacional.produtos_renda_fixa.rendimento IS 'Percentual de rendimento do produto de renda fixa (opcional).';
COMMENT ON COLUMN transacional.produtos_renda_fixa.datahora_criacao IS 'Data e hora exatas (UTC) em que o registro foi criado.';
COMMENT ON COLUMN transacional.produtos_renda_fixa.datahora_atualizacao IS 'Data e hora exatas (UTC) da última modificação manual neste registro.';

CREATE OR REPLACE FUNCTION transacional.validar_conta_investimento()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM essencial.usuario_contas uc
        JOIN essencial.conta_instituicao ci ON uc.id_conta_instituicao = ci.id
        WHERE uc.id = NEW.id_usuario_conta_investimento
          AND (ci.tipo_conta = 'Conta de Custódia' OR ci.investimentos = TRUE)
    ) THEN
        RAISE EXCEPTION 'A conta selecionada para investimento deve ser uma Conta de Custódia ou permitir investimentos';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validar_conta_investimento_trigger
BEFORE INSERT OR UPDATE ON transacional.produtos_renda_fixa
FOR EACH ROW EXECUTE FUNCTION transacional.validar_conta_investimento();

-- Operacionalização da tabela 'transacoes_investimentos_renda_fixa'

CREATE TYPE transacional.operacao_investimento AS ENUM ('Aplicação', 'Resgate');

CREATE TABLE transacional.transacoes_investimentos_renda_fixa (
    id character varying(50) NOT NULL,
    id_usuario_conta character varying(50) NOT NULL,
    id_produto_renda_fixa character varying(50) NOT NULL,
    id_operador character varying(50) NOT NULL,
    id_procedimento character varying(50) NOT NULL,
    situacao transacional.situacao NOT NULL DEFAULT 'Efetuado',
    data_programada timestamp with time zone,
    data_efetivacao timestamp with time zone,
    comprovante text,
    observacoes text,
    datahora_criacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datahora_atualizacao timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transacoes_investimentos_renda_fixa_id_pk PRIMARY KEY (id),
    CONSTRAINT transacoes_investimentos_renda_fixa_fk_usuario_conta FOREIGN KEY (id_usuario_conta) REFERENCES essencial.usuario_contas(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_investimentos_renda_fixa_fk_usuario_conta_investimento FOREIGN KEY (id_usuario_conta_investimento) REFERENCES essencial.usuario_contas(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_investimentos_renda_fixa_fk_procedimento FOREIGN KEY (id_procedimento) REFERENCES essencial.procedimentos_saldo(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_investimentos_renda_fixa_fk_produto_renda_fixa FOREIGN KEY (id_produto_renda_fixa) REFERENCES transacional.produtos_renda_fixa(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_investimentos_renda_fixa_fk_operador FOREIGN KEY (id_operador) REFERENCES essencial.operadores(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT transacoes_investimentos_renda_fixa_verificar_data_efetivacao_maior_igual_programada CHECK (data_programada IS NULL OR data_efetivacao >= data_programada),
    CONSTRAINT transacoes_investimentos_renda_fixa_verificar_efetivacao_nao_pendente CHECK ((situacao = 'Pendente' AND data_efetivacao IS NULL) OR (situacao <> 'Pendente' AND data_efetivacao IS NOT NULL)),
);

-- Operacionalização da tabela 'transacoes_investimentos_renda_fixa_valores'

CREATE TABLE transacional.transacoes_investimentos_renda_fixa_valores (
    id character varying(50) NOT NULL,
    id_transacoes_investimentos_renda_fixa character varying(50) NOT NULL,
    operacao transacional.operacao_investimento NOT NULL,
    data_efetivacao timestamp with time zone NOT NULL,
    categoria transacional.categoria_valores NOT NULL DEFAULT 'Base',
    observacoes text,
    valor numeric(15, 2) NOT NULL,
    CONSTRAINT transacoes_investimentos_renda_fixa_valores_id_pk PRIMARY KEY (id),
    CONSTRAINT transacoes_investimentos_renda_fixa_valores_fk_transacao FOREIGN KEY (id_transacoes_investimentos_renda_fixa) REFERENCES transacional.transacoes_investimentos_renda_fixa(id) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE transacional.transacoes_investimentos_renda_fixa_valores IS 'Armazena os valores detalhados das transações de investimentos em renda fixa.';
COMMENT ON COLUMN transacional.transacoes_investimentos_renda_fixa_valores.id IS 'Identificador único do valor da transação (PK, fornecido externamente).';
COMMENT ON COLUMN transacional.transacoes_investimentos_renda_fixa_valores.id_transacoes_investimentos_renda_fixa IS 'Referência à transação de investimento em renda fixa (FK para transacoes_investimentos_renda_fixa).';
COMMENT ON COLUMN transacional.transacoes_investimentos_renda_fixa_valores.operacao IS 'Tipo da operação (Aplicação ou Resgate).';
COMMENT ON COLUMN transacional.transacoes_investimentos_renda_fixa_valores.data_efetivacao IS 'Data e hora em que o valor foi efetivado.';
COMMENT ON COLUMN transacional.transacoes_investimentos_renda_fixa_valores.categoria IS 'Categoria do valor (Base, Taxa Diversa, etc.).';
COMMENT ON COLUMN transacional.transacoes_investimentos_renda_fixa_valores.observacoes IS 'Observações adicionais sobre este valor específico.';
COMMENT ON COLUMN transacional.transacoes_investimentos_renda_fixa_valores.valor IS 'Valor monetário com até 2 casas decimais.';

-- Trigger para criação automática de registro inicial de valores

CREATE OR REPLACE FUNCTION transacional.transacoes_investimentos_renda_fixa_valores_iniciais()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT'
    THEN
        
        INSERT INTO transacional.transacoes_investimentos_renda_fixa_valores (
            id,
            id_transacoes_investimentos_renda_fixa,
            operacao,
            data_efetivacao,
            valor
        ) VALUES (
            NEW.id || '1',
            NEW.id,
            NEW.operacao,
            NEW.data_efetivacao,
            '0.00'
        );

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER transacoes_investimentos_renda_fixa_valores_iniciais
AFTER INSERT ON transacional.transacoes_investimentos_renda_fixa
FOR EACH ROW EXECUTE FUNCTION transacional.transacoes_investimentos_renda_fixa_valores_iniciais();