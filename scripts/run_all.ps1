# Script PowerShell de Orquestração E2E
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -ErrorAction SilentlyContinue

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Atividade 1: Ingestão e ETL - Apache Hop & PostgreSQL" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$WorkspaceDir = Get-Location

# 1. Subir a infraestrutura Docker (PostgreSQL 16 DW & Apache Hop Container)
Write-Host "`n[1/4] Subindo infraestrutura Docker Compose..." -ForegroundColor Yellow
Set-Location -Path "$WorkspaceDir\docker"
docker-compose up -d

Write-Host "Aguardando inicialização do banco de dados PostgreSQL..." -ForegroundColor Yellow
Start-Sleep -Seconds 6

# 2. Executar provisionamento do Terraform (IaC)
Write-Host "`n[2/4] Executando Terraform para declarar Schemas no PostgreSQL..." -ForegroundColor Yellow
Set-Location -Path "$WorkspaceDir\terraform"
terraform init
terraform apply -auto-approve

# 3. Executar o Pipeline de ETL (Carga Staging + Star Schema + Tabela Final)
Set-Location -Path "$WorkspaceDir"
Write-Host "`n[3/4] Executando Pipeline de ETL Visual / Headless..." -ForegroundColor Yellow
python scripts\execute_hop_pipeline.py

# 4. Validação da Tabela Final Consolidada e Star Schema
Write-Host "`n[4/4] Executando validação SQL no PostgreSQL DW..." -ForegroundColor Yellow
python -c "
import psycopg2
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
"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  Pipeline de ETL Executado e Validado com Sucesso! " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
