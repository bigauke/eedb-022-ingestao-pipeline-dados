-- Script de Inicialização da Imagem Docker do PostgreSQL
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

-- Staging Tables
CREATE TABLE IF NOT EXISTS staging.stg_enquadramento (
    segmento VARCHAR(255),
    cnpj VARCHAR(20),
    nome VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS staging.stg_glassdoor (
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

CREATE TABLE IF NOT EXISTS staging.stg_reclamacoes (
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

-- Star Schema Tables
CREATE TABLE IF NOT EXISTS dw.dim_instituicao (
    sk_instituicao SERIAL PRIMARY KEY,
    cnpj_if VARCHAR(20),
    nome_instituicao VARCHAR(255) NOT NULL,
    segmento VARCHAR(255),
    categoria VARCHAR(255),
    tipo_instituicao VARCHAR(255),
    CONSTRAINT uk_dim_instituicao UNIQUE (nome_instituicao, segmento)
);

CREATE TABLE IF NOT EXISTS dw.dim_tempo (
    sk_tempo SERIAL PRIMARY KEY,
    ano INT NOT NULL,
    trimestre VARCHAR(10) NOT NULL,
    rotulo_trimestre VARCHAR(20) NOT NULL,
    CONSTRAINT uk_dim_tempo UNIQUE (ano, trimestre)
);

CREATE TABLE IF NOT EXISTS dw.dim_clima_organizacional (
    sk_clima SERIAL PRIMARY KEY,
    employer_name VARCHAR(255) UNIQUE NOT NULL,
    score_geral NUMERIC(3,2),
    score_cultura NUMERIC(3,2),
    score_diversidade NUMERIC(3,2),
    score_qualidade_vida NUMERIC(3,2),
    score_lideranca NUMERIC(3,2),
    score_remuneracao NUMERIC(3,2),
    score_carreira NUMERIC(3,2),
    pct_recomendam NUMERIC(5,2),
    pct_perspectiva_positiva NUMERIC(5,2),
    employer_headquarters VARCHAR(255),
    employer_founded NUMERIC(6,1),
    employer_revenue VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS dw.fato_reclamacoes (
    id_fato SERIAL PRIMARY KEY,
    sk_instituicao INT REFERENCES dw.dim_instituicao(sk_instituicao),
    sk_tempo INT REFERENCES dw.dim_tempo(sk_tempo),
    sk_clima INT REFERENCES dw.dim_clima_organizacional(sk_clima),
    indice_reclamacao NUMERIC(12,4),
    qtd_reclamacoes_procedentes INT DEFAULT 0,
    qtd_reclamacoes_outras INT DEFAULT 0,
    qtd_reclamacoes_nao_reguladas INT DEFAULT 0,
    qtd_total_reclamacoes INT DEFAULT 0,
    qtd_total_clientes_ccs_scr BIGINT DEFAULT 0,
    qtd_clientes_ccs BIGINT DEFAULT 0,
    qtd_clientes_scr BIGINT DEFAULT 0,
    dt_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela Final Consolidada
CREATE TABLE IF NOT EXISTS dw.tb_final_consolidada_reclamacoes (
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
