import os
import sys
import glob
import pandas as pd
import psycopg2
from psycopg2.extras import execute_batch

DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": int(os.environ.get("DB_PORT", 5432)),
    "dbname": os.environ.get("DB_NAME", "eedb_dw"),
    "user": os.environ.get("DB_USER", "postgres"),
    "password": os.environ.get("DB_PASSWORD", "postgres")
}

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "Dados")

def get_connection():
    return psycopg2.connect(**DB_CONFIG)

def run_sql_script(conn, script_path):
    print(f"Executing SQL script: {script_path}")
    with open(script_path, "r", encoding="utf-8") as f:
        sql = f.read()
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()

def ingest_enquadramento(conn):
    file_path = os.path.join(DATA_DIR, "Bancos", "EnquadramentoInicia_v2.tsv")
    print(f"Ingesting Enquadramento from {file_path}...")
    df = pd.read_csv(file_path, sep="\t", dtype=str)
    df.columns = [c.strip().lower() for c in df.columns]
    
    rows = list(df.itertuples(index=False, name=None))
    
    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE staging.stg_enquadramento;")
        query = "INSERT INTO staging.stg_enquadramento (segmento, cnpj, nome) VALUES (%s, %s, %s);"
        execute_batch(cur, query, rows)
    conn.commit()
    print(f"Ingested {len(rows)} rows into staging.stg_enquadramento.")

def ingest_glassdoor(conn):
    file_path = os.path.join(DATA_DIR, "Empregados", "glassdoor_consolidado_join_match_v2.csv")
    print(f"Ingesting Glassdoor from {file_path}...")
    df = pd.read_csv(file_path, sep="|")
    
    # Clean columns mapping
    df = df.rename(columns={
        "employer-website": "employer_website",
        "employer-headquarters": "employer_headquarters",
        "employer-founded": "employer_founded",
        "employer-industry": "employer_industry",
        "employer-revenue": "employer_revenue",
        "Geral": "score_geral",
        "Cultura e valores": "score_cultura",
        "Diversidade e inclusão": "score_diversidade",
        "Qualidade de vida": "score_qualidade_vida",
        "Alta liderança": "score_lideranca",
        "Remuneração e benefícios": "score_remuneracao",
        "Oportunidades de carreira": "score_carreira",
        "Recomendam para outras pessoas(%)": "pct_recomendam",
        "Perspectiva positiva da empresa(%)": "pct_perspectiva_positiva",
        "Segmento": "segmento",
        "Nome": "nome"
    })
    
    selected_cols = [
        "employer_name", "reviews_count", "culture_count", "salaries_count", "benefits_count",
        "employer_website", "employer_headquarters", "employer_founded", "employer_industry",
        "employer_revenue", "url", "score_geral", "score_cultura", "score_diversidade",
        "score_qualidade_vida", "score_lideranca", "score_remuneracao", "score_carreira",
        "pct_recomendam", "pct_perspectiva_positiva", "segmento", "nome", "match_percent"
    ]
    df_sub = df[selected_cols].where(pd.notnull(df[selected_cols]), None)
    rows = [tuple(x) for x in df_sub.to_numpy()]

    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE staging.stg_glassdoor;")
        query = """
            INSERT INTO staging.stg_glassdoor (
                employer_name, reviews_count, culture_count, salaries_count, benefits_count,
                employer_website, employer_headquarters, employer_founded, employer_industry,
                employer_revenue, url, score_geral, score_cultura, score_diversidade,
                score_qualidade_vida, score_lideranca, score_remuneracao, score_carreira,
                pct_recomendam, pct_perspectiva_positiva, segmento, nome, match_percent
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
        """
        execute_batch(cur, query, rows)
    conn.commit()
    print(f"Ingested {len(rows)} rows into staging.stg_glassdoor.")

def parse_br_float(val_str):
    if val_str is None:
        return None
    cleaned = str(val_str).strip()
    if not cleaned or cleaned == "":
        return None
    cleaned = cleaned.replace(".", "").replace(",", ".")
    try:
        return float(cleaned)
    except ValueError:
        return None

def parse_br_int(val_str):
    if val_str is None:
        return 0
    cleaned = str(val_str).strip()
    if not cleaned or cleaned == "":
        return 0
    cleaned = cleaned.replace(".", "").replace(",", ".")
    try:
        return int(float(cleaned))
    except ValueError:
        return 0

