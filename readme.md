# SisFinance - Sistema de Gestão de Finanças Pessoais

Este repositório contém scripts para automatizar a gestão do SisFinance (Sistema de Gestão de Finanças Pessoais), operando a lógica de negócios em Python a partir com um banco de dados PostgreSQL.

## Informações, Banco de Dados e Front-End

A estrutura do Banco de Dados, com nome `SisFinance` é composta por tabelas com tipos de dados personalizados e regras de integridade específicas, construídos sob demanda específica para uso pelo sistema. A estrutura e comando SQL de criação estão em `structure_bd.sql`.

Já em relação à apresentação do sistema (ou Front-End), está sendo feita por meio do `Google AppSheet` (com interface gráfica com regras próprias adaptadas ao sistema).

## Funcionalidades
### Gerenciamento de criação, atualização ou remoção de faturas
> Prioridade Máxima
- **Situação Atual:** Implementado
- **Linguagem:** Python (`manage_invoices`)
- **Objetivo:**
    - Geração automática de faturas futuras para cartões de crédito cadastrados.
    - Atualização de datas de abertura, fechamento e vencimento conforme regras de negócio.
    - Exclusão de faturas de cartões desativados sem movimentação.
    - Execução automática a cada 5 dias ou sob demanda manual.
### Gerenciamento de criação ou remoção de parcelas
> Prioridade Máxima
- **Situação Atual:** Em implementação
- **Linguagem:** Python (`manage_installments`)
- **Objetivo:**
    - Criação ou remoção, em tabela personalizada, de dados de parcelamentos em transações com cartão de crédito parcelado (sendo que cada parcelamento será correspondente a uma fatura existente).
    - **PENDENTE URGENTE** - Atualiza os dados de parcelamentos em transações com cartão de crédito parcelado somente se o valor total das parcelas for diferente do valor total do produto.
    - Execução sob demanda automática (via chamamento externo, com autenticação) ou manual. 
### Gerenciamento de valores de faturas
> Prioridade Máxima
- **Situação Atual:** Em implementação avançada (falta ajustes de código)
- **Linguagem:** Python
- **Objetivo:**
    - Cálculo automático de valores das faturas, para transações com cartão de crédito à vista ou para transações com cartão de crédito parcelado.
    - Execução sob demanda automática (via chamamento externo, com autenticação) ou manual. 
### Gerenciamento de criação, atualização ou remoção de pagamentos recorrentes em transações com saldo ou cartão de crédito
> Prioridade Média
- **Situação Atual:** Em implementação
- **Linguagem:** Python
- **Objetivo:**
    - Criação automática de pagamentos recorrentes nas tabelas de transações com cartão de crédito, conforme configurações individuais.
    - Execução sob demanda automática (via chamamento externo, com autenticação) ou manual.
### Gerenciamento de criação, atualização ou remoção de investimentos
> Prioridade Baixa
- **Situação Atual:** Em implementação
- **Linguagem:** Python
- **Objetivo:**
    - Criação, em tabela exclusiva para isso, de investimentos ativos com base em cálculos feitos na tabela específica para transações com investimentos. 
    - Execução sob demanda automática (via chamamento externo, com autenticação) ou manual.
### Gerenciamento de investimentos ativos
> Prioridade Baixa
- **Situação Atual:** Em implementação
- **Linguagem:** Python
- **Objetivo:**
    - Atualização de valores de investimentos ativos, para renda fixa (com rendimentos mensalmente, a partir de dados econômicos como CDI, SELIC ou IPCA, com atualização diária conforme tabela de impostos e rendimentos específicos de cada investimento) e para renda variável (a partir de valores reais em bolsa de valores).
    - Execução automática a cada dia ou sob demanda manual.
### Gerenciamento de dados em outras moedas (ex-BRL)
> Prioridade Baixa
- **Situação Atual:** Em planejamento
- **Linguagem:** Python
- **Objetivo:**
    - PENDENTE
    - PENDENTE
### Relatórios de Transações (a partir de dados de saldo e cartão de crédito)
> Prioridade Baixa
- **Situação Atual:** Em planejamento
- **Linguagem:** Python
- **Objetivo:**
    - PENDENTE
    - PENDENTE
### Registro Histórico de Saldos
> Prioridade Baixa
- **Situação Atual:** Em planejamento
- **Linguagem:** Python
- **Objetivo:**
    - PENDENTE
    - PENDENTE
### Gerenciamento de criação, alteração ou exclusão de eventos em agenda do Google Agenda
> Prioridade Baixa
- **Situação Atual:** Em planejamento
- **Linguagem:** JavaScript (via Google Apps Script)
- **Objetivo:**
    - PENDENTE
    - PENDENTE

## Estrutura das Pastas
- Em relação ao gerenciamento de faturas (`manage_invoices`):
    - `creditcard_invoices/manage_invoices.py`: Script de gerenciamento de faturas.
    - `creditcard_invoices/requirements.txt`: Dependências Python necessárias.
    - `.github/workflows/manage_invoices.yml`: Workflow do GitHub Actions para execução automatizada.
- Em relação à geração de parcelas (`manage_installments`):
    - `creditcard_invoices/manage_installments.py`: Script para criação, modificação ou remoção de faturas.
    - `creditcard_invoices/requirements.txt`: Dependências Python necessárias.
    - `.github/workflows/manage_installments.yml`: Workflow do GitHub Actions para execução automatizada.

## Licença
Uso interno/proprietário.
