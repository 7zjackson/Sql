CREATE TABLE aluno (
    id_aluno SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    data_nascimento DATE,
    sexo VARCHAR(20),
    telefone VARCHAR(15),
    email VARCHAR(100),
    data_cadastro DATE,
    ativo BOOLEAN
);

CREATE TABLE professor (
    id_professor SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    telefone VARCHAR(15),
    email VARCHAR(100),
    especialidade VARCHAR(100),
    data_contratacao DATE,
    ativo BOOLEAN
);

CREATE TABLE quadra (
    id_quadra SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    coberta BOOLEAN,
    iluminacao BOOLEAN,
    valor_hora NUMERIC(10, 2),
    ativa BOOLEAN
);

CREATE TABLE plano (
    id_plano SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    descricao VARCHAR(200),
    frequencia_semanal INT,
    duracao_meses INT,
    valor NUMERIC(10, 2),
    ativo BOOLEAN
);

