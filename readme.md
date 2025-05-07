# Scripts para o SisFinance - Gerenciamento de Faturas de Cartão de Crédito

Este repositório contém scripts para automatizar a gestão do SisFinance (Sistema de Gestão de Finanças Pessoais), operando a lógica de negócios em Python a partir com um banco de dados PostgreSQL.

## Funcionalidades
- Em relação ao gerenciamento de faturas:
    - Geração automática de faturas futuras para cartões de crédito cadastrados
    - Atualização de datas de abertura, fechamento e vencimento conforme regras de negócio
    - Exclusão de faturas de cartões desativados sem movimentação
    - Processamento em lotes para eficiência

## Estrutura
- `creditcard_invoices/manage_invoices.py`: Script principal de gerenciamento de faturas
- `creditcard_invoices/requirements.txt`: Dependências Python necessárias
- `.github/workflows/invoices.yml`: Workflow do GitHub Actions para execução automatizada
   ```

## Execução Automática
O workflow do GitHub Actions executa o script a cada 5 dias ou sob demanda manual.

## Observações
- O script utiliza timezone 'America/Sao_Paulo' e feriados nacionais brasileiros.

## Licença
Uso interno.
