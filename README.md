# Sistema de Monitoramento Financeiro

Este projeto é um sistema de monitoramento financeiro, desenvolvido para acompanhar receitas, despesas e limites de gastos por categoria. Ele foi construído em MySQL e inclui uma estrutura de banco de dados para gerenciar transações financeiras, limites de gastos e categorias, além de triggers e procedures para validação e geração de relatórios.

## Índice

- [Funcionalidades](#funcionalidades)
- [Estrutura do Banco de Dados](#estrutura-do-banco-de-dados)
- [Instruções de Instalação](#instruções-de-instalação)
- [Como Usar](#como-usar)
- [Scripts SQL](#scripts-sql)

## Funcionalidades

- **Gerenciamento de Transações**: Registre receitas e despesas em diferentes categorias.
- **Limites de Gastos por Categoria**: Defina e acompanhe limites de gastos por categoria em um intervalo de tempo específico.
- **Relatório Mensal**: Gera um relatório financeiro com o saldo inicial (iniciando em 0), total de receitas, despesas e saldo final do mês atual.
- **Validação Automática**: Utiliza triggers para garantir que as despesas não excedam os limites definidos.

## Estrutura do Banco de Dados

O banco de dados `sistema_de_monitoramento_financeiro` possui as seguintes tabelas principais:

- **`categorias`**: Lista de categorias de receitas e despesas.
- **`transacoes`**: Registra cada transação (receitas e despesas).
- **`limites_de_gastos`**: Define limites de gastos por categoria e período.

### Exemplo de Esquema das Tabelas

```sql
CREATE TABLE categorias (
    categoria_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

CREATE TABLE transacoes (
    transacao_id INT AUTO_INCREMENT PRIMARY KEY,
    valor DECIMAL(10, 2) NOT NULL,
    data DATE NOT NULL,
    descricao VARCHAR(255),
    tipo ENUM('receita', 'despesa') NOT NULL,
    categoria_id INT,
    FOREIGN KEY (categoria_id) REFERENCES categorias(categoria_id)
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
```
## Instruções de Instalação

1. Clone o repositório:  
```- git clone https://github.com/GabrielGurris/sistema-monitoramento-financeiro.git```  
```- cd sistema-monitoramento-financeiro```

2. No MySQL Workbench, importe o arquivo ```sistema_monitoramento_financeiro.sql``` para criar a estrutura e popular as tabelas com dados de exemplo.
3. Execute os scripts SQL para configurar o banco e criar triggers e procedures.

## Como Usar
### Inserir Transações
Para registrar uma nova transação (exemplo de despesa):  
```INSERT INTO transacoes (valor, data, descricao, tipo, categoria_id) VALUES (40.00, '2024-10-05', 'Uber', 'despesa', 2);```

### Gerar Relatório Mensal
Chame a procedure para gerar o relatório financeiro do mês atual:  
```CALL relatorio_mensal_financeiro();```

### Triggers
O sistema utiliza triggers para evitar que as despesas excedam o limite de gastos de uma categoria:  

```sql
DELIMITER //

CREATE TRIGGER verificar_limite_antes_insercao
BEFORE INSERT ON transacoes
FOR EACH ROW
BEGIN
    DECLARE valor_restante DECIMAL(10, 2);
    
    IF NEW.tipo = 'despesa' THEN
        SELECT (lg.valor_limite - COALESCE(SUM(t.valor), 0)) INTO valor_restante
        FROM limites_de_gastos lg
        LEFT JOIN transacoes t ON t.categoria_id = lg.categoria_id AND t.tipo = 'despesa'
        WHERE lg.categoria_id = NEW.categoria_id
          AND CURDATE() BETWEEN lg.data_inicial AND lg.data_final
        GROUP BY lg.meta_id;

        IF NEW.valor > valor_restante THEN
            SIGNAL SQLSTATE '45000' 
                SET MESSAGE_TEXT = 'Alerta: Esta transação excede o limite de gastos para esta categoria.';
        END IF;
    END IF;
END //

DELIMITER ;
```

### Teste do Funcionamento da Trigger
Para registrar uma nova transação (exemplo de despesa):  
```INSERT INTO transacoes (valor, data, descricao, tipo, categoria_id) VALUES (6000.00, '2024-10-05', 'Uber', 'despesa', 2);```  
  
Note o erro que aparecerá na saída:  
```Error Code: 1644. Alerta: Esta transação excede o limite de gastos para esta categoria.```  

Este erro ocorre pois o valor máximo definido para gastos com transporte era de ```400.00```.

## Scripts SQL
Todos os scripts SQL estão incluídos no arquivo ```sistema_monitoramento_financeiro.sql```. O arquivo contém:

- Estrutura das tabelas.
- Triggers para validação de limites.
- Procedures para geração de relatórios financeiros mensais.

