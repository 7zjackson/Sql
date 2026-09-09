DROP TABLE IF EXISTS locacao CASCADE;

CREATE TABLE locacao (
id SERIAL PRIMARY KEY,
id_aluno INT NOT NULL,
id_quadra INT NOT NULL,
id_forma_pagamento INT NOT NULL,
data_locacao DATE NOT NULL,
hora_inicio TIME NOT NULL,
hora_fim TIME NOT NULL,
valor_total NUMERIC(10, 2) NOT NULL,
status VARCHAR(30) DEFAULT 'Confirmada',
FOREIGN KEY (id_aluno) REFERENCES aluno(id_aluno) ON DELETE CASCADE,
FOREIGN KEY (id_quadra) REFERENCES quadra(id_quadra) ON DELETE CASCADE,
FOREIGN KEY (id_forma_pagamento) REFERENCES forma_pagamento(id_forma_pagamento) ON DELETE RESTRICT
);
