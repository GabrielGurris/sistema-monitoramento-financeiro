USE sistema_de_monitoramento_financeiro;

-- CRIAÇÃO DAS TABELAS
CREATE TABLE categorias (
    categoria_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL
);

CREATE TABLE limites_de_gastos (
    meta_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    valor_limite DECIMAL(10, 2) NOT NULL,
    data_inicial DATE NOT NULL,
    data_final DATE NOT NULL,
    categoria_id INT,
    FOREIGN KEY (categoria_id) REFERENCES categorias(categoria_id)
);

CREATE TABLE transacoes (
    transacao_id INT AUTO_INCREMENT PRIMARY KEY,
    valor DECIMAL(10, 2) NOT NULL,
    data DATE NOT NULL,
    descricao VARCHAR(255),
    tipo ENUM('receita', 'despesa') NOT NULL,
    categoria_id INT NOT NULL,
    FOREIGN KEY (categoria_id) REFERENCES categorias(categoria_id)
);

-- SELECTs BÁSICOS PARA VER TODOS OS DADOS DA TABELA
SELECT * FROM categorias;
SELECT * FROM limites_de_gastos;
SELECT * FROM transacoes;

-- INSERÇÕES DE DADOS NAS TABELAS
INSERT INTO sistema_de_monitoramento_financeiro.categorias (nome) VALUES
('Alimentação'),
('Transporte'),
('Lazer'),
('Educação'),
('Saúde'),
('Financeiro');

INSERT INTO sistema_de_monitoramento_financeiro.limites_de_gastos (nome, valor_limite, data_inicial, data_final, categoria_id) VALUES
('Compras', 500.00, '2024-01-01', '2024-12-31', 3),
('Gastos com transporte', 400.00, '2024-01-01', '2024-12-31', 2),
('Investir em educação', 300.00, '2024-01-01', '2024-12-31', 4),
('Comer em restaurantes', 400.00, '2024-01-01', '2024-12-31', 1),
('Gastos com convenio', 350.00, '2024-01-01', '2024-12-31', 5);

INSERT INTO sistema_de_monitoramento_financeiro.transacoes (valor, data, descricao, tipo, categoria_id) VALUES
(50.00, '2024-10-05', 'Uber', 'despesa', 2),
(100.00, '2024-10-07', 'Cinema com amigos', 'despesa', 3),
(75.00, '2024-10-10', 'Curso online', 'despesa', 4),
(300.00, '2024-09-10', 'Investimento em ações', 'despesa', 6),
(35.00, '2024-10-12', 'Almoço', 'despesa', 1),
(20.00, '2024-11-11', 'Consulta com Nutricionista', 'despesa', 5),
(500.00, '2024-10-15', 'Investimento em ações', 'receita', 6);


-- TRIGGER PARA VERIFICAR SE A NOVA DESPESA NAO EXCEDE O VALOR MÁXIMO
DELIMITER //

CREATE TRIGGER verificar_limite_antes_insercao
BEFORE INSERT ON transacoes
FOR EACH ROW
BEGIN
    DECLARE valor_restante DECIMAL(10, 2);

    -- Verifica se a transação é uma despesa
    IF NEW.tipo = 'despesa' THEN
        -- Calcula o valor restante do limite de gastos para a categoria da transação
        SELECT (lg.valor_limite - COALESCE(SUM(t.valor), 0)) INTO valor_restante
        FROM limites_de_gastos lg
        LEFT JOIN transacoes t ON t.categoria_id = lg.categoria_id AND t.tipo = 'despesa'
        WHERE lg.categoria_id = NEW.categoria_id
          AND CURDATE() BETWEEN lg.data_inicial AND lg.data_final
        GROUP BY lg.meta_id;

        -- Verifica se o valor da transação excede o valor restante do limite
        IF NEW.valor > valor_restante THEN
            SIGNAL SQLSTATE '45000' 
                SET MESSAGE_TEXT = 'Alerta: Esta transação excede o limite de gastos para esta categoria.';
        END IF;
    END IF;
END //

DELIMITER ;

-- EXEMPLO DE INSERÇÃO QUE EXCEDE O VALOR MÁXIMO
INSERT INTO sistema_de_monitoramento_financeiro.transacoes (valor, data, descricao, tipo, categoria_id) VALUES
(550.00, '2024-10-05', 'Uber', 'despesa', 2)


DELIMITER //

CREATE PROCEDURE relatorio_mensal_financeiro()
BEGIN
    DECLARE saldo_inicial DECIMAL(10, 2) DEFAULT 0;
    DECLARE receitas DECIMAL(10, 2) DEFAULT 0;
    DECLARE despesas DECIMAL(10, 2) DEFAULT 0;
    DECLARE saldo_final DECIMAL(10, 2) DEFAULT 0;
    
    -- Calculando as receitas do mês atual
    SET receitas = (SELECT COALESCE(SUM(valor), 0)
                    FROM transacoes
                    WHERE tipo = 'receita'
                      AND MONTH(data) = MONTH(CURDATE())
                      AND YEAR(data) = YEAR(CURDATE()));

    -- Calculando as despesas do mês atual
    SET despesas = (SELECT COALESCE(SUM(valor), 0)
                    FROM transacoes
                    WHERE tipo = 'despesa'
                      AND MONTH(data) = MONTH(CURDATE())
                      AND YEAR(data) = YEAR(CURDATE()));

    -- Calculando o saldo final
    SET saldo_final = saldo_inicial + receitas - despesas;

    -- Exibindo o relatório
    SELECT saldo_inicial AS Saldo_Inicial, 
           receitas AS Total_Receitas, 
           despesas AS Total_Despesas, 
           saldo_final AS Saldo_Final;
END //

DELIMITER ;

CALL relatorio_mensal_financeiro();
