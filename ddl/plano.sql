CREATE TABLE plano (
    id int SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    descricao VARCHAR(200),
    frequencia_semanal INT,
    duracao_meses INT,
    valor NUMERIC(10, 2),
    ativo BOOLEAN
);

DROP TABLE IF EXISTS plano CASCADE;

CREATE TABLE plano (
id_plano SERIAL PRIMARY KEY,
nome VARCHAR(50) NOT NULL,
descricao VARCHAR(200),
frequencia_semanal INT NOT NULL,
duracao_meses INT NOT NULL,
valor NUMERIC(10, 2) NOT NULL,
ativo BOOLEAN DEFAULT TRUE
);