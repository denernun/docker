# 🔧 Nginx Proxy Reverso - Configuração

## 📁 Estrutura de Arquivos

```
nginx/
├── nginx.conf          # Configuração principal do Nginx
├── options.conf        # Opções de SSL/TLS
├── general.conf        # Configurações gerais (security headers, cache)
├── proxy.conf          # Configurações de proxy (headers, timeouts)
├── erpclass.conf       # Virtual host para grafana.erpclass.com.br
└── dhparam.pem        # Diffie-Hellman parameters (gerado no setup)

nginx.yml               # Docker Compose do Nginx + Grafana
setup-nginx.sh          # Script de instalação automatizada
```

## 🚀 Instalação Rápida

### **Passo 1: Executar o setup automático**

```bash
# Dar permissão de execução
chmod +x setup-nginx.sh

# Executar o script
./setup-nginx.sh
```

O script irá:

- ✅ Verificar dependências (Docker, Docker Compose)
- ✅ Criar volumes necessários
- ✅ Gerar DH parameters (2048 bits)
- ✅ Verificar arquivos de configuração
- ✅ Verificar DNS
- ✅ Instalar Certbot (opcional)
- ✅ Configurar certificados SSL
- ✅ Iniciar serviços

---

## 📋 Instalação Manual

### **1. Criar volumes Docker**

```bash
docker volume create letsencrypt
docker volume create nginx-logs
docker volume create grafana-data
```

### **2. Criar rede (se não existir)**

```bash
docker network create network
```

### **3. Gerar DH Parameters**

```bash
# Gerar arquivo dhparam.pem (pode levar alguns minutos)
openssl dhparam -out ./nginx/dhparam.pem 2048
```

### **4. Obter Certificado SSL (Let's Encrypt)**

**Opção A: Usando Certbot no host**

```bash
# Instalar Certbot
sudo apt install -y certbot

# Obter certificado
sudo certbot certonly --standalone -d grafana.erpclass.com.br

# Copiar certificados para o volume Docker
docker run --rm \
  -v letsencrypt:/target \
  -v /etc/letsencrypt:/source:ro \
  alpine sh -c "cp -r /source/* /target/"
```

**Opção B: Usando Certbot em container**

```bash
# Obter certificado usando container
docker run -it --rm \
  -v letsencrypt:/etc/letsencrypt \
  -p 80:80 \
  certbot/certbot certonly \
  --standalone \
  -d grafana.erpclass.com.br \
  --agree-tos \
  --email seu-email@example.com
```

### **5. Iniciar serviços**

```bash
# Iniciar Nginx e Grafana
docker-compose -f nginx.yml up -d

# Ver logs
docker-compose -f nginx.yml logs -f

# Ver status
docker-compose -f nginx.yml ps
```

---

## 🔍 Verificação

### **Testar configuração do Nginx**

```bash
# Testar sintaxe
docker exec nginx nginx -t

# Ver configuração ativa
docker exec nginx nginx -T

# Verificar versão
docker exec nginx nginx -v
```

### **Verificar certificado SSL**

```bash
# Verificar certificado
openssl s_client -connect grafana.erpclass.com.br:443 -servername grafana.erpclass.com.br

# Verificar data de expiração
echo | openssl s_client -connect grafana.erpclass.com.br:443 2>/dev/null | openssl x509 -noout -dates
```

### **Testar conectividade**

```bash
# Testar HTTP (deve redirecionar para HTTPS)
curl -I http://grafana.erpclass.com.br

# Testar HTTPS
curl -I https://grafana.erpclass.com.br

# Verificar headers de segurança
curl -I https://grafana.erpclass.com.br | grep -E "X-|Strict|Content-Security"
```

---

## 📊 Monitoramento

### **Ver logs**

```bash
# Logs em tempo real
docker-compose -f nginx.yml logs -f

# Logs apenas do Nginx
docker logs nginx -f

# Logs apenas do Grafana
docker logs grafana -f

# Últimas 100 linhas
docker logs nginx --tail 100

# Logs com timestamps
docker logs nginx -t
```

### **Verificar status**

```bash
# Status dos containers
docker-compose -f nginx.yml ps

# Usar recursos
docker stats nginx grafana

# Health check
docker inspect nginx | grep -A 10 Health
```

### **Acessar logs persistentes**

```bash
# Ver logs do volume
docker run --rm -v nginx-logs:/logs alpine ls -lah /logs

# Ver access log
docker run --rm -v nginx-logs:/logs alpine tail -f /logs/access.log

# Ver error log
docker run --rm -v nginx-logs:/logs alpine tail -f /logs/error.log
```

---

## 🔄 Gerenciamento

### **Reiniciar serviços**

```bash
# Reiniciar apenas Nginx
docker-compose -f nginx.yml restart nginx

# Reiniciar apenas Grafana
docker-compose -f nginx.yml restart grafana

# Reiniciar tudo
docker-compose -f nginx.yml restart
```

### **Recarregar configuração (sem downtime)**

```bash
# Testar configuração primeiro
docker exec nginx nginx -t

# Recarregar
docker exec nginx nginx -s reload
```

### **Parar serviços**

```bash
# Parar containers (preserva volumes)
docker-compose -f nginx.yml down

# Parar e remover volumes (CUIDADO!)
docker-compose -f nginx.yml down -v
```

### **Atualizar imagens**

```bash
# Baixar imagens mais recentes
docker-compose -f nginx.yml pull

# Recriar containers com novas imagens
docker-compose -f nginx.yml up -d --force-recreate
```

---

## 🔐 Renovação de Certificado SSL

### **Renovação Automática (Recomendado)**

```bash
# Criar script de renovação
sudo nano /etc/cron.monthly/renew-cert.sh
```

