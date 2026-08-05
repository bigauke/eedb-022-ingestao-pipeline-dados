-- Script SQL: Staging Zone Schema & Tables
CREATE SCHEMA IF NOT EXISTS staging;

-- Tabela Staging: Enquadramento dos Bancos (BACEN)
DROP TABLE IF EXISTS staging.stg_enquadramento CASCADE;
CREATE TABLE staging.stg_enquadramento (
    segmento VARCHAR(255),
    cnpj VARCHAR(20),
    nome VARCHAR(255)
);

-- Tabela Staging: Clima Organizacional & Avaliações (Glassdoor)
DROP TABLE IF EXISTS staging.stg_glassdoor CASCADE;
CREATE TABLE staging.stg_glassdoor (
    employer_name VARCHAR(255),
    reviews_count INT,
    culture_count INT,
    salaries_count INT,
    benefits_count INT,
    employer_website VARCHAR(500),
    employer_headquarters VARCHAR(255),
    employer_founded NUMERIC(6,1),
    employer_industry VARCHAR(500),
    employer_revenue VARCHAR(255),
    url VARCHAR(500),
    score_geral NUMERIC(3,2),
    score_cultura NUMERIC(3,2),
    score_diversidade NUMERIC(3,2),
    score_qualidade_vida NUMERIC(3,2),
    score_lideranca NUMERIC(3,2),
    score_remuneracao NUMERIC(3,2),
    score_carreira NUMERIC(3,2),
    pct_recomendam NUMERIC(5,2),
    pct_perspectiva_positiva NUMERIC(5,2),
    segmento VARCHAR(255),
    nome VARCHAR(255),
    match_percent INT
);

-- Tabela Staging: Reclamações do Banco Central (BACEN - 2021/2022)
DROP TABLE IF EXISTS staging.stg_reclamacoes CASCADE;
CREATE TABLE staging.stg_reclamacoes (
    ano INT,
    trimestre VARCHAR(10),
    categoria VARCHAR(255),
    tipo VARCHAR(255),
    cnpj_if VARCHAR(20),
    instituicao_financeira VARCHAR(255),
    indice_reclamacao NUMERIC(12,4),
    qtd_reclamacoes_procedentes INT,
    qtd_reclamacoes_outras INT,
    qtd_reclamacoes_nao_reguladas INT,
    qtd_total_reclamacoes INT,
    qtd_total_clientes_ccs_scr BIGINT,
    qtd_clientes_ccs BIGINT,
    qtd_clientes_scr BIGINT
);
