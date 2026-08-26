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

