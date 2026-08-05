# Atividade 1 – Ingestão e ETL com Ferramenta Visual (Apache Hop + PostgreSQL)

Este repositório contém a solução completa para a **Atividade 1** da disciplina **Ingestão e Pipeline de Dados (eEDB-011 / eEDB-022)** da especialização em Engenharia de Dados e Big Data (PECE/POLI-USP).

---

## 🎯 Objetivos da Atividade
1. **Ferramenta Visual de ETL**: Construir pipelines visuais e workflows no **Apache Hop** (`.hpl` e `.hwk`).
2. **Ingestão em Banco de Dados Relacional Open Source**: Ingestão completa no **PostgreSQL 16**.
3. **Modelagem Star Schema (Dimensional)**: Construção de dimensões (`dim_instituicao`, `dim_tempo`, `dim_clima_organizacional`) e da tabela fato (`fato_reclamacoes`).
4. **Tabela Final Consolidada**: Geração da tabela final unificada e tratada (`dw.tb_final_consolidada_reclamacoes`).
5. **Infraestrutura como Código (IaC) & Conteinerização**: Uso de **Docker Compose** e **Terraform**.

---

## 📂 Arquitetura e Estrutura do Projeto

```text
.
├── docker/
│   ├── docker-compose.yml           # PostgreSQL 16 DW e Apache Hop Container
│   └── postgres/init/01_init_db.sql # Script DDL de inicialização do PostgreSQL
├── terraform/
│   ├── main.tf                      # Declarativo dos Schemas staging e dw via IaC
│   ├── variables.tf                 # Variáveis de conexão
│   ├── terraform.tfvars             # Parâmetros de ambiente
│   └── outputs.tf                   # Outputs dos recursos criados
├── sql/
│   ├── 01_create_staging_tables.sql # DDL das Tabelas Staging
│   ├── 02_create_star_schema.sql    # DDL da Fato e Dimensões (Star Schema)
│   └── 03_create_final_table.sql    # DDL da Tabela Final Consolidada e Views
├── hop/
│   ├── project-config.json          # Configuração de conexões JDBC do Hop
│   ├── pipelines/
│   │   ├── pipe_stg_enquadramento.hpl
│   │   ├── pipe_stg_glassdoor.hpl
│   │   ├── pipe_stg_reclamacoes.hpl
│   │   ├── pipe_build_star_schema.hpl
│   │   └── pipe_build_final_consolidated.hpl
│   └── workflows/
│       └── wf_main_etl.hwk          # Workflow orquestrador visual principal
├── scripts/
│   ├── run_all.ps1                  # Script PowerShell de Execução Completa E2E
│   └── execute_hop_pipeline.py      # Executor Python para orquestração da ETL
└── README.md                        # Documentação do Projeto
```

---

## 🏗️ Modelagem Dimensional (Star Schema)

### 1. Staging Zone (`staging`)
- `stg_enquadramento`: Enquadramento dos bancos pelo BACEN (S1, S2, S3, S4, S5).
- `stg_glassdoor`: Avaliações, satisfação, cultura e benefícios dos funcionários no Glassdoor.
- `stg_reclamacoes`: Ingestão unificada dos 8 trimestres (2021-2022) do Banco Central.

### 2. Data Warehouse Star Schema (`dw`)
- **`dim_instituicao`**: Surrogate key `sk_instituicao`, `cnpj_if`, `nome_instituicao`, `segmento`, `categoria`, `tipo_instituicao`.
- **`dim_tempo`**: Surrogate key `sk_tempo`, `ano`, `trimestre`, `rotulo_trimestre` (ex: `2021-Q1`).
- **`dim_clima_organizacional`**: Surrogate key `sk_clima`, `employer_name`, notas de cultura, liderança, remuneração e recomendação.
- **`fato_reclamacoes`**: Métricas de reclamações reguladas procedentes, outras, não reguladas, total de reclamações, quantidade de clientes e índice de reclamação.

### 3. Tabela Final Consolidada (`dw.tb_final_consolidada_reclamacoes`)
Tabela tratada e unificada que consolida as Reclamações do BACEN, o Enquadramento do BACEN e o Clima do Glassdoor em uma única visão analítica de alta performance.

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- Docker & Docker Compose
- Terraform (opcional, orquestrado via script)
- Python 3.8+ (`pandas`, `psycopg2-binary`)

### Execução Automática (E2E)
No PowerShell, execute o script principal na raiz do repositório:

```powershell
.\scripts\run_all.ps1
```

O script realizará:
1. Subida dos containers PostgreSQL e Apache Hop via Docker Compose.
2. Aplicação do Terraform para declarar os Schemas no PostgreSQL.
3. Carga e execução dos pipelines de ETL do Apache Hop.
4. Consulta SQL de validação exibindo a contagem de registros e o resumo analítico por segmento.

---

## 📊 Consulta SQL de Exemplo

Para consultar o resumo consolidado no PostgreSQL:

```sql
SELECT 
    segmento, 
    COUNT(DISTINCT nome_instituicao) AS total_instituicoes,
    SUM(qtd_total_reclamacoes) AS total_reclamacoes,
    AVG(score_geral_glassdoor) AS media_satisfacao_glassdoor
FROM dw.tb_final_consolidada_reclamacoes
GROUP BY segmento
ORDER BY total_reclamacoes DESC;
```
