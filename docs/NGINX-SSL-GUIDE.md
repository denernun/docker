# 🔒 Configurando HTTPS para Grafana com Nginx

## 🎯 Problema

O navegador bloqueia acesso HTTPS sem certificado SSL válido. A solução é usar Nginx como proxy reverso com certificado SSL do Let's Encrypt.

## ✅ Solução: Nginx + Let's Encrypt + Grafana

---

## 📋 Arquitetura

```
Internet → Nginx (porta 443 HTTPS) → Grafana (porta 3000 HTTP interno)
           ↓
    Certificado SSL
```

**Vantagens:**

- ✅ Certificado SSL gratuito e renovado automaticamente
- ✅ HTTPS seguro (cadeado verde no navegador)
- ✅ Esconde a porta 3000 (usa porta 443 padrão)
- ✅ Pode adicionar outros serviços facilmente

---

## 🚀 Instalação Completa (Ubuntu)

### **Passo 1: Instalar Nginx e Certbot**

```bash
# Atualizar sistema
sudo apt update

# Instalar Nginx
sudo apt install -y nginx

# Instalar Certbot para Let's Encrypt
sudo apt install -y certbot python3-certbot-nginx

# Verificar se Nginx está rodando
sudo systemctl status nginx
```

### **Passo 2: Configurar DNS**

**Antes de continuar, certifique-se que:**

```
grafana.erpclass.com.br → aponta para o IP do seu servidor
```

Verifique com:

```bash
ping grafana.erpclass.com.br
# Deve retornar o IP do seu servidor
```

### **Passo 3: Ajustar Portas do Grafana**

Edite o `loki.yml` para que o Grafana **NÃO exponha** a porta 3000 externamente:

```yaml
services:
  grafana:
    image: grafana/grafana:latest
    hostname: grafana
    container_name: grafana
    restart: always
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
      - GF_USERS_ALLOW_SIGN_UP=false
      # Configurar domínio correto
      - GF_SERVER_DOMAIN=grafana.erpclass.com.br
      - GF_SERVER_ROOT_URL=https://grafana.erpclass.com.br
    ports:
      # Apenas local - não expor externamente
      - '127.0.0.1:3000:3000'
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    networks:
      - network
    depends_on:
      - loki
```

**Aplicar mudanças:**

```bash
docker-compose -f loki.yml down
docker-compose -f loki.yml up -d
```

### **Passo 4: Criar Configuração do Nginx**

```bash
# Criar arquivo de configuração
sudo nano /etc/nginx/sites-available/grafana
```

**Cole este conteúdo:**

```nginx
# Configuração inicial - HTTP apenas (para obter certificado)
server {
    listen 80;
    listen [::]:80;
    server_name grafana.erpclass.com.br;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (necessário para algumas features do Grafana)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### **Passo 5: Ativar o Site**

```bash
# Criar link simbólico
sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/

# Remover site padrão (opcional)
sudo rm /etc/nginx/sites-enabled/default

# Testar configuração
sudo nginx -t

# Recarregar Nginx
sudo systemctl reload nginx
```

### **Passo 6: Obter Certificado SSL (Let's Encrypt)**

```bash
# Obter certificado SSL automaticamente
sudo certbot --nginx -d grafana.erpclass.com.br

# Durante o processo, responda:
# 1. Digite seu e-mail
# 2. Aceite os termos (Y)
# 3. Escolha se quer compartilhar e-mail (N é ok)
# 4. Certbot vai configurar HTTPS automaticamente!
```

**O Certbot irá:**

- ✅ Obter certificado SSL
- ✅ Configurar HTTPS automaticamente
- ✅ Redirecionar HTTP → HTTPS
- ✅ Configurar renovação automática

### **Passo 7: Verificar Configuração Final**

Após o Certbot, o arquivo ficará assim:

```bash
# Ver configuração final
sudo cat /etc/nginx/sites-available/grafana
```

Deve ter algo parecido com:

```nginx
server {
    server_name grafana.erpclass.com.br;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    listen [::]:443 ssl ipv6only=on;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/grafana.erpclass.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/grafana.erpclass.com.br/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    if ($host = grafana.erpclass.com.br) {
        return 301 https://$host$request_uri;
    }

    listen 80;
    listen [::]:80;
    server_name grafana.erpclass.com.br;
    return 404;
}
```

### **Passo 8: Configurar Firewall**

```bash
# Permitir HTTP e HTTPS
sudo ufw allow 'Nginx Full'

# Ou manualmente:
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Verificar status
sudo ufw status
```

### **Passo 9: Testar!**

```bash
# Acessar no navegador (sem porta):
https://grafana.erpclass.com.br

# Verificar certificado SSL
curl -I https://grafana.erpclass.com.br
```

---

## 🔄 Renovação Automática do Certificado

O Certbot já configura renovação automática, mas você pode testar:

```bash
# Testar renovação (dry-run)
sudo certbot renew --dry-run

# Ver status do timer de renovação
sudo systemctl status certbot.timer

