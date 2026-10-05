DROP TABLE IF EXISTS matricula CASCADE;

CREATE TABLE matricula (
    id SERIAL PRIMARY KEY,
    id_aluno INT NOT NULL,
    id_turma INT NOT NULL,
    id_plano INT NOT NULL,
    data_matricula DATE NOT NULL,
    data_inicio DATE NOT NULL,
    data_termino DATE,
    status VARCHAR(30) DEFAULT 'Ativa',
    FOREIGN KEY (id_aluno) REFERENCES aluno(id) ON DELETE CASCADE,
    FOREIGN KEY (id_turma) REFERENCES turma(id) ON DELETE CASCADE,
    FOREIGN KEY (id_plano) REFERENCES plano(id) ON DELETE CASCADE
);
