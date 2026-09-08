CREATE TABLE quadra (
    id int SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    coberta BOOLEAN,
    iluminacao BOOLEAN,
    valor_hora NUMERIC(10, 2),
    ativa BOOLEAN
);

DROP TABLE IF EXISTS quadra CASCADE;

CREATE TABLE quadra (
id_quadra SERIAL PRIMARY KEY,
nome VARCHAR(50) NOT NULL,
coberta BOOLEAN DEFAULT FALSE,
iluminacao BOOLEAN DEFAULT FALSE,
valor_hora NUMERIC(10, 2) NOT NULL,
ativa BOOLEAN DEFAULT TRUE
);
