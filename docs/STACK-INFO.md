# 📦 Organização dos Stacks Docker

## 🔄 Reorganização Realizada

Os arquivos foram reorganizados para melhor refletir as dependências entre os serviços.

### **Antes:**

- `nginx.yml` → Apenas Nginx + Grafana
- `loki.yml` → Apenas Loki + Grafana

### **Depois:**

- `nginx.yml` → **Stack Completo: Loki + Grafana + Nginx** ✅
- `loki.yml` → **Stack Completo: Loki + Grafana + Nginx** ✅

> **⚠️ Ambos os arquivos são idênticos agora!**
> Use qualquer um dos dois para subir o stack completo.

---

## 🎯 Motivação

Como o **Loki depende do Grafana** e o **Nginx depende de ambos**, faz mais sentido ter todos os serviços juntos em um único arquivo.

### Dependências:

```
Loki (Log Aggregation)
  ↓
Grafana (Visualização) → datasource: Loki + PostgreSQL
  ↓
Nginx (Reverse Proxy com SSL)
```

---

## 🚀 Como usar

### **Opção 1: Usar nginx.yml**

```bash
docker-compose -f nginx.yml up -d
```

### **Opção 2: Usar loki.yml**

```bash
docker-compose -f loki.yml up -d
```

### **Resultado:** Stack completo funcionando

- ✅ Loki rodando na porta 3100 (localhost only)
- ✅ Grafana rodando na porta 3000 (localhost only)
- ✅ Nginx nas portas 80 e 443 (público)
- ✅ SSL configurado para https://grafana.erpclass.com.br

---

## 📊 Serviços no Stack

| Serviço     | Container | Porta Externa  | Porta Interna | Acesso           |
| ----------- | --------- | -------------- | ------------- | ---------------- |
| **Loki**    | loki      | 127.0.0.1:3100 | 3100          | Apenas localhost |
| **Grafana** | grafana   | 127.0.0.1:3000 | 3000          | Apenas localhost |
| **Nginx**   | nginx     | 80, 443        | 80, 443       | Público (HTTPS)  |

### Acessos:

- **Grafana**: https://grafana.erpclass.com.br (via Nginx)
- **Loki API**: http://localhost:3100 (direto no servidor)
- **Loki Push**: http://loki:3100/loki/api/v1/push (entre containers)

---

## 🔐 Segurança

### Portas Internas (127.0.0.1):

- Loki e Grafana só são acessíveis via localhost
- Não são expostas diretamente para a internet
- Nginx faz o proxy reverso com SSL

### Portas Públicas:

- Apenas Nginx nas portas 80 (HTTP) e 443 (HTTPS)
- HTTP redireciona automaticamente para HTTPS
- Certificado SSL Let's Encrypt

---

## 📁 Volumes Utilizados

```bash
# Volumes persistentes
docker volume create loki           # Dados do Loki
docker volume create grafana        # Dados do Grafana
docker volume create letsencrypt    # Certificados SSL
docker volume create nginx-logs     # Logs do Nginx

# Rede externa
docker network create network
```

---

## 🔧 Comandos Úteis

### Ver todos os containers do stack:

```bash
docker-compose -f nginx.yml ps
```

### Ver logs de um serviço específico:

```bash
docker-compose -f nginx.yml logs -f loki
docker-compose -f nginx.yml logs -f grafana
docker-compose -f nginx.yml logs -f nginx
```

### Reiniciar um serviço:

```bash
docker-compose -f nginx.yml restart loki
docker-compose -f nginx.yml restart grafana
docker-compose -f nginx.yml restart nginx
```

### Parar o stack:

```bash
docker-compose -f nginx.yml down
```

### Atualizar imagens:

```bash
docker-compose -f nginx.yml pull
docker-compose -f nginx.yml up -d --force-recreate
```

---

## 🩺 Health Checks

Todos os serviços possuem health checks configurados:

### Loki:

```bash
curl http://localhost:3100/ready
# ou dentro do container
docker exec loki wget --no-verbose --tries=1 --spider http://localhost:3100/ready
```

### Grafana:

```bash
curl http://localhost:3000/api/health
```

### Nginx:

```bash
docker exec nginx nginx -t
```

---

## ⚙️ Configurações do Grafana

### Datasources Pré-configurados:

- **Loki**: http://loki:3100
- **PostgreSQL**: postgres:5432 (banco: postgres)

### Plugins Instalados:

- grafana-clock-panel
- grafana-simple-json-datasource

### Configuração de Domínio:

```yaml
GF_SERVER_DOMAIN=grafana.erpclass.com.br
GF_SERVER_ROOT_URL=https://grafana.erpclass.com.br
```

---

## 📝 Ordem de Inicialização

O Docker Compose garante a ordem correta através do `depends_on`:

1. **Loki** inicia primeiro
2. **Grafana** inicia após Loki estar pronto
3. **Nginx** inicia após Grafana e Loki

---

## 🆘 Troubleshooting

### Problema: Nginx não consegue conectar no Grafana

```bash
# Verificar se todos estão na mesma rede
docker network inspect network

# Verificar se Grafana está rodando
docker ps | grep grafana

# Verificar logs do Nginx
docker logs nginx | grep error
```

### Problema: Loki não recebe logs

```bash
# Testar endpoint do Loki
curl http://localhost:3100/ready

# Enviar log de teste
curl -H "Content-Type: application/json" \
  -X POST http://localhost:3100/loki/api/v1/push \
  --data '{"streams": [{"stream": {"app": "teste"},"values": [["'"$(date +%s)000000000"'","Teste de log"]]}]}'

# Verificar no Grafana → Explore → Loki
```

### Problema: Certificado SSL inválido

```bash
# Verificar certificados no volume
docker run --rm -v letsencrypt:/certs alpine ls -la /certs/live

# Recarregar Nginx
docker exec nginx nginx -s reload

# Verificar expiração
echo | openssl s_client -connect grafana.erpclass.com.br:443 2>/dev/null | openssl x509 -noout -dates
```

---

## ✅ Checklist de Deploy

- [ ] DNS configurado (grafana.erpclass.com.br → IP do servidor)
- [ ] Volumes Docker criados (loki, grafana, letsencrypt, nginx-logs)
- [ ] Rede externa criada (network)
- [ ] Arquivos de configuração do Nginx criados (nginx/\*.conf)
- [ ] DH parameters gerado (nginx/dhparam.pem)
- [ ] Certificado SSL obtido (Let's Encrypt)
- [ ] Certificados copiados para volume letsencrypt
- [ ] Firewall liberado (portas 80 e 443)
- [ ] Stack iniciado (docker-compose -f nginx.yml up -d)
- [ ] Health checks passando (docker ps)
- [ ] Grafana acessível via HTTPS
- [ ] Loki recebendo logs

---

**🎉 Stack Loki + Grafana + Nginx configurado e pronto para produção!**
