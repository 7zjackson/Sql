CREATE TABLE professor (
    id int SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    telefone VARCHAR(15),
    email VARCHAR(100),
    especialidade VARCHAR(100),
    data_contratacao DATE,
    ativo BOOLEAN
);

DROP TABLE IF EXISTS professor CASCADE;

CREATE TABLE professor (
id_professor SERIAL PRIMARY KEY,
nome VARCHAR(100) NOT NULL,
cpf VARCHAR(11) NOT NULL UNIQUE,
telefone VARCHAR(15),
email VARCHAR(100) UNIQUE,
especialidade VARCHAR(100),
data_contratacao DATE NOT NULL,
ativo BOOLEAN DEFAULT TRUE
);
