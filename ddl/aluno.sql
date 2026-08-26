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