# Verificar quando expira
sudo certbot certificates
```

O certificado será renovado automaticamente a cada 60 dias.

---

## 🛠️ Configuração Otimizada do Nginx (Opcional)

Para melhor performance e segurança:

```bash
sudo nano /etc/nginx/sites-available/grafana
```

**Configuração completa otimizada:**

```nginx
# Redirecionar HTTP para HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name grafana.erpclass.com.br;
    return 301 https://$host$request_uri;
}

# Servidor HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name grafana.erpclass.com.br;

    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/grafana.erpclass.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/grafana.erpclass.com.br/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/grafana.erpclass.com.br/chain.pem;

    # Configurações SSL modernas
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    # HSTS (opcional - força HTTPS por 1 ano)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Outros headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logs
    access_log /var/log/nginx/grafana.access.log;
    error_log /var/log/nginx/grafana.error.log;

    # Proxy para Grafana
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffering
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # API específica do Grafana (se necessário)
    location /api/live/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

**Aplicar:**

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔒 Configurar Outros Serviços (Opcional)

Você pode fazer o mesmo para outros serviços:

### **RabbitMQ Management**

```bash
sudo nano /etc/nginx/sites-available/rabbitmq
```

```nginx
server {
    listen 80;
    server_name rabbitmq.erpclass.com.br;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name rabbitmq.erpclass.com.br;

    ssl_certificate /etc/letsencrypt/live/rabbitmq.erpclass.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rabbitmq.erpclass.com.br/privkey.pem;

    location / {
        proxy_pass http://localhost:15672;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### **Mongo Express**

```nginx
server {
    listen 443 ssl http2;
    server_name mongo.erpclass.com.br;

    location / {
        proxy_pass http://localhost:8081;
        # ... mesmos headers do Grafana
    }
}
```

---

## 🆘 Troubleshooting

### **Erro: "Connection refused"**

```bash
# Verificar se Grafana está rodando
docker ps | grep grafana

# Verificar se Nginx consegue acessar
curl http://localhost:3000

# Ver logs do Nginx
sudo tail -f /var/log/nginx/error.log
```

### **Erro: "502 Bad Gateway"**

```bash
# Grafana não está respondendo
docker logs grafana -f

# Verificar configuração do proxy
sudo nginx -t

# Reiniciar serviços
docker-compose -f loki.yml restart grafana
sudo systemctl restart nginx
```

### **Certificado SSL não funciona**

```bash
# Verificar DNS
nslookup grafana.erpclass.com.br

# Verificar portas abertas
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Ver logs do Certbot
sudo less /var/log/letsencrypt/letsencrypt.log

# Tentar obter certificado novamente
sudo certbot --nginx -d grafana.erpclass.com.br --force-renewal
```

### **Certificado expirando**

```bash
# Renovar manualmente
sudo certbot renew

# Forçar renovação
sudo certbot renew --force-renewal
```

---

## 📊 Monitoramento

### **Ver logs em tempo real**

```bash
# Nginx
sudo tail -f /var/log/nginx/grafana.access.log
sudo tail -f /var/log/nginx/error.log

# Grafana
docker logs grafana -f
```

### **Verificar status**

```bash
# Nginx
sudo systemctl status nginx

# Certificado SSL
sudo certbot certificates

# Testar SSL
openssl s_client -connect grafana.erpclass.com.br:443 -servername grafana.erpclass.com.br
```

---

## 🎯 Resumo dos Comandos

```bash
# 1. Instalar Nginx e Certbot
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

# 2. Configurar Nginx
sudo nano /etc/nginx/sites-available/grafana
sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# 3. Obter certificado SSL
sudo certbot --nginx -d grafana.erpclass.com.br

# 4. Configurar firewall
sudo ufw allow 'Nginx Full'

# 5. Testar
curl -I https://grafana.erpclass.com.br
```

---

## ✅ Checklist

- [ ] DNS configurado (grafana.erpclass.com.br → IP do servidor)
- [ ] Nginx instalado
- [ ] Certbot instalado
- [ ] Grafana rodando em localhost:3000
- [ ] Arquivo de configuração do Nginx criado
- [ ] Link simbólico criado
- [ ] Certificado SSL obtido
- [ ] Firewall configurado (portas 80 e 443)
- [ ] HTTPS funcionando
- [ ] Renovação automática configurada
- [ ] Logs sendo monitorados

---

## 🌟 Resultado Final

**Antes:**

```
❌ https://grafana.erpclass.com.br:3000/ (erro de certificado)
❌ http://grafana.erpclass.com.br:3000/ (inseguro)
```

**Depois:**

```
✅ https://grafana.erpclass.com.br (seguro, sem porta)
✅ Certificado SSL válido (cadeado verde)
✅ Renovação automática
✅ HTTP → HTTPS automático
```

---

## 📚 Recursos Adicionais

- **Let's Encrypt**: https://letsencrypt.org/
- **Certbot**: https://certbot.eff.org/
- **Nginx SSL Config**: https://ssl-config.mozilla.org/
- **SSL Labs Test**: https://www.ssllabs.com/ssltest/

---

**🔒 Agora seu Grafana está acessível via HTTPS com certificado SSL válido!**
