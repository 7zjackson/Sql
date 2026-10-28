-- ============================================================================
-- PROCEDURES E FUNCTIONS - OFICINA MECANICA
-- PostgreSQL. Rodar depois do DDL e do DML.
-- ============================================================================

-- ============================================================================
-- 0. ALTERACOES NA ESTRUTURA (precisamos de umas colunas a mais)
-- ============================================================================

-- atendente da OS e valores parciais
ALTER TABLE ordens_servico ADD COLUMN IF NOT EXISTS atendente_id INT;
ALTER TABLE ordens_servico ADD COLUMN IF NOT EXISTS valor_pecas DECIMAL(10,2) NOT NULL DEFAULT 0;
ALTER TABLE ordens_servico ADD COLUMN IF NOT EXISTS valor_mao_obra DECIMAL(10,2) NOT NULL DEFAULT 0;

-- reserva de estoque (disponivel = quantidade_atual - quantidade_reservada)
ALTER TABLE estoques ADD COLUMN IF NOT EXISTS quantidade_reservada INT NOT NULL DEFAULT 0;

-- dados da nota do fornecedor
ALTER TABLE movimentacoes_estoque ADD COLUMN IF NOT EXISTS fornecedor_id INT;
ALTER TABLE movimentacoes_estoque ADD COLUMN IF NOT EXISTS nota_fiscal VARCHAR(30);
ALTER TABLE movimentacoes_estoque ADD COLUMN IF NOT EXISTS preco_unitario DECIMAL(10,2);

-- juros e desconto do pagamento
ALTER TABLE pagamentos ADD COLUMN IF NOT EXISTS valor_juros DECIMAL(10,2) NOT NULL DEFAULT 0;
ALTER TABLE pagamentos ADD COLUMN IF NOT EXISTS valor_desconto DECIMAL(10,2) NOT NULL DEFAULT 0;

-- cobranca gerada quando a OS e finalizada
CREATE TABLE IF NOT EXISTS cobrancas (
    id               INT PRIMARY KEY,
    ordem_servico_id INT NOT NULL,
    valor            DECIMAL(10,2) NOT NULL,
    data_emissao     DATE NOT NULL,
    data_vencimento  DATE NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'PENDENTE'
);

-- categoria dos servicos (freios, motor...), usada na function de faturamento
CREATE TABLE IF NOT EXISTS categorias_servico (
    id        INT PRIMARY KEY,
    descricao VARCHAR(80) NOT NULL
);
ALTER TABLE servicos ADD COLUMN IF NOT EXISTS categoria_servico_id INT;

INSERT INTO categorias_servico (id, descricao) VALUES
(1, 'Motor'),
(2, 'Freios'),
(3, 'Suspensão'),
(4, 'Elétrica')
ON CONFLICT (id) DO NOTHING;

UPDATE servicos SET categoria_servico_id = 1 WHERE nome = 'Troca de Óleo';
UPDATE servicos SET categoria_servico_id = 3 WHERE nome = 'Alinhamento e Balanceamento';
UPDATE servicos SET categoria_servico_id = 2 WHERE nome = 'Revisão de Freios';
UPDATE servicos SET categoria_servico_id = 4 WHERE nome = 'Troca de Bateria';


-- ============================================================================
-- 1. FUNCTIONS
-- ============================================================================

-- 1. fc_calcular_valor_total_os
-- soma das pecas (quantidade * preco) + mao de obra (valor_cobrado)
CREATE OR REPLACE FUNCTION fc_calcular_valor_total_os(p_os_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_pecas NUMERIC;
    v_mao_obra NUMERIC;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ordens_servico WHERE id = p_os_id) THEN
        RAISE EXCEPTION 'OS % nao encontrada', p_os_id;
    END IF;

    SELECT COALESCE(SUM(quantidade * preco_unitario), 0) INTO v_pecas
    FROM ordens_servico_pecas
    WHERE ordem_servico_id = p_os_id;

    SELECT COALESCE(SUM(valor_cobrado), 0) INTO v_mao_obra
    FROM ordens_servico_servicos
    WHERE ordem_servico_id = p_os_id;

    RETURN v_pecas + v_mao_obra;
END;
$$;


