-- Script SQL: Data Warehouse Star Schema (Dimensional Modeling)
CREATE SCHEMA IF NOT EXISTS dw;

-- Dimensão Instituição / Banco
DROP TABLE IF EXISTS dw.dim_instituicao CASCADE;
CREATE TABLE dw.dim_instituicao (
    sk_instituicao SERIAL PRIMARY KEY,
    cnpj_if VARCHAR(20),
    nome_instituicao VARCHAR(255) NOT NULL,
    segmento VARCHAR(255),
    categoria VARCHAR(255),
    tipo_instituicao VARCHAR(255),
    CONSTRAINT uk_dim_instituicao UNIQUE (nome_instituicao, segmento)
);

-- Dimensão Tempo / Calendário
DROP TABLE IF EXISTS dw.dim_tempo CASCADE;
CREATE TABLE dw.dim_tempo (
    sk_tempo SERIAL PRIMARY KEY,
    ano INT NOT NULL,
    trimestre VARCHAR(10) NOT NULL,
    rotulo_trimestre VARCHAR(20) NOT NULL,
    CONSTRAINT uk_dim_tempo UNIQUE (ano, trimestre)
);

-- Dimensão Clima Organizacional (Glassdoor)
DROP TABLE IF EXISTS dw.dim_clima_organizacional CASCADE;
CREATE TABLE dw.dim_clima_organizacional (
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

-- Tabela Fato: Reclamações
DROP TABLE IF EXISTS dw.fato_reclamacoes CASCADE;
CREATE TABLE dw.fato_reclamacoes (
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
