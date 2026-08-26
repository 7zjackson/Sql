CREATE TABLE plano (
    id int SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    descricao VARCHAR(200),
    frequencia_semanal INT,
    duracao_meses INT,
    valor NUMERIC(10, 2),
    ativo BOOLEAN
);