-- 2. fc_total_gasto_cliente
-- total das OS concluidas do cliente (CONCLUIDA, FINALIZADA ou PAGA)
CREATE OR REPLACE FUNCTION fc_total_gasto_cliente(p_cliente_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE id = p_cliente_id) THEN
        RAISE EXCEPTION 'Cliente % nao encontrado', p_cliente_id;
    END IF;

    SELECT COALESCE(SUM(fc_calcular_valor_total_os(id)), 0) INTO v_total
    FROM ordens_servico
    WHERE cliente_id = p_cliente_id
      AND status IN ('CONCLUIDA', 'FINALIZADA', 'PAGA');

    RETURN v_total;
END;
$$;


-- 3. fc_verificar_peca_estoque_critico
-- true se o disponivel (atual - reservado) for menor que o minimo
CREATE OR REPLACE FUNCTION fc_verificar_peca_estoque_critico(p_peca_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_disponivel INT;
    v_minimo INT;
BEGIN
    SELECT quantidade_atual - quantidade_reservada, quantidade_minima
    INTO v_disponivel, v_minimo
    FROM estoques
    WHERE peca_id = p_peca_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Peca % sem registro de estoque', p_peca_id;
    END IF;

    RETURN v_disponivel < v_minimo;
END;
$$;


-- 4. fc_produtividade_mensal_mecanico
-- retorna qtd de OS concluidas e total de mao de obra do mecanico no mes/ano
CREATE OR REPLACE FUNCTION fc_produtividade_mensal_mecanico(p_funcionario_id INT, p_mes INT, p_ano INT)
RETURNS TABLE (qtd_os_concluidas INT, valor_mao_obra NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_mes < 1 OR p_mes > 12 THEN
        RAISE EXCEPTION 'Mes invalido: %', p_mes;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM funcionarios WHERE id = p_funcionario_id) THEN
        RAISE EXCEPTION 'Funcionario % nao encontrado', p_funcionario_id;
    END IF;

    RETURN QUERY
    SELECT
        (SELECT COUNT(*)::INT
         FROM ordens_servico os
         WHERE os.status IN ('CONCLUIDA', 'FINALIZADA', 'PAGA')
           AND EXTRACT(MONTH FROM os.data_conclusao) = p_mes
           AND EXTRACT(YEAR FROM os.data_conclusao) = p_ano
           AND (os.funcionario_id = p_funcionario_id
                OR EXISTS (SELECT 1 FROM ordens_servico_servicos oss
                           WHERE oss.ordem_servico_id = os.id
                             AND oss.funcionario_id = p_funcionario_id))),
        (SELECT COALESCE(SUM(oss.valor_cobrado), 0)
         FROM ordens_servico_servicos oss
         JOIN ordens_servico os ON os.id = oss.ordem_servico_id
         WHERE oss.funcionario_id = p_funcionario_id
           AND os.status IN ('CONCLUIDA', 'FINALIZADA', 'PAGA')
           AND EXTRACT(MONTH FROM os.data_conclusao) = p_mes
           AND EXTRACT(YEAR FROM os.data_conclusao) = p_ano);
END;
$$;


-- 5. fc_faturamento_por_categoria_servico
-- total faturado de uma categoria (ex: 'Freios') entre duas datas
CREATE OR REPLACE FUNCTION fc_faturamento_por_categoria_servico(p_categoria VARCHAR, p_data_inicio DATE, p_data_fim DATE)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_categoria_id INT;
    v_total NUMERIC;
BEGIN
    IF p_data_inicio > p_data_fim THEN
        RAISE EXCEPTION 'Data inicial maior que a data final';
    END IF;

    SELECT id INTO v_categoria_id
    FROM categorias_servico
    WHERE LOWER(descricao) = LOWER(p_categoria);

    IF v_categoria_id IS NULL THEN
        RAISE EXCEPTION 'Categoria % nao encontrada', p_categoria;
    END IF;

    SELECT COALESCE(SUM(oss.valor_cobrado), 0) INTO v_total
    FROM ordens_servico_servicos oss
    JOIN servicos s ON s.id = oss.servico_id
    JOIN ordens_servico os ON os.id = oss.ordem_servico_id
    WHERE s.categoria_servico_id = v_categoria_id
      AND os.status IN ('CONCLUIDA', 'FINALIZADA', 'PAGA')
      AND os.data_conclusao::DATE BETWEEN p_data_inicio AND p_data_fim;

    RETURN v_total;
END;
$$;


-- ============================================================================
-- 2. PROCEDURES
-- ============================================================================

-- 1. sp_abrir_ordem_servico
-- valida cliente, veiculo, mecanico e atendente e abre a OS como EM_ANALISE
-- o id da nova OS volta no ultimo parametro (passar NULL)
CREATE OR REPLACE PROCEDURE sp_abrir_ordem_servico(
    p_cliente_id INT,
    p_veiculo_id INT,
    p_mecanico_id INT,
    p_atendente_id INT,
    p_observacoes VARCHAR DEFAULT NULL,
    p_data_previsao DATE DEFAULT NULL,
    INOUT p_os_id INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE id = p_cliente_id) THEN
        RAISE EXCEPTION 'Cliente % nao cadastrado', p_cliente_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM clientes WHERE id = p_cliente_id AND ativo = TRUE) THEN
        RAISE EXCEPTION 'Cliente % esta inativo', p_cliente_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM veiculos WHERE id = p_veiculo_id AND cliente_id = p_cliente_id) THEN
        RAISE EXCEPTION 'Veiculo % nao existe ou nao pertence ao cliente %', p_veiculo_id, p_cliente_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM funcionarios f
                   JOIN tipos_funcionario t ON t.id = f.tipo_funcionario_id
                   WHERE f.id = p_mecanico_id AND f.ativo = TRUE AND t.descricao = 'Mecânico') THEN
        RAISE EXCEPTION 'Funcionario % nao e um mecanico ativo', p_mecanico_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM funcionarios f
                   JOIN tipos_funcionario t ON t.id = f.tipo_funcionario_id
                   WHERE f.id = p_atendente_id AND f.ativo = TRUE AND t.descricao = 'Atendente') THEN
        RAISE EXCEPTION 'Funcionario % nao e um atendente ativo', p_atendente_id;
    END IF;

    SELECT COALESCE(MAX(id), 0) + 1 INTO p_os_id FROM ordens_servico;

    INSERT INTO ordens_servico (id, cliente_id, veiculo_id, funcionario_id, atendente_id,
                                data_abertura, data_previsao, status, valor_total, observacoes)
    VALUES (p_os_id, p_cliente_id, p_veiculo_id, p_mecanico_id, p_atendente_id,
            CURRENT_TIMESTAMP, p_data_previsao, 'EM_ANALISE', 0, p_observacoes);
