CREATE TABLE locacao (
id int SERIAL PRIMARY KEY,
data_locacao DATE NOT NULL,
hora_inicio TIME NOT NULL,
hora_fim TIME NOT NULL,
valor_total NUMERIC(10, 2),
forma_pagamento VARCHAR(30),
status VARCHAR(30)
);