def ingest_reclamacoes(conn):
    files_pattern = os.path.join(DATA_DIR, "Reclamações", "*.csv")
    csv_files = glob.glob(files_pattern)
    print(f"Found {len(csv_files)} files in Reclamações directory.")
    
    all_rows = []
    for fpath in csv_files:
        if "nao_ha_dados" in fpath or os.path.getsize(fpath) == 0:
            print(f"Skipping empty file: {os.path.basename(fpath)}")
            continue
            
        try:
            df = pd.read_csv(fpath, sep=";", encoding="utf-8", dtype=str)
        except Exception:
            df = pd.read_csv(fpath, sep=";", encoding="latin1", dtype=str)
        df = df.dropna(how="all")

        
        for _, row in df.iterrows():
            if pd.isna(row.get("Ano")) or str(row.get("Ano")).strip() == "":
                continue
                
            ano = int(str(row.get("Ano")).strip())
            trimestre = str(row.get("Trimestre")).strip()
            categoria = str(row.get("Categoria")).strip() if pd.notna(row.get("Categoria")) else None
            tipo = str(row.get("Tipo")).strip() if pd.notna(row.get("Tipo")) else None
            cnpj_if = str(row.get("CNPJ IF")).strip() if pd.notna(row.get("CNPJ IF")) else None
            inst_fin = str(row.get("Instituição financeira")).strip() if pd.notna(row.get("Instituição financeira")) else None
            
            idx_val = parse_br_float(row.get("Índice"))
            q_proc = parse_br_int(row.get("Quantidade de reclamações reguladas procedentes"))
            q_outr = parse_br_int(row.get("Quantidade de reclamações reguladas - outras"))
            q_nreg = parse_br_int(row.get("Quantidade de reclamações não reguladas"))
            q_tot  = parse_br_int(row.get("Quantidade total de reclamações"))
            q_ccs_scr = parse_br_int(row.get("Quantidade total de clientes - CCS e SCR"))
            q_ccs = parse_br_int(row.get("Quantidade de clientes - CCS"))
            q_scr = parse_br_int(row.get("Quantidade de clientes - SCR"))

            all_rows.append((
                ano, trimestre, categoria, tipo, cnpj_if, inst_fin, idx_val,
                q_proc, q_outr, q_nreg, q_tot, q_ccs_scr, q_ccs, q_scr
            ))
            
    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE staging.stg_reclamacoes;")
        query = """
            INSERT INTO staging.stg_reclamacoes (
                ano, trimestre, categoria, tipo, cnpj_if, instituicao_financeira, indice_reclamacao,
                qtd_reclamacoes_procedentes, qtd_reclamacoes_outras, qtd_reclamacoes_nao_reguladas,
                qtd_total_reclamacoes, qtd_total_clientes_ccs_scr, qtd_clientes_ccs, qtd_clientes_scr
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
        """
        execute_batch(cur, query, all_rows)
    conn.commit()
    print(f"Ingested {len(all_rows)} total rows into staging.stg_reclamacoes.")

