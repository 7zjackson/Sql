CREATE TABLE matricula (
    id int SERIAL PRIMARY KEY,
    data_matricula DATE NOT NULL,
    data_inicio DATE,
    data_termino DATE,
    status VARCHAR(30)
);

