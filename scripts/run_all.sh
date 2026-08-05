#!/usr/bin/env bash
# ==============================================================================
# Script Bash de Orquestração E2E para Linux (BACEN & Glassdoor Pipeline)
# eEDB-022 - Ingestão e Pipeline de Dados (PECE/POLI-USP)
# ==============================================================================

set -e

# Cores para formatação de saída no terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Sem Cor

echo -e "${CYAN}=========================================================="
echo -e "  Atividade 1: Ingestão e ETL - Apache Hop & PostgreSQL"
echo -e "==========================================================${NC}\n"

# Identifica a raiz do projeto (independente de onde o script é executado)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$WORKSPACE_DIR"

# 0. Verificação do Python e ambiente
echo -e "${YELLOW}[0/4] Verificando dependências Python...${NC}"
PYTHON_BIN="python3"

if ! command -v $PYTHON_BIN &> /dev/null; then
    echo -e "${RED}Erro: Python3 não encontrado no sistema. Instale o Python 3.8+ antes de continuar.${NC}"
    exit 1
fi

# Instalar dependências Python mínimas se necessário
$PYTHON_BIN -c "import psycopg2, pandas" 2>/dev/null || {
    echo -e "${YELLOW}Instalando dependências Python (psycopg2-binary, pandas)...${NC}"
    $PYTHON_BIN -m pip install --quiet psycopg2-binary pandas
}

# Detectar comando docker compose (v2) vs docker-compose (v1)
DOCKER_COMPOSE_CMD="docker compose"
if ! docker compose version &> /dev/null; then
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
    else
        echo -e "${RED}Erro: Nem 'docker compose' nem 'docker-compose' foram encontrados. Verifique a instalação do Docker.${NC}"
        exit 1
    fi
fi

# 1. Subir infraestrutura Docker (PostgreSQL 16 DW & Apache Hop Web GUI)
echo -e "\n${YELLOW}[1/4] Subindo infraestrutura Docker Compose...${NC}"
cd "$WORKSPACE_DIR/docker"
$DOCKER_COMPOSE_CMD up -d

echo -e "${YELLOW}Aguardando inicialização do banco de dados PostgreSQL...${NC}"
MAX_RETRIES=30
RETRIES=0
until docker exec postgres_dw pg_isready -U postgres -d eedb_dw &> /dev/null || [ $RETRIES -eq $MAX_RETRIES ]; do
    echo -n "."
    sleep 1
    ((RETRIES++))
done
echo ""

if [ $RETRIES -eq $MAX_RETRIES ]; then
    echo -e "${YELLOW}PostgreSQL inicializando... aguardando 5 segundos adicionais.${NC}"
    sleep 5
else
    echo -e "${GREEN}PostgreSQL está online e pronto para conexões!${NC}"
fi

# 2. Executar provisionamento IaC (Terraform)
echo -e "\n${YELLOW}[2/4] Executando Terraform para declarar Schemas no PostgreSQL...${NC}"
if command -v terraform &> /dev/null; then
    cd "$WORKSPACE_DIR/terraform"
    terraform init -input=false
    terraform apply -auto-approve -input=false
else
    echo -e "${YELLOW}Terraform não encontrado no PATH. O pipeline prosseguirá aplicando DDLs via Python/SQL.${NC}"
fi

# 3. Executar o Pipeline de ETL (Carga Staging + Star Schema + Tabela Final)
cd "$WORKSPACE_DIR"
echo -e "\n${YELLOW}[3/4] Executando Pipeline de ETL Visual / Headless...${NC}"
$PYTHON_BIN scripts/execute_hop_pipeline.py

# 4. Validação da Tabela Final Consolidada e Star Schema
echo -e "\n${YELLOW}[4/4] Executando validação SQL no PostgreSQL DW...${NC}"
$PYTHON_BIN -c "
import psycopg2

try:
    conn = psycopg2.connect(host='localhost', port=5432, dbname='eedb_dw', user='postgres', password='postgres')
    cur = conn.cursor()

    cur.execute('SELECT COUNT(*) FROM staging.stg_reclamacoes;')
    stg_count = cur.fetchone()[0]

    cur.execute('SELECT COUNT(*) FROM dw.fato_reclamacoes;')
    fato_count = cur.fetchone()[0]

    cur.execute('SELECT COUNT(*) FROM dw.tb_final_consolidada_reclamacoes;')
    final_count = cur.fetchone()[0]

    print(f'-> Total Registros Staging Reclamações: {stg_count}')
    print(f'-> Total Registros Fato Reclamações: {fato_count}')
    print(f'-> Total Registros Tabela Final Consolidada: {final_count}')

    cur.execute('''
        SELECT segmento, COUNT(DISTINCT nome_instituicao) AS instituicoes, SUM(qtd_total_reclamacoes) AS reclamacoes
        FROM dw.tb_final_consolidada_reclamacoes
        GROUP BY segmento
        ORDER BY reclamacoes DESC;
    ''')
    print('\nResumo Analítico por Segmento:')
    for row in cur.fetchall():
        print(f'  Segmento {row[0]}: {row[1]} Instituições, {row[2]} Reclamações Totais')
    conn.close()
except Exception as e:
    print(f'Erro na validação SQL: {e}')
    exit(1)
"

echo -e "\n${GREEN}=========================================================="
echo -e "  Pipeline de ETL Executado e Validado com Sucesso!"
echo -e "==========================================================${NC}"
