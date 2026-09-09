CREATE TABLE turma (
id SERIAL PRIMARY KEY,
id_professor INT NOT NULL,
id_nivel INT NOT NULL,
nome VARCHAR(50) NOT NULL,
dia_semana VARCHAR(20) NOT NULL,
horario_inicio TIME NOT NULL,
horario_fim TIME NOT NULL,
vagas_maximas INT NOT NULL,
ativa BOOLEAN DEFAULT TRUE,
FOREIGN KEY (id_professor) REFERENCES professor(id_professor) ON DELETE CASCADE,
FOREIGN KEY (id_nivel) REFERENCES nivel_turma(id_nivel) ON DELETE CASCADE
);