def execute_star_schema_and_final(conn):
    print("Executing Star Schema & Final Table transformations...")
    sql_star = os.path.join(BASE_DIR, "sql", "02_create_star_schema.sql")
    sql_final = os.path.join(BASE_DIR, "sql", "03_create_final_table.sql")
    
    run_sql_script(conn, sql_star)
    
    with conn.cursor() as cur:
        cur.execute("""
            -- 1. dim_instituicao com DISTINCT ON para prevenir duplicatas no conflito
            INSERT INTO dw.dim_instituicao (cnpj_if, nome_instituicao, segmento, categoria, tipo_instituicao)
            SELECT DISTINCT ON (nome_instituicao, segmento)
                r.cnpj_if,
                TRIM(r.instituicao_financeira) AS nome_instituicao,
                COALESCE(e.segmento, r.categoria, 'Outros') AS segmento,
                r.categoria,
                r.tipo
            FROM staging.stg_reclamacoes r
            LEFT JOIN staging.stg_enquadramento e ON TRIM(e.nome) = TRIM(r.instituicao_financeira) OR e.cnpj = r.cnpj_if
            ORDER BY nome_instituicao, segmento
            ON CONFLICT (nome_instituicao, segmento) DO UPDATE SET 
                cnpj_if = EXCLUDED.cnpj_if,
                categoria = EXCLUDED.categoria,
                tipo_instituicao = EXCLUDED.tipo_instituicao;

            -- 2. dim_tempo
            INSERT INTO dw.dim_tempo (ano, trimestre, rotulo_trimestre)
            SELECT DISTINCT ON (ano, trimestre)
                r.ano,
                r.trimestre,
                CONCAT(r.ano, '-Q', REPLACE(r.trimestre, 'º', '')) AS rotulo_trimestre
            FROM staging.stg_reclamacoes r
            WHERE r.ano IS NOT NULL
            ORDER BY ano, trimestre
            ON CONFLICT (ano, trimestre) DO NOTHING;

            -- 3. dim_clima_organizacional
            INSERT INTO dw.dim_clima_organizacional (
                employer_name, score_geral, score_cultura, score_diversidade,
                score_qualidade_vida, score_lideranca, score_remuneracao, score_carreira,
                pct_recomendam, pct_perspectiva_positiva, employer_headquarters,
                employer_founded, employer_revenue
            )
            SELECT DISTINCT ON (g.employer_name)
                g.employer_name, g.score_geral, g.score_cultura, g.score_diversidade,
                g.score_qualidade_vida, g.score_lideranca, g.score_remuneracao, g.score_carreira,
                g.pct_recomendam, g.pct_perspectiva_positiva, g.employer_headquarters,
                g.employer_founded, g.employer_revenue
            FROM staging.stg_glassdoor g
            WHERE g.employer_name IS NOT NULL
            ORDER BY g.employer_name
            ON CONFLICT (employer_name) DO UPDATE SET
                score_geral = EXCLUDED.score_geral,
                score_cultura = EXCLUDED.score_cultura,
                score_remuneracao = EXCLUDED.score_remuneracao,
                pct_recomendam = EXCLUDED.pct_recomendam;

            -- 4. fato_reclamacoes
            TRUNCATE TABLE dw.fato_reclamacoes CASCADE;

            INSERT INTO dw.fato_reclamacoes (
                sk_instituicao, sk_tempo, sk_clima, indice_reclamacao,
                qtd_reclamacoes_procedentes, qtd_reclamacoes_outras, qtd_reclamacoes_nao_reguladas,
                qtd_total_reclamacoes, qtd_total_clientes_ccs_scr, qtd_clientes_ccs, qtd_clientes_scr
            )
            SELECT 
                di.sk_instituicao,
                dt.sk_tempo,
                dc.sk_clima,
                r.indice_reclamacao,
                COALESCE(r.qtd_reclamacoes_procedentes, 0),
                COALESCE(r.qtd_reclamacoes_outras, 0),
                COALESCE(r.qtd_reclamacoes_nao_reguladas, 0),
                COALESCE(r.qtd_total_reclamacoes, 0),
                COALESCE(r.qtd_total_clientes_ccs_scr, 0),
                COALESCE(r.qtd_clientes_ccs, 0),
                COALESCE(r.qtd_clientes_scr, 0)
            FROM staging.stg_reclamacoes r
            INNER JOIN dw.dim_tempo dt ON dt.ano = r.ano AND dt.trimestre = r.trimestre
            LEFT JOIN dw.dim_instituicao di ON di.nome_instituicao = TRIM(r.instituicao_financeira)
            LEFT JOIN dw.dim_clima_organizacional dc ON LOWER(dc.employer_name) LIKE CONCAT('%', LOWER(SPLIT_PART(r.instituicao_financeira, ' ', 1)), '%');
        """)
    conn.commit()

    run_sql_script(conn, sql_final)
    with conn.cursor() as cur:
        cur.execute("""
            TRUNCATE TABLE dw.tb_final_consolidada_reclamacoes;

            INSERT INTO dw.tb_final_consolidada_reclamacoes (
                ano, trimestre, rotulo_trimestre, cnpj_if, nome_instituicao, segmento,
                categoria, tipo_instituicao, indice_reclamacao, qtd_reclamacoes_procedentes,
                qtd_reclamacoes_outras, qtd_reclamacoes_nao_reguladas, qtd_total_reclamacoes,
                qtd_total_clientes_ccs_scr, qtd_clientes_ccs, qtd_clientes_scr, employer_name,
                score_geral_glassdoor, score_cultura_glassdoor, score_remuneracao_glassdoor,
                score_qualidade_vida_glassdoor, score_lideranca_glassdoor, score_carreira_glassdoor,
                pct_recomendam_glassdoor, pct_perspectiva_positiva_glassdoor
            )
            SELECT 
                t.ano, t.trimestre, t.rotulo_trimestre, i.cnpj_if, i.nome_instituicao, i.segmento,
                i.categoria, i.tipo_instituicao, f.indice_reclamacao, f.qtd_reclamacoes_procedentes,
                f.qtd_reclamacoes_outras, f.qtd_reclamacoes_nao_reguladas, f.qtd_total_reclamacoes,
                f.qtd_total_clientes_ccs_scr, f.qtd_clientes_ccs, f.qtd_clientes_scr, c.employer_name,
                c.score_geral AS score_geral_glassdoor,
                c.score_cultura AS score_cultura_glassdoor,
                c.score_remuneracao AS score_remuneracao_glassdoor,
                c.score_qualidade_vida AS score_qualidade_vida_glassdoor,
                c.score_lideranca AS score_lideranca_glassdoor,
                c.score_carreira AS score_carreira_glassdoor,
                c.pct_recomendam AS pct_recomendam_glassdoor,
                c.pct_perspectiva_positiva AS pct_perspectiva_positiva_glassdoor
            FROM dw.fato_reclamacoes f
            INNER JOIN dw.dim_instituicao i ON f.sk_instituicao = i.sk_instituicao
            INNER JOIN dw.dim_tempo t ON f.sk_tempo = t.sk_tempo
            LEFT JOIN dw.dim_clima_organizacional c ON f.sk_clima = c.sk_clima;
        """)
    conn.commit()
    print("Star Schema and Final Consolidated Table built successfully!")

def main():
    print("=== Starting ETL Execution Pipeline ===")
    conn = get_connection()
    try:
        # Step 1: Ensure Staging tables exist
        run_sql_script(conn, os.path.join(BASE_DIR, "sql", "01_create_staging_tables.sql"))
        
        # Step 2: Ingest raw files into Staging
        ingest_enquadramento(conn)
        ingest_glassdoor(conn)
        ingest_reclamacoes(conn)
        
        # Step 3: Populate Star Schema and Final Consolidated Table
        execute_star_schema_and_final(conn)
        
        print("=== ETL Execution Completed Successfully! ===")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