END;
$$;


-- 2. sp_adicionar_peca_ordem_servico
-- confere o estoque disponivel, reserva a quantidade e atualiza o valor das pecas da OS
CREATE OR REPLACE PROCEDURE sp_adicionar_peca_ordem_servico(
    p_os_id INT,
    p_peca_id INT,
    p_quantidade INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_preco NUMERIC;
    v_disponivel INT;
    v_item_id INT;
BEGIN
    IF p_quantidade <= 0 THEN
        RAISE EXCEPTION 'Quantidade tem que ser maior que zero';
    END IF;

    SELECT status INTO v_status FROM ordens_servico WHERE id = p_os_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'OS % nao encontrada', p_os_id;
    END IF;
    IF v_status NOT IN ('EM_ANALISE', 'ABERTA', 'EM_ANDAMENTO') THEN
        RAISE EXCEPTION 'OS % esta com status % e nao aceita pecas', p_os_id, v_status;
    END IF;

    SELECT preco_venda INTO v_preco FROM pecas WHERE id = p_peca_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Peca % nao cadastrada', p_peca_id;
    END IF;

    SELECT quantidade_atual - quantidade_reservada INTO v_disponivel
    FROM estoques WHERE peca_id = p_peca_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Peca % sem registro de estoque', p_peca_id;
    END IF;
    IF v_disponivel < p_quantidade THEN
        RAISE EXCEPTION 'Estoque insuficiente da peca % (disponivel: %, pedido: %)', p_peca_id, v_disponivel, p_quantidade;
    END IF;

    -- reserva
    UPDATE estoques
    SET quantidade_reservada = quantidade_reservada + p_quantidade,
        data_atualizacao = CURRENT_DATE
    WHERE peca_id = p_peca_id;

    -- se a peca ja esta na OS soma a quantidade, senao insere
    SELECT id INTO v_item_id FROM ordens_servico_pecas
    WHERE ordem_servico_id = p_os_id AND peca_id = p_peca_id;

    IF FOUND THEN
        UPDATE ordens_servico_pecas SET quantidade = quantidade + p_quantidade WHERE id = v_item_id;
    ELSE
        INSERT INTO ordens_servico_pecas (id, ordem_servico_id, peca_id, quantidade, preco_unitario)
        SELECT COALESCE(MAX(id), 0) + 1, p_os_id, p_peca_id, p_quantidade, v_preco
        FROM ordens_servico_pecas;
    END IF;

    -- valor parcial das pecas
    UPDATE ordens_servico
    SET valor_pecas = (SELECT COALESCE(SUM(quantidade * preco_unitario), 0)
                       FROM ordens_servico_pecas WHERE ordem_servico_id = p_os_id)
    WHERE id = p_os_id;
END;
$$;


-- 3. sp_finalizar_ordem_servico
-- da baixa definitiva no estoque, soma peca + mao de obra, muda o status e gera a cobranca
CREATE OR REPLACE PROCEDURE sp_finalizar_ordem_servico(
    p_os_id INT,
    p_data_vencimento DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_item RECORD;
    v_pecas NUMERIC;
    v_mao_obra NUMERIC;
    v_vencimento DATE;
BEGIN
    SELECT status INTO v_status FROM ordens_servico WHERE id = p_os_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'OS % nao encontrada', p_os_id;
    END IF;
    IF v_status NOT IN ('EM_ANALISE', 'ABERTA', 'EM_ANDAMENTO') THEN
        RAISE EXCEPTION 'OS % esta com status % e nao pode ser finalizada', p_os_id, v_status;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ordens_servico_pecas WHERE ordem_servico_id = p_os_id)
       AND NOT EXISTS (SELECT 1 FROM ordens_servico_servicos WHERE ordem_servico_id = p_os_id) THEN
        RAISE EXCEPTION 'OS % nao tem pecas nem servicos', p_os_id;
    END IF;

    -- se nao informar vencimento, 7 dias
    v_vencimento := COALESCE(p_data_vencimento, CURRENT_DATE + 7);

    -- baixa no estoque (tira do saldo e da reserva) e registra a saida
    FOR v_item IN SELECT peca_id, quantidade FROM ordens_servico_pecas WHERE ordem_servico_id = p_os_id
    LOOP
        UPDATE estoques
        SET quantidade_atual = quantidade_atual - v_item.quantidade,
            quantidade_reservada = quantidade_reservada - v_item.quantidade,
            data_atualizacao = CURRENT_DATE
        WHERE peca_id = v_item.peca_id
          AND quantidade_atual >= v_item.quantidade
          AND quantidade_reservada >= v_item.quantidade;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Problema no estoque/reserva da peca % (OS %)', v_item.peca_id, p_os_id;
        END IF;

        INSERT INTO movimentacoes_estoque (id, peca_id, tipo_movimentacao, quantidade, data_movimentacao, observacao)
        SELECT COALESCE(MAX(id), 0) + 1, v_item.peca_id, 'SAIDA', v_item.quantidade,
               CURRENT_TIMESTAMP, 'Uso na ordem de servico ' || p_os_id
        FROM movimentacoes_estoque;
    END LOOP;

    SELECT COALESCE(SUM(quantidade * preco_unitario), 0) INTO v_pecas
    FROM ordens_servico_pecas WHERE ordem_servico_id = p_os_id;

    SELECT COALESCE(SUM(valor_cobrado), 0) INTO v_mao_obra
    FROM ordens_servico_servicos WHERE ordem_servico_id = p_os_id;

    UPDATE ordens_servico
    SET status = 'FINALIZADA',
        data_conclusao = CURRENT_TIMESTAMP,
        valor_pecas = v_pecas,
        valor_mao_obra = v_mao_obra,
        valor_total = v_pecas + v_mao_obra
    WHERE id = p_os_id;

    -- cobranca
    INSERT INTO cobrancas (id, ordem_servico_id, valor, data_emissao, data_vencimento, status)
    SELECT COALESCE(MAX(id), 0) + 1, p_os_id, v_pecas + v_mao_obra, CURRENT_DATE, v_vencimento, 'PENDENTE'
    FROM cobrancas;
END;
$$;


-- 4. sp_registrar_pagamento_os
-- regras de juros e desconto:
--   Dinheiro e Pix: 5% de desconto
--   Cartao de Credito: ate 12x, juros de 2% por parcela alem da primeira
--   outras formas: so 1 parcela
--   pagamento atrasado: multa de 2% + 0,033% por dia
-- valor pago = valor da cobranca - desconto + juros
CREATE OR REPLACE PROCEDURE sp_registrar_pagamento_os(
    p_os_id INT,
    p_forma_pagamento_id INT,
    p_parcelas INT DEFAULT 1,
    p_desconto_extra NUMERIC DEFAULT 0
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_forma VARCHAR(30);
    v_cobranca_id INT;
    v_valor NUMERIC;
    v_vencimento DATE;
    v_desconto NUMERIC := 0;
    v_juros NUMERIC := 0;
    v_atraso INT;
BEGIN
    SELECT status INTO v_status FROM ordens_servico WHERE id = p_os_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'OS % nao encontrada', p_os_id;
    END IF;
    IF v_status = 'PAGA' THEN
        RAISE EXCEPTION 'OS % ja esta paga', p_os_id;
    END IF;
    IF v_status NOT IN ('FINALIZADA', 'CONCLUIDA') THEN
        RAISE EXCEPTION 'OS % esta com status % (precisa estar finalizada)', p_os_id, v_status;
    END IF;

    SELECT descricao INTO v_forma FROM formas_pagamento WHERE id = p_forma_pagamento_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Forma de pagamento % nao cadastrada', p_forma_pagamento_id;
    END IF;

    IF p_parcelas < 1 OR p_parcelas > 12 THEN
        RAISE EXCEPTION 'Numero de parcelas invalido: %', p_parcelas;
    END IF;
    IF v_forma <> 'Cartão de Crédito' AND p_parcelas > 1 THEN
        RAISE EXCEPTION '% aceita apenas 1 parcela', v_forma;
    END IF;

    -- pega a cobranca pendente (as OS antigas CONCLUIDA nao tem, entao cria uma)
    SELECT id, valor, data_vencimento INTO v_cobranca_id, v_valor, v_vencimento
    FROM cobrancas
    WHERE ordem_servico_id = p_os_id AND status = 'PENDENTE';

    IF NOT FOUND THEN
        v_valor := fc_calcular_valor_total_os(p_os_id);
        v_vencimento := CURRENT_DATE;
        SELECT COALESCE(MAX(id), 0) + 1 INTO v_cobranca_id FROM cobrancas;
        INSERT INTO cobrancas (id, ordem_servico_id, valor, data_emissao, data_vencimento, status)
        VALUES (v_cobranca_id, p_os_id, v_valor, CURRENT_DATE, v_vencimento, 'PENDENTE');
    END IF;

    -- desconto
    IF v_forma IN ('Dinheiro', 'Pix') THEN
        v_desconto := ROUND(v_valor * 0.05, 2);
    END IF;
    IF p_desconto_extra < 0 OR p_desconto_extra > v_valor - v_desconto THEN
        RAISE EXCEPTION 'Desconto extra invalido: %', p_desconto_extra;
    END IF;
    v_desconto := v_desconto + p_desconto_extra;

    -- juros do parcelamento
    IF v_forma = 'Cartão de Crédito' AND p_parcelas > 1 THEN
        v_juros := ROUND(v_valor * 0.02 * (p_parcelas - 1), 2);
    END IF;

    -- multa por atraso
    v_atraso := CURRENT_DATE - v_vencimento;
    IF v_atraso > 0 THEN
        v_juros := v_juros + ROUND(v_valor * (0.02 + 0.00033 * v_atraso), 2);
    END IF;

    INSERT INTO pagamentos (id, ordem_servico_id, forma_pagamento_id, valor, data_pagamento, parcelas, valor_juros, valor_desconto)
    SELECT COALESCE(MAX(id), 0) + 1, p_os_id, p_forma_pagamento_id, v_valor - v_desconto + v_juros,
           CURRENT_TIMESTAMP, p_parcelas, v_juros, v_desconto
    FROM pagamentos;

    UPDATE cobrancas SET status = 'PAGA' WHERE id = v_cobranca_id;
    UPDATE ordens_servico SET status = 'PAGA' WHERE id = p_os_id;
END;
$$;


-- 5. sp_dar_entrada_estoque_fornecedor
-- registra a nota do fornecedor. Os itens vao em JSON, exemplo:
-- '[{"peca_id":3,"quantidade":10,"preco_custo":47.50}]'
-- soma no estoque, atualiza o preco de custo e grava a movimentacao de ENTRADA
CREATE OR REPLACE PROCEDURE sp_dar_entrada_estoque_fornecedor(
    p_fornecedor_id INT,
    p_numero_nota VARCHAR,
    p_itens JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_item JSONB;
    v_peca_id INT;
    v_qtd INT;
    v_custo NUMERIC;
    v_razao VARCHAR(150);
BEGIN
    SELECT razao_social INTO v_razao FROM fornecedores WHERE id = p_fornecedor_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Fornecedor % nao cadastrado', p_fornecedor_id;
    END IF;

    IF EXISTS (SELECT 1 FROM movimentacoes_estoque
               WHERE fornecedor_id = p_fornecedor_id AND nota_fiscal = p_numero_nota) THEN
        RAISE EXCEPTION 'Nota % ja foi lancada', p_numero_nota;
    END IF;

    IF p_itens IS NULL OR jsonb_array_length(p_itens) = 0 THEN
        RAISE EXCEPTION 'A nota precisa ter pelo menos um item';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_itens)
    LOOP
        v_peca_id := (v_item ->> 'peca_id')::INT;
        v_qtd := (v_item ->> 'quantidade')::INT;
        v_custo := (v_item ->> 'preco_custo')::NUMERIC;

        IF v_qtd IS NULL OR v_qtd <= 0 OR v_custo IS NULL OR v_custo <= 0 THEN
            RAISE EXCEPTION 'Item invalido: %', v_item;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pecas WHERE id = v_peca_id AND fornecedor_id = p_fornecedor_id) THEN
            RAISE EXCEPTION 'Peca % nao existe ou nao e do fornecedor %', v_peca_id, v_razao;
        END IF;

        UPDATE estoques
        SET quantidade_atual = quantidade_atual + v_qtd,
            data_atualizacao = CURRENT_DATE
        WHERE peca_id = v_peca_id;

        -- se a peca ainda nao tem estoque cadastrado
        IF NOT FOUND THEN
            INSERT INTO estoques (id, peca_id, quantidade_atual, quantidade_minima, data_atualizacao)
            SELECT COALESCE(MAX(id), 0) + 1, v_peca_id, v_qtd, 0, CURRENT_DATE FROM estoques;
        END IF;

        UPDATE pecas SET preco_custo = v_custo WHERE id = v_peca_id;

        INSERT INTO movimentacoes_estoque (id, peca_id, tipo_movimentacao, quantidade, data_movimentacao,
                                           observacao, fornecedor_id, nota_fiscal, preco_unitario)
        SELECT COALESCE(MAX(id), 0) + 1, v_peca_id, 'ENTRADA', v_qtd, CURRENT_TIMESTAMP,
               'NF ' || p_numero_nota || ' - ' || v_razao, p_fornecedor_id, p_numero_nota, v_custo
        FROM movimentacoes_estoque;
    END LOOP;
END;
$$;


-- ============================================================================
-- 3. TESTES (tirar o -- para rodar)
-- ============================================================================

-- SELECT fc_calcular_valor_total_os(2);
-- SELECT fc_total_gasto_cliente(1);
-- SELECT fc_verificar_peca_estoque_critico(3);
-- SELECT * FROM fc_produtividade_mensal_mecanico(1, 10, 2026);
-- SELECT fc_faturamento_por_categoria_servico('Freios', '2026-01-01', '2026-12-31');

-- CALL sp_abrir_ordem_servico(2, 2, 1, 2, 'Barulho ao frear', NULL, NULL);
-- CALL sp_adicionar_peca_ordem_servico(5, 1, 4);
-- CALL sp_finalizar_ordem_servico(5);
-- CALL sp_registrar_pagamento_os(5, 2);
-- CALL sp_dar_entrada_estoque_fornecedor(2, 'NF-1001', '[{"peca_id":3,"quantidade":10,"preco_custo":47.50}]'::JSONB);