Conteúdo do script:

```bash
#!/bin/bash
# Renovar certificado
certbot renew --quiet

# Copiar para volume Docker
docker run --rm \
  -v letsencrypt:/target \
  -v /etc/letsencrypt:/source:ro \
  alpine sh -c "cp -r /source/* /target/"

# Recarregar Nginx
docker exec nginx nginx -s reload

echo "$(date): Certificado renovado e Nginx recarregado" >> /var/log/cert-renewal.log
```

```bash
# Dar permissão
sudo chmod +x /etc/cron.monthly/renew-cert.sh
```

### **Renovação Manual**

```bash
# Parar Nginx temporariamente (libera porta 80)
docker-compose -f nginx.yml stop nginx

# Renovar certificado
sudo certbot renew

# Copiar certificados atualizados
docker run --rm \
  -v letsencrypt:/target \
  -v /etc/letsencrypt:/source:ro \
  alpine sh -c "cp -r /source/* /target/"

# Iniciar Nginx
docker-compose -f nginx.yml start nginx
```

---

## ⚙️ Configuração Detalhada

### **Arquivos de Configuração**

#### **nginx.conf**

- Configuração principal do Nginx
- Workers, eventos, HTTP settings
- Compressão gzip
- Logs
- Include de outros arquivos

#### **options.conf**

- Configurações de SSL/TLS
- Protocolos (TLSv1.2, TLSv1.3)
- Ciphers modernos
- OCSP Stapling
- Session cache

#### **general.conf**

- Security headers (X-Frame-Options, CSP, HSTS)
- Cache de assets estáticos
- Proteção de arquivos sensíveis
- Favicon, robots.txt

#### **proxy.conf**

- Headers de proxy
- Timeouts
- Buffer settings
- WebSocket support
- Failover settings

#### **erpclass.conf**

- Virtual host para grafana.erpclass.com.br
- Redirecionamento HTTP → HTTPS
- Certificados SSL
- Proxy pass para Grafana

---

## 🔧 Customização

### **Adicionar novo domínio**

1. Criar novo arquivo de configuração:

```bash
nano nginx/novo-dominio.conf
```

2. Adicionar configuração:

```nginx
server {
    listen 80;
    server_name novo.erpclass.com.br;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name novo.erpclass.com.br;

    ssl_certificate /etc/letsencrypt/live/erpclass.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/erpclass.com.br/privkey.pem;

    include /etc/nginx/general.conf;

    location / {
        proxy_pass http://nome-do-container:porta;
        include /etc/nginx/proxy.conf;
    }
}
```

3. Adicionar ao nginx.yml:

```yaml
volumes:
  - ./nginx/novo-dominio.conf:/etc/nginx/conf.d/novo-dominio.conf:ro
```

4. Recarregar:

```bash
docker exec nginx nginx -t
docker exec nginx nginx -s reload
```

---

## 🆘 Troubleshooting

### **Erro: "nginx: [emerg] bind() to 0.0.0.0:80 failed"**

```bash
# Ver o que está usando a porta 80
sudo lsof -i :80
# ou
sudo netstat -tulpn | grep :80

# Parar o serviço conflitante
sudo systemctl stop apache2  # exemplo
```

### **Erro: "502 Bad Gateway"**

```bash
# Verificar se Grafana está rodando
docker ps | grep grafana

# Ver logs do Grafana
docker logs grafana

# Verificar rede
docker network inspect network
```

### **Certificado SSL não funciona**

```bash
# Verificar se certificados existem no volume
docker run --rm -v letsencrypt:/certs alpine ls -la /certs/live

# Verificar permissões
docker exec nginx ls -la /etc/letsencrypt/live/

# Ver logs de erro do Nginx
docker logs nginx | grep ssl
```

### **Configuração não atualiza**

```bash
# Testar configuração
docker exec nginx nginx -t

# Forçar recriação do container
docker-compose -f nginx.yml up -d --force-recreate nginx
```

---

## 📊 Performance

### **Otimizações aplicadas**

✅ **Compressão Gzip**: Nível 9, todos os tipos relevantes
✅ **HTTP/2**: Habilitado em todas as conexões HTTPS
✅ **Keep-Alive**: Otimizado para conexões persistentes
✅ **Cache de Assets**: CSS, JS, fontes, imagens
✅ **Buffer Otimizado**: Para proxy e client
✅ **SSL Session Cache**: 10MB compartilhado
✅ **Open File Cache**: Para arquivos estáticos

### **Testar performance**

```bash
# Teste de velocidade
curl -w "@curl-format.txt" -o /dev/null -s https://grafana.erpclass.com.br

# Verificar compressão
curl -H "Accept-Encoding: gzip" -I https://grafana.erpclass.com.br

# Benchmark
ab -n 1000 -c 10 https://grafana.erpclass.com.br/
```

---

## ✅ Checklist de Produção

- [ ] DNS configurado corretamente
- [ ] Certificado SSL obtido e válido
- [ ] DH parameters gerado (2048 bits ou 4096)
- [ ] Firewall configurado (portas 80 e 443)
- [ ] Logs sendo monitorados
- [ ] Renovação automática de certificado configurada
- [ ] Backup dos volumes configurado
- [ ] Headers de segurança verificados
- [ ] HTTPS funcionando corretamente
- [ ] HTTP redirecionando para HTTPS
- [ ] Performance testada

---

## 📚 Recursos

- **Nginx Docs**: https://nginx.org/en/docs/
- **SSL Labs Test**: https://www.ssllabs.com/ssltest/
- **Let's Encrypt**: https://letsencrypt.org/
- **Security Headers**: https://securityheaders.com/

---

**🔒 Nginx configurado com SSL, pronto para produção!**
