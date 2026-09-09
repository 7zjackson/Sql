DROP TABLE IF EXISTS mensalidade CASCADE;

CREATE TABLE mensalidade (
id SERIAL PRIMARY KEY,
id_matricula INT NOT NULL,
id_forma_pagamento INT NOT NULL,
mes_referencia VARCHAR(7) NOT NULL,
data_vencimento DATE NOT NULL,
data_pagamento DATE,
valor NUMERIC(10, 2) NOT NULL,
status VARCHAR(30) DEFAULT 'Pendente',
FOREIGN KEY (id_matricula) REFERENCES matricula(id_matricula) ON DELETE CASCADE,
FOREIGN KEY (id_forma_pagamento) REFERENCES forma_pagamento(id_forma_pagamento) ON DELETE RESTRICT
);
