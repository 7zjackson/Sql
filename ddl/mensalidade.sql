CREATE TABLE mensalidade (
    id int SERIAL PRIMARY KEY,
    mes_referencia VARCHAR(7),
    data_vencimento DATE NOT NULL,
    data_pagamento DATE,
    valor NUMERIC(10, 2),
    forma_pagamento VARCHAR(30),
    status VARCHAR(30)
);
