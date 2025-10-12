# 📊 Guia Completo: Criando Dashboards no Grafana

## 🚀 Passo a Passo Básico

### 1. Acessar o Grafana

1. Abra o navegador em: **http://localhost:3000** (ou http://ip-do-servidor:3000)
2. Faça login:
   - **Usuário**: `admin`
   - **Senha**: `admin`
3. (Opcional) Altere a senha quando solicitado

### 2. Criar um Novo Dashboard

**Opção A: Através do Menu**

1. Clique no ícone **"+"** no menu lateral esquerdo
2. Selecione **"Dashboard"**
3. Clique em **"Add visualization"**

**Opção B: Através da Home**

1. Vá para **Home** (ícone da casa no canto superior esquerdo)
2. Clique em **"New Dashboard"**
3. Clique em **"Add visualization"**

### 3. Selecionar Fonte de Dados

Escolha uma das fontes de dados configuradas:

- **Loki** (logs)
- **PostgreSQL** (dados relacionais)

---

## 📈 Exemplo 1: Dashboard com PostgreSQL

### Cenário: Monitorar dados de uma tabela

#### Passo 1: Criar tabela de exemplo (se não tiver dados)

```sql
-- Conectar ao PostgreSQL
docker exec -it postgres psql -U postgres

-- Criar tabela de exemplo
CREATE TABLE IF NOT EXISTS vendas (
    id SERIAL PRIMARY KEY,
    produto VARCHAR(100),
    quantidade INTEGER,
    valor DECIMAL(10,2),
    data_venda TIMESTAMP DEFAULT NOW()
);

-- Inserir dados de exemplo
INSERT INTO vendas (produto, quantidade, valor, data_venda) VALUES
    ('Notebook', 5, 3500.00, NOW() - INTERVAL '1 day'),
    ('Mouse', 20, 50.00, NOW() - INTERVAL '2 days'),
    ('Teclado', 15, 150.00, NOW() - INTERVAL '3 days'),
    ('Monitor', 8, 800.00, NOW()),
    ('Webcam', 12, 200.00, NOW());
```

#### Passo 2: Criar Visualização no Grafana

1. **Adicionar nova visualização**
2. **Selecionar**: PostgreSQL
3. **Configurar a Query**:

```sql
SELECT
    data_venda as time,
    produto as metric,
    valor
FROM vendas
WHERE $__timeFilter(data_venda)
ORDER BY data_venda
```

4. **Configurações**:

   - **Format**: Time series
   - **Type**: Graph (ou escolha outro tipo)

5. **Escolher tipo de gráfico**:
   - **Time series**: Gráfico de linha temporal
   - **Bar chart**: Gráfico de barras
   - **Stat**: Valor único grande
   - **Table**: Tabela
   - **Gauge**: Medidor

#### Exemplo de Queries Úteis

**Query 1: Total de Vendas**

```sql
SELECT
    SUM(valor) as "Total de Vendas"
FROM vendas
```

_Visualização recomendada_: **Stat**

**Query 2: Vendas por Produto**

```sql
SELECT
    produto,
    SUM(quantidade) as quantidade,
    SUM(valor) as valor_total
FROM vendas
GROUP BY produto
ORDER BY valor_total DESC
```

_Visualização recomendada_: **Bar chart** ou **Table**

**Query 3: Vendas ao Longo do Tempo**

```sql
SELECT
    DATE_TRUNC('day', data_venda) as time,
    SUM(valor) as "Valor"
FROM vendas
WHERE $__timeFilter(data_venda)
GROUP BY time
ORDER BY time
```

_Visualização recomendada_: **Time series**

**Query 4: Últimas 10 Vendas**

```sql
SELECT
    data_venda as "Data",
    produto as "Produto",
    quantidade as "Quantidade",
    valor as "Valor"
FROM vendas
ORDER BY data_venda DESC
LIMIT 10
```

_Visualização recomendada_: **Table**

---

## 📝 Exemplo 2: Dashboard com Loki (Logs)

### Cenário: Monitorar logs dos containers

#### Passo 1: Configurar logs para enviar ao Loki (Opcional)

Adicione ao seu docker-compose:

```yaml
services:
  seu-servico:
    logging:
      driver: loki
      options:
        loki-url: 'http://loki:3100/loki/api/v1/push'
        loki-batch-size: '400'
```

#### Passo 2: Criar Visualização no Grafana

1. **Adicionar nova visualização**
2. **Selecionar**: Loki
3. **Escrever LogQL Query**:

**Query 1: Ver todos os logs**

```logql
{job="varlogs"}
```

**Query 2: Filtrar por container**

```logql
{container_name="postgres"}
```

**Query 3: Buscar por palavra específica**

