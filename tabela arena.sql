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

CREATE TABLE turma (
    id_turma SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    dia_semana VARCHAR(20),
    horario_inicio TIME,
    horario_fim TIME,
    nivel VARCHAR(30),
    vagas_maximas INT,
    ativa BOOLEAN
);

CREATE TABLE matricula (
    id_matricula SERIAL PRIMARY KEY,
    data_matricula DATE NOT NULL,
    data_inicio DATE,
    data_termino DATE,
    status VARCHAR(30)
);
CREATE TABLE turma (
    id_turma SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    dia_semana VARCHAR(20),
    horario_inicio TIME,
    horario_fim TIME,
    nivel VARCHAR(30),
    vagas_maximas INT,
    ativa BOOLEAN
);

CREATE TABLE mensalidade (
    id_mensalidade SERIAL PRIMARY KEY,
    mes_referencia VARCHAR(7),
    data_vencimento DATE NOT NULL,
    data_pagamento DATE,
    valor NUMERIC(10, 2),
    forma_pagamento VARCHAR(30),
    status VARCHAR(30)
);

CREATE TABLE locacao (
    id_locacao SERIAL PRIMARY KEY,
    data_locacao DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fim TIME NOT NULL,
    valor_total NUMERIC(10, 2),
    forma_pagamento VARCHAR(30),
    status VARCHAR(30)
);
