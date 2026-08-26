CREATE TABLE quadra (
    id int SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    coberta BOOLEAN,
    iluminacao BOOLEAN,
    valor_hora NUMERIC(10, 2),
    ativa BOOLEAN
);