```logql
{container_name="postgres"} |= "error"
```

**Query 4: Contar erros por minuto**

```logql
rate({container_name="postgres"} |= "error" [1m])
```

**Query 5: Métricas de logs**

```logql
sum(rate({job="varlogs"}[5m])) by (container_name)
```

---

## 🎨 Personalizando o Dashboard

### 1. Configurações do Painel

Clique na engrenagem (⚙️) ou no título do painel:

- **Panel options**:

  - Title: Nome do painel
  - Description: Descrição
  - Transparent background: Fundo transparente

- **Standard options**:
  - Unit: Unidade dos valores (currency, bytes, etc.)
  - Min/Max: Valores mínimo e máximo
  - Decimals: Casas decimais

### 2. Tipos de Visualização

| Tipo            | Melhor Para                                 |
| --------------- | ------------------------------------------- |
| **Time series** | Dados temporais, métricas ao longo do tempo |
| **Stat**        | Valores únicos, KPIs                        |
| **Gauge**       | Percentuais, valores com limites            |
| **Bar chart**   | Comparações entre categorias                |
| **Table**       | Dados tabulares, listagens                  |
| **Pie chart**   | Distribuições, proporções                   |
| **Logs**        | Visualizar logs (Loki)                      |

### 3. Threshold (Limites)

Configure cores baseadas em valores:

1. Vá em **Thresholds**
2. Adicione valores:
   - Verde: Abaixo de 50
   - Amarelo: Entre 50 e 80
   - Vermelho: Acima de 80

### 4. Transformações

Modifique os dados antes de exibir:

1. Clique na aba **Transform**
2. Escolha transformação:
   - **Filter by name**: Filtrar colunas
   - **Organize fields**: Reorganizar/renomear
   - **Reduce**: Agregar valores (sum, mean, etc.)
   - **Merge**: Juntar séries

---

## 📋 Template de Dashboard Completo

### Dashboard: Visão Geral do Sistema

#### Painel 1: Total de Registros (PostgreSQL)

```sql
SELECT COUNT(*) as "Total de Registros"
FROM vendas
```

**Tipo**: Stat | **Cor**: Verde

#### Painel 2: Valor Total (PostgreSQL)

```sql
SELECT SUM(valor) as "Valor Total"
FROM vendas
```

**Tipo**: Stat | **Unit**: currency (BRL) | **Cor**: Azul

#### Painel 3: Vendas por Dia (PostgreSQL)

```sql
SELECT
    DATE_TRUNC('day', data_venda) as time,
    SUM(valor) as "Vendas"
FROM vendas
WHERE $__timeFilter(data_venda)
GROUP BY time
ORDER BY time
```

**Tipo**: Time series | **Fill**: 30%

#### Painel 4: Top 5 Produtos (PostgreSQL)

```sql
SELECT
    produto as "Produto",
    SUM(quantidade) as "Quantidade",
    SUM(valor) as "Valor Total"
FROM vendas
GROUP BY produto
ORDER BY SUM(valor) DESC
LIMIT 5
```

**Tipo**: Table

#### Painel 5: Logs de Erro (Loki)

```logql
{job="varlogs"} |= "error" or "ERROR" or "Error"
```

**Tipo**: Logs

#### Painel 6: Taxa de Logs por Container (Loki)

```logql
sum(rate({job="varlogs"}[5m])) by (container_name)
```

**Tipo**: Bar chart

---

## ⚙️ Configurações Avançadas

### Variáveis (Variables)

Crie variáveis para dashboards dinâmicos:

1. Clique em **Dashboard settings** (⚙️ no topo)
2. Vá em **Variables**
3. Clique em **Add variable**

**Exemplo: Variável para selecionar produto**

- **Name**: `produto`
- **Type**: Query
- **Data source**: PostgreSQL
- **Query**:
  ```sql
  SELECT DISTINCT produto FROM vendas ORDER BY produto
  ```

**Uso na query**:

```sql
SELECT * FROM vendas WHERE produto = '$produto'
```

### Anotações (Annotations)

Marque eventos importantes no gráfico:

1. **Dashboard settings** → **Annotations**
2. **Add annotation query**
3. Configure query para buscar eventos

### Links

Adicione links para outros dashboards:

1. **Dashboard settings** → **Links**
2. **Add link**
3. Configure URL e título

---

## 💾 Salvando o Dashboard

1. Clique no ícone **💾 Save dashboard** (topo direito)
2. Digite um nome: "Dashboard de Vendas"
3. (Opcional) Adicione uma pasta
4. Clique em **Save**

---

## 📤 Exportar/Importar Dashboard

### Exportar

1. **Dashboard settings** (⚙️)
2. **JSON Model**
3. Copie o JSON ou clique em **Save to file**

