-- Script SQL: Tabela Final Consolidada (Tratada e Unida)
CREATE SCHEMA IF NOT EXISTS dw;

DROP VIEW IF EXISTS dw.vw_resumo_reclamacoes_por_segmento CASCADE;
DROP TABLE IF EXISTS dw.tb_final_consolidada_reclamacoes CASCADE;

CREATE TABLE dw.tb_final_consolidada_reclamacoes (
    id_consolidado SERIAL PRIMARY KEY,
    ano INT,
    trimestre VARCHAR(10),
    rotulo_trimestre VARCHAR(20),
    cnpj_if VARCHAR(20),
    nome_instituicao VARCHAR(255),
    segmento VARCHAR(255),
    categoria VARCHAR(255),
    tipo_instituicao VARCHAR(255),
    indice_reclamacao NUMERIC(12,4),
    qtd_reclamacoes_procedentes INT,
    qtd_reclamacoes_outras INT,
    qtd_reclamacoes_nao_reguladas INT,
    qtd_total_reclamacoes INT,
    qtd_total_clientes_ccs_scr BIGINT,
    qtd_clientes_ccs BIGINT,
    qtd_clientes_scr BIGINT,
    employer_name VARCHAR(255),
    score_geral_glassdoor NUMERIC(3,2),
    score_cultura_glassdoor NUMERIC(3,2),
    score_remuneracao_glassdoor NUMERIC(3,2),
    score_qualidade_vida_glassdoor NUMERIC(3,2),
    score_lideranca_glassdoor NUMERIC(3,2),
    score_carreira_glassdoor NUMERIC(3,2),
    pct_recomendam_glassdoor NUMERIC(5,2),
    pct_perspectiva_positiva_glassdoor NUMERIC(5,2),
    dt_processamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- View Analítica de Suporte
CREATE VIEW dw.vw_resumo_reclamacoes_por_segmento AS
SELECT 
    f.segmento,
    COUNT(DISTINCT f.nome_instituicao) AS total_instituicoes,
    SUM(f.qtd_total_reclamacoes) AS total_reclamacoes,
    SUM(f.qtd_reclamacoes_procedentes) AS total_procedentes,
    AVG(f.score_geral_glassdoor) AS media_score_glassdoor,
    AVG(f.pct_recomendam_glassdoor) AS media_pct_recomendacao
FROM dw.tb_final_consolidada_reclamacoes f
GROUP BY f.segmento
ORDER BY total_reclamacoes DESC;
