-- ===================================
-- Script de Exemplo para Grafana
-- Crie dados de teste no PostgreSQL
-- ===================================

-- Conecte ao PostgreSQL:
-- docker exec -it postgres psql -U postgres

-- ===================================
-- 1. CRIAR TABELA DE VENDAS
-- ===================================
CREATE TABLE IF NOT EXISTS vendas (
    id SERIAL PRIMARY KEY,
    produto VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    quantidade INTEGER NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    data_venda TIMESTAMP DEFAULT NOW(),
    vendedor VARCHAR(100),
    regiao VARCHAR(50)
);

-- ===================================
-- 2. INSERIR DADOS DE EXEMPLO
-- ===================================
INSERT INTO vendas (produto, categoria, quantidade, valor, data_venda, vendedor, regiao) VALUES
    -- Vendas dos últimos 30 dias
    ('Notebook Dell', 'Informática', 5, 3500.00, NOW() - INTERVAL '1 day', 'João Silva', 'Sul'),
    ('Mouse Logitech', 'Informática', 20, 50.00, NOW() - INTERVAL '1 day', 'Maria Santos', 'Sudeste'),
    ('Teclado Mecânico', 'Informática', 15, 150.00, NOW() - INTERVAL '2 days', 'João Silva', 'Sul'),
    ('Monitor LG 24"', 'Informática', 8, 800.00, NOW() - INTERVAL '2 days', 'Pedro Costa', 'Norte'),
    ('Webcam HD', 'Informática', 12, 200.00, NOW() - INTERVAL '3 days', 'Maria Santos', 'Sudeste'),

    ('Notebook HP', 'Informática', 3, 3200.00, NOW() - INTERVAL '4 days', 'João Silva', 'Sul'),
    ('Mouse Sem Fio', 'Informática', 25, 45.00, NOW() - INTERVAL '5 days', 'Ana Lima', 'Centro-Oeste'),
    ('Teclado USB', 'Informática', 18, 80.00, NOW() - INTERVAL '6 days', 'Pedro Costa', 'Norte'),
    ('Monitor Samsung 27"', 'Informática', 6, 1200.00, NOW() - INTERVAL '7 days', 'Maria Santos', 'Sudeste'),
    ('Headset Gamer', 'Informática', 10, 250.00, NOW() - INTERVAL '8 days', 'João Silva', 'Sul'),

    ('Cadeira Gamer', 'Móveis', 7, 800.00, NOW() - INTERVAL '9 days', 'Ana Lima', 'Centro-Oeste'),
    ('Mesa para PC', 'Móveis', 5, 400.00, NOW() - INTERVAL '10 days', 'Pedro Costa', 'Norte'),
    ('Luminária LED', 'Móveis', 15, 80.00, NOW() - INTERVAL '11 days', 'Maria Santos', 'Sudeste'),
    ('Suporte Monitor', 'Móveis', 20, 120.00, NOW() - INTERVAL '12 days', 'João Silva', 'Sul'),
    ('Gaveteiro', 'Móveis', 8, 300.00, NOW() - INTERVAL '13 days', 'Ana Lima', 'Centro-Oeste'),

    ('SSD 500GB', 'Informática', 30, 350.00, NOW() - INTERVAL '14 days', 'Pedro Costa', 'Norte'),
    ('HD Externo 1TB', 'Informática', 22, 280.00, NOW() - INTERVAL '15 days', 'Maria Santos', 'Sudeste'),
    ('Memória RAM 16GB', 'Informática', 25, 400.00, NOW() - INTERVAL '16 days', 'João Silva', 'Sul'),
    ('Placa de Vídeo', 'Informática', 4, 2500.00, NOW() - INTERVAL '17 days', 'Ana Lima', 'Centro-Oeste'),
    ('Fonte 600W', 'Informática', 12, 300.00, NOW() - INTERVAL '18 days', 'Pedro Costa', 'Norte'),

    ('Notebook Lenovo', 'Informática', 6, 3800.00, NOW() - INTERVAL '19 days', 'Maria Santos', 'Sudeste'),
    ('Mouse Pad', 'Informática', 40, 25.00, NOW() - INTERVAL '20 days', 'João Silva', 'Sul'),
    ('Webcam 4K', 'Informática', 5, 450.00, NOW() - INTERVAL '21 days', 'Ana Lima', 'Centro-Oeste'),
    ('Microfone USB', 'Informática', 8, 180.00, NOW() - INTERVAL '22 days', 'Pedro Costa', 'Norte'),
    ('Caixa de Som', 'Informática', 14, 120.00, NOW() - INTERVAL '23 days', 'Maria Santos', 'Sudeste'),

    ('Cadeira Escritório', 'Móveis', 10, 600.00, NOW() - INTERVAL '24 days', 'João Silva', 'Sul'),
    ('Apoio para Pés', 'Móveis', 16, 50.00, NOW() - INTERVAL '25 days', 'Ana Lima', 'Centro-Oeste'),
    ('Organizador Mesa', 'Móveis', 20, 40.00, NOW() - INTERVAL '26 days', 'Pedro Costa', 'Norte'),
    ('Quadro Branco', 'Móveis', 8, 150.00, NOW() - INTERVAL '27 days', 'Maria Santos', 'Sudeste'),
    ('Arquivo de Aço', 'Móveis', 4, 800.00, NOW() - INTERVAL '28 days', 'João Silva', 'Sul');

