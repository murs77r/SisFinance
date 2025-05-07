# SisFinance - Sistema de Gestão de Finanças Pessoais

Este repositório contém scripts para automatizar a gestão do SisFinance (Sistema de Gestão de Finanças Pessoais), operando a lógica de negócios em Python a partir com um banco de dados PostgreSQL.

## Funcionalidades
- **IMPLEMENTADO EM PYTHON (`manage_invoices`)** - Gerenciamento de criação, atualização ou remoção de faturas:
    - Geração automática de faturas futuras para cartões de crédito cadastrados.
    - Atualização de datas de abertura, fechamento e vencimento conforme regras de negócio.
    - Exclusão de faturas de cartões desativados sem movimentação.
    - Execução automática a cada 5 dias ou sob demanda manual.
- **EM IMPLEMENTAÇÃO EM PYTHON** - Gerenciamento de valores de faturas:
    - Cálculo automático de valores das faturas, para transações com cartão de crédito à vista ou para transações com cartão de crédito parcelado.
    - Execução sob demanda automática (via chamamento externo, com autenticação) ou manual. 
- **EM IMPLEMENTAÇÃO EM PYTHON** - Gerenciamento de criação, atualização ou remoção de pagamentos recorrentes em transações com saldo ou cartão de crédito:
    - Criação automática de pagamentos recorrentes nas tabelas de transações com cartão de crédito, conforme configurações individuais.
    - Execução sob demanda automática (via chamamento externo, com autenticação) ou manual.
- **EM IMPLEMENTAÇÃO EM PYTHON** - Gerenciamento de criação, atualização ou remoção de investimentos:
    - Criação, em tabela exclusiva para isso, de investimentos ativos com base em cálculos feitos na tabela específica para transações com investimentos. 
    - Execução sob demanda automática (via chamamento externo, com autenticação) ou manual.
- **EM IMPLEMENTAÇÃO EM PYTHON** - Gerenciamento de investimentos ativos:
    - Atualização de valores de investimentos ativos, para renda fixa (com rendimentos mensalmente, a partir de dados econômicos como CDI, SELIC ou IPCA, com atualização diária conforme tabela de impostos e rendimentos específicos de cada investimento) e para renda variável (a partir de valores reais em bolsa de valores).
    - Execução automática a cada dia ou sob demanda manual.
- **EM IMPLEMENTAÇÃO EM PYTHON** - Gerenciamento de dados em outras moedas (ex-BRL):
    - PENDENTE
    - PENDENTE
- **EM IMPLEMENTAÇÃO EM PYTHON** - Relatórios de Transações (a partir de dados de saldo e cartão de crédito):
    - PENDENTE
    - PENDENTE
- **EM IMPLEMENTAÇÃO EM PYTHON** - Histórico de Saldos:
    - PENDENTE
    - PENDENTE
- **EM IMPLEMENTAÇÃO EM JAVASCRIPT (GOOGLE APPS SCRIPT)** - Gerenciamento de criação, alteração ou exclusão de eventos em agenda do Google Agenda:
    - PENDENTE
    - PENDENTE

## Estrutura
- Em relação ao gerenciamento de faturas (`manage_invoices`):
    - `creditcard_invoices/manage_invoices.py`: Script principal de gerenciamento de faturas.
    - `creditcard_invoices/requirements.txt`: Dependências Python necessárias.
    - `.github/workflows/manage_invoices.yml`: Workflow do GitHub Actions para execução automatizada.

## Licença
Uso interno/proprietário.
