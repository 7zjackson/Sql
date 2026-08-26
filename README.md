# Modelagem de Banco de Dados - Futevôlei

Trabalho da disciplina de Banco de Dados. Escolhemos como tema uma arena de futevôlei que também dá aula, tipo uma escolinha mesmo, com aluno, professor, turma, plano, mensalidade e locação avulsa de quadra.

Repositório: https://github.com/7zjackson/Sql

## Justificativa do domínio

A gente escolheu esse tema porque futevôlei é um esporte que vem crescendo bastante e a maioria das arenas ainda controla tudo de um jeito bem manual, no caderno ou em grupo de WhatsApp. Dá pra perceber que tem bastante regra de negócio ali: o aluno contrata um plano (por exemplo, 2x por semana ou mensal) e isso gera a matrícula, que por sua vez gera as mensalidades. Além disso o aluno frequenta uma turma, que tem professor, dia e horário definido. E separado disso ainda tem a locação, que é quando alguém aluga a quadra avulsa só pra jogar, sem estar matriculado em nada.

Com o banco montado dá pra saber quem tá em dia com o pagamento, quais turmas têm vaga e como as quadras estão sendo usadas no geral.

## Entidades

- aluno - cadastro dos alunos matriculados na arena
- professor - cadastro dos instrutores que dão as aulas
- quadra - as quadras de areia da arena
- plano - os pacotes que o aluno pode contratar (mensal, trimestral etc)
- turma - os horários de treino, com dia da semana e nível
- matricula - liga o aluno ao plano que ele contratou
- mensalidade - as cobranças geradas pela matrícula
- locacao - reserva avulsa de quadra pra jogo particular ou racha

## Padrão de nomenclatura

Seguimos o artigo Database Naming Standards (DEV Community) que o professor pediu. Resumindo o que usamos:

- tudo em minúsculo
- snake_case (palavra_separada_assim)
- nome de tabela no singular (aluno e não alunos)
- sem acento nos nomes de coluna
- chave primária sempre id_nomedatabela

## Sobre o script

O banco usado foi PostgreSQL. O script tá em `ddl/tabela_arena.sql`.

Como o professor pediu, nessa etapa ainda não colocamos chave estrangeira, só a estrutura básica de cada tabela mesmo. Isso vai entrar na próxima parte do trabalho quando a gente for ligar as tabelas (tipo matricula indicando de qual aluno e de qual plano ela é).

Pra rodar:

```
psql -U postgres -d nome_do_banco -f ddl/tabela_arena.sql
```

## Estrutura das pastas

```
Sql/
├── README.md
└── ddl/
    └── tabela_arena.sql
```

## Sobre o trabalho em grupo

Grupo: Caio Josué, Camilly Ribeiro, Eliã Silva, Julia Gomes e Jackson Souza.

O repositório foi feito no GitHub e cada um ficou responsável por uma parte: alguém criou a estrutura inicial do repositório, outros cuidaram de levantar as entidades e escrever o script das tabelas, e o resto revisou e ajustou os nomes das colunas pra ficar de acordo com o padrão pedido. As alterações foram subidas por Pull Request pra ficar registrado quem fez o quê no histórico do Git.