-- ===================================
-- 3. QUERIES PARA USAR NO GRAFANA
-- ===================================

-- QUERY 1: Total de Vendas (Use em painel tipo STAT)
SELECT
    SUM(valor) as "Total de Vendas"
FROM vendas;

-- QUERY 2: Número de Vendas (Use em painel tipo STAT)
SELECT
    COUNT(*) as "Total de Pedidos"
FROM vendas;

-- QUERY 3: Ticket Médio (Use em painel tipo STAT)
SELECT
    ROUND(AVG(valor), 2) as "Ticket Médio"
FROM vendas;

-- QUERY 4: Vendas ao Longo do Tempo (Use em painel tipo TIME SERIES)
SELECT
    DATE_TRUNC('day', data_venda) as time,
    SUM(valor) as "Vendas Diárias"
FROM vendas
WHERE $__timeFilter(data_venda)
GROUP BY time
ORDER BY time;

-- QUERY 5: Top 10 Produtos Mais Vendidos (Use em painel tipo BAR CHART)
SELECT
    produto as "Produto",
    SUM(quantidade) as "Quantidade",
    SUM(valor) as "Valor Total"
FROM vendas
GROUP BY produto
ORDER BY SUM(valor) DESC
LIMIT 10;

-- QUERY 6: Vendas por Categoria (Use em painel tipo PIE CHART)
SELECT
    categoria as "Categoria",
    SUM(valor) as "Valor"
FROM vendas
GROUP BY categoria
ORDER BY SUM(valor) DESC;

-- QUERY 7: Vendas por Região (Use em painel tipo BAR CHART)
SELECT
    regiao as "Região",
    SUM(valor) as "Valor Total",
    COUNT(*) as "Quantidade de Vendas"
FROM vendas
GROUP BY regiao
ORDER BY SUM(valor) DESC;

-- QUERY 8: Performance por Vendedor (Use em painel tipo TABLE)
SELECT
    vendedor as "Vendedor",
    COUNT(*) as "Nº Vendas",
    SUM(quantidade) as "Itens Vendidos",
    SUM(valor) as "Valor Total",
    ROUND(AVG(valor), 2) as "Ticket Médio"
FROM vendas
GROUP BY vendedor
ORDER BY SUM(valor) DESC;

-- QUERY 9: Últimas 15 Vendas (Use em painel tipo TABLE)
SELECT
    data_venda as "Data",
    produto as "Produto",
    quantidade as "Qtd",
    valor as "Valor",
    vendedor as "Vendedor",
    regiao as "Região"
FROM vendas
ORDER BY data_venda DESC
LIMIT 15;

-- QUERY 10: Vendas por Dia da Semana (Use em painel tipo BAR CHART)
SELECT
    CASE EXTRACT(DOW FROM data_venda)
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Segunda'
        WHEN 2 THEN 'Terça'
        WHEN 3 THEN 'Quarta'
        WHEN 4 THEN 'Quinta'
        WHEN 5 THEN 'Sexta'
        WHEN 6 THEN 'Sábado'
    END as "Dia da Semana",
    SUM(valor) as "Valor Total"
FROM vendas
GROUP BY EXTRACT(DOW FROM data_venda)
ORDER BY EXTRACT(DOW FROM data_venda);

-- QUERY 11: Comparação Mês a Mês (Use em painel tipo TIME SERIES)
SELECT
    DATE_TRUNC('month', data_venda) as time,
    SUM(valor) as "Vendas Mensais"
FROM vendas
WHERE $__timeFilter(data_venda)
GROUP BY time
ORDER BY time;

-- QUERY 12: Crescimento Diário (Use em painel tipo TIME SERIES)
SELECT
    DATE_TRUNC('day', data_venda) as time,
    SUM(valor) as "Valor",
    COUNT(*) as "Quantidade de Vendas"
FROM vendas
WHERE $__timeFilter(data_venda)
GROUP BY time
ORDER BY time;

-- ===================================
-- 4. CRIAR ÍNDICES PARA PERFORMANCE
-- ===================================
CREATE INDEX IF NOT EXISTS idx_vendas_data ON vendas(data_venda);
CREATE INDEX IF NOT EXISTS idx_vendas_produto ON vendas(produto);
CREATE INDEX IF NOT EXISTS idx_vendas_vendedor ON vendas(vendedor);
CREATE INDEX IF NOT EXISTS idx_vendas_regiao ON vendas(regiao);

-- ===================================
-- 5. CONSULTAS ÚTEIS PARA DEBUG
-- ===================================

-- Ver todas as vendas
SELECT * FROM vendas ORDER BY data_venda DESC;

-- Ver resumo geral
SELECT
    COUNT(*) as total_vendas,
    SUM(valor) as valor_total,
    AVG(valor) as ticket_medio,
    MIN(data_venda) as primeira_venda,
    MAX(data_venda) as ultima_venda
FROM vendas;

-- Ver vendas por categoria
SELECT
    categoria,
    COUNT(*) as quantidade,
    SUM(valor) as total
FROM vendas
GROUP BY categoria;

-- ===================================
-- 6. LIMPAR DADOS (SE NECESSÁRIO)
-- ===================================
-- CUIDADO: Isso apaga todos os dados!
-- TRUNCATE TABLE vendas;
-- DROP TABLE vendas;
