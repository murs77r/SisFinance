# SisFinance - Sistema de Gestão de Finanças Pessoais

Este repositório contém scripts para automatizar a gestão do SisFinance (Sistema de Gestão de Finanças Pessoais), operando a lógica de negócios em Python a partir com um banco de dados PostgreSQL.

## Funcionalidades
- Em relação ao gerenciamento de faturas:
    - Geração automática de faturas futuras para cartões de crédito cadastrados.
    - Atualização de datas de abertura, fechamento e vencimento conforme regras de negócio.
    - Exclusão de faturas de cartões desativados sem movimentação.
    - Processamento em lotes para eficiência.

## Estrutura
- Em relação ao gerenciamento de faturas (`manage_invoices`):
    - `creditcard_invoices/manage_invoices.py`: Script principal de gerenciamento de faturas.
    - `creditcard_invoices/requirements.txt`: Dependências Python necessárias.
    - `.github/workflows/invoices.yml`: Workflow do GitHub Actions para execução automatizada.

## Licença
Uso interno/proprietário.