### Importar

1. Menu **+ → Import**
2. Cole o JSON ou faça upload do arquivo
3. Clique em **Load**
4. Configure data sources se necessário
5. Clique em **Import**

---

## 🎯 Dashboards Prontos da Comunidade

Você pode importar dashboards prontos:

1. Vá em **+ → Import**
2. Digite um ID do dashboard (do grafana.com):

   - **PostgreSQL**: 455, 9628
   - **Redis**: 11835, 12776
   - **Docker**: 893, 1229
   - **Loki**: 12611, 13639

3. Clique em **Load**
4. Selecione suas data sources
5. Clique em **Import**

**Fonte**: https://grafana.com/grafana/dashboards/

---

## 🔄 Atualização Automática

Configure refresh automático:

1. Clique no ícone do **relógio** (⏱️) no topo direito
2. Selecione intervalo:
   - 5s, 10s, 30s
   - 1m, 5m, 15m, 30m
   - 1h, 2h, 1d

---

## 🎨 Dicas de Design

### Layout Responsivo

1. Arraste painéis para reorganizar
2. Redimensione arrastando os cantos
3. Use grid de 24 colunas

### Cores Consistentes

1. Use a mesma paleta de cores
2. Configure thresholds consistentes
3. Use modo escuro ou claro consistentemente

### Organização

1. Agrupe painéis relacionados
2. Use rows para separar seções:
   - Clique em **Add → Row**
   - Nomeie a row
   - Arraste painéis para dentro

### Painéis de Resumo no Topo

1. Stats com KPIs principais
2. Gauges para status
3. Gráficos detalhados abaixo

---

## 🔍 Exemplos Práticos por Caso de Uso

### Monitoramento de API

```sql
-- Tempo médio de resposta
SELECT
    time,
    AVG(response_time) as "Tempo Médio (ms)"
FROM api_logs
WHERE $__timeFilter(time)
GROUP BY time
ORDER BY time
```

### Monitoramento de Vendas

```sql
-- Vendas do dia
SELECT
    SUM(valor) as "Vendas Hoje"
FROM vendas
WHERE DATE(data_venda) = CURRENT_DATE
```

### Análise de Erros

```logql
# Taxa de erros por hora
sum(rate({job="varlogs"} |= "error" [1h])) by (container_name)
```

### Dashboard de Sistema

```sql
-- Conexões ativas no PostgreSQL
SELECT
    COUNT(*) as "Conexões Ativas"
FROM pg_stat_activity
WHERE state = 'active'
```

---

## 📚 Recursos Adicionais

- **Documentação Oficial**: https://grafana.com/docs/grafana/latest/dashboards/
- **Tutoriais em Vídeo**: https://grafana.com/tutorials/
- **Dashboards Prontos**: https://grafana.com/grafana/dashboards/
- **LogQL (Loki)**: https://grafana.com/docs/loki/latest/logql/
- **Plugins**: https://grafana.com/grafana/plugins/

---

## 🆘 Problemas Comuns

### Query não retorna dados

✅ Verifique:

- Filtro de tempo está correto?
- Data source está conectado?
- Query tem sintaxe correta?
- Há dados na tabela/logs?

### "No data" no painel

✅ Soluções:

- Ajuste o time range (canto superior direito)
- Verifique a query no Query Inspector (⚠️)
- Teste a query direto no banco

### Gráfico não aparece

✅ Verifique:

- Tipo de visualização é compatível com os dados?
- Campos de time estão mapeados corretamente?
- Format da query está correto?

---

## ✅ Checklist: Seu Primeiro Dashboard

- [ ] Acessar Grafana (localhost:3000)
- [ ] Verificar data sources em Configuration → Data Sources
- [ ] Criar novo dashboard
- [ ] Adicionar primeiro painel
- [ ] Selecionar data source (PostgreSQL ou Loki)
- [ ] Escrever query
- [ ] Escolher tipo de visualização
- [ ] Configurar título e opções
- [ ] Adicionar mais painéis conforme necessário
- [ ] Salvar o dashboard
- [ ] Configurar auto-refresh (opcional)
- [ ] Compartilhar com o time! 🎉

---

## 🎓 Próximos Passos

1. **Crie seu primeiro dashboard** seguindo este guia
2. **Explore dashboards da comunidade** para se inspirar
3. **Configure alertas** (Configuration → Alerting)
4. **Crie variáveis** para dashboards dinâmicos
5. **Organize em pastas** para melhor gestão
6. **Configure permissões** para controle de acesso

---

**💡 Dica Final**: Comece simples! Crie um dashboard com 2-3 painéis básicos e vá evoluindo conforme aprende mais funcionalidades.

**🚀 Boa sorte com seus dashboards!**
