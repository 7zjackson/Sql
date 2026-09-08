CREATE TABLE matricula (
    id int SERIAL PRIMARY KEY,
    data_matricula DATE NOT NULL,
    data_inicio DATE,
    data_termino DATE,
    status VARCHAR(30)
);

DROP TABLE IF EXISTS matricula CASCADE;

CREATE TABLE matricula (
id_matricula SERIAL PRIMARY KEY,
id_aluno INT NOT NULL,
id_turma INT NOT NULL,
id_plano INT NOT NULL,
data_matricula DATE NOT NULL,
data_inicio DATE NOT NULL,
data_termino DATE,
status VARCHAR(30) DEFAULT 'Ativa',
FOREIGN KEY (id_aluno) REFERENCES aluno(id_aluno) ON DELETE CASCADE,
FOREIGN KEY (id_turma) REFERENCES turma(id_turma) ON DELETE CASCADE,
FOREIGN KEY (id_plano) REFERENCES plano(id_plano) ON DELETE CASCADE
);