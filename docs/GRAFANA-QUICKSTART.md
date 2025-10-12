# 🎯 Quick Start: Seu Primeiro Dashboard em 5 Minutos

## 📝 Passo a Passo Rápido

### ⏱️ Tempo estimado: 5 minutos

---

## 1️⃣ Preparar Dados de Teste (2 minutos)

```bash
# Copiar o script SQL para dentro do container PostgreSQL
docker exec -i postgres psql -U postgres < grafana-sample-data.sql

# OU executar manualmente:
docker exec -it postgres psql -U postgres

# Dentro do PostgreSQL, copie e cole o conteúdo de grafana-sample-data.sql
```

---

## 2️⃣ Acessar o Grafana (30 segundos)

1. Abra: **http://localhost:3000**
2. Login: `admin` / `admin`
3. (Opcional) Mude a senha ou clique em "Skip"

---

## 3️⃣ Criar Dashboard (2 minutos)

### Criar novo dashboard:

1. Clique no **"+"** no menu lateral esquerdo
2. Clique em **"Dashboard"**
3. Clique em **"Add visualization"**

### Adicionar Painel 1: Total de Vendas

1. **Selecione**: PostgreSQL
2. **Cole esta query**:
   ```sql
   SELECT SUM(valor) as "Total de Vendas" FROM vendas;
   ```
3. **Tipo de visualização**: Clique em **"Stat"** (canto superior direito)
4. **Título**: No painel direito, em "Panel options" → "Title", digite: "Total de Vendas"
5. **Unidade**: Em "Standard options" → "Unit", procure por "currency" → "Brazilian Real (BRL)"
6. **Clique em "Apply"** (canto superior direito)

### Adicionar Painel 2: Vendas ao Longo do Tempo

1. Clique em **"Add"** → **"Visualization"**
2. **Selecione**: PostgreSQL
3. **Cole esta query**:
   ```sql
   SELECT
       DATE_TRUNC('day', data_venda) as time,
       SUM(valor) as "Vendas"
   FROM vendas
   WHERE $__timeFilter(data_venda)
   GROUP BY time
   ORDER BY time;
   ```
4. **Tipo**: Já vem como "Time series" (gráfico de linha)
5. **Título**: "Vendas Diárias"
6. **Clique em "Apply"**

### Adicionar Painel 3: Top Produtos

1. Clique em **"Add"** → **"Visualization"**
2. **Selecione**: PostgreSQL
3. **Cole esta query**:
   ```sql
   SELECT
       produto as "Produto",
       SUM(valor) as "Valor Total"
   FROM vendas
   GROUP BY produto
   ORDER BY SUM(valor) DESC
   LIMIT 5;
   ```
4. **Tipo**: Clique em **"Bar chart"**
5. **Título**: "Top 5 Produtos"
6. **Clique em "Apply"**

---

## 4️⃣ Salvar Dashboard (30 segundos)

1. Clique no ícone **💾** (Save dashboard) no topo direito
2. Digite o nome: **"Dashboard de Vendas"**
3. Clique em **"Save"**

---

## 🎉 Pronto! Seu Primeiro Dashboard Está Criado!

---

## 📊 O que você criou:

✅ **Painel 1**: Mostra o valor total de todas as vendas
✅ **Painel 2**: Gráfico de linha mostrando vendas ao longo do tempo
✅ **Painel 3**: Gráfico de barras com os 5 produtos mais vendidos

---

## 🔄 Configurar Auto-Refresh

1. Clique no ícone do **relógio** ⏱️ (canto superior direito)
2. Selecione **"5m"** (atualizar a cada 5 minutos)

---

## 🎨 Próximos Passos

Agora que você criou seu primeiro dashboard, explore mais:

### Adicione mais painéis:

**Painel 4: Vendas por Região**

```sql
SELECT regiao, SUM(valor) as "Valor"
FROM vendas
GROUP BY regiao;
```

Tipo: **Pie chart**

**Painel 5: Performance dos Vendedores**

```sql
SELECT
    vendedor as "Vendedor",
    COUNT(*) as "Nº Vendas",
    SUM(valor) as "Valor Total"
FROM vendas
GROUP BY vendedor
ORDER BY SUM(valor) DESC;
```

Tipo: **Table**

**Painel 6: Últimas Vendas**

```sql
SELECT
    data_venda as "Data",
    produto as "Produto",
    valor as "Valor",
    vendedor as "Vendedor"
FROM vendas
ORDER BY data_venda DESC
LIMIT 10;
```

Tipo: **Table**

---

## 🛠️ Personalizações Rápidas

### Mudar cor do painel:

1. Clique no título do painel → **"Edit"**
2. Painel direito → **"Thresholds"**
3. Configure valores e cores

### Reorganizar painéis:

- Arraste pelos cantos para mover
- Arraste pelas bordas para redimensionar

### Duplicar painel:

1. Clique no título do painel
2. Clique em **"More..."**
3. Clique em **"Duplicate"**

---

## 📖 Documentação Completa

Para um guia completo com mais exemplos, veja:
👉 **[GRAFANA-DASHBOARD-GUIDE.md](GRAFANA-DASHBOARD-GUIDE.md)**

---

## 🆘 Problemas?

### Query não retorna dados?

✅ Verifique se executou o script SQL no PostgreSQL
✅ Ajuste o time range (canto superior direito)
✅ Clique no ícone ⚠️ para ver detalhes do erro

### Dashboard não salva?

✅ Certifique-se de estar logado
✅ Verifique as permissões

### Painel aparece vazio?

✅ Verifique se a data source PostgreSQL está conectada
✅ Vá em: Configuration → Data Sources → PostgreSQL → Test

---

## ✅ Checklist Completo

- [ ] Executei o script SQL no PostgreSQL
- [ ] Acessei o Grafana (localhost:3000)
- [ ] Criei novo dashboard
- [ ] Adicionei painel "Total de Vendas"
- [ ] Adicionei painel "Vendas ao Longo do Tempo"
- [ ] Adicionei painel "Top 5 Produtos"
- [ ] Salvei o dashboard
- [ ] Configurei auto-refresh
- [ ] Explorei outros tipos de painéis

---

## 🎓 Dica Pro

Para importar um dashboard pronto da comunidade:

1. Vá em **+ → Import**
2. Digite o ID: **9628** (PostgreSQL Overview)
3. Clique em **"Load"**
4. Selecione sua data source PostgreSQL
5. Clique em **"Import"**

---

**🚀 Parabéns! Você criou seu primeiro dashboard no Grafana!**

Continue experimentando e explorando as possibilidades! 📊✨
