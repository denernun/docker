# 🐳 Docker Stack - Infraestrutura Completa

Stack completa de infraestrutura com bancos de dados, cache, mensageria e observabilidade.

## 📦 Serviços Incluídos

| Serviço           | Porta(s)    | Descrição             | Credenciais       |
| ----------------- | ----------- | --------------------- | ----------------- |
| **MongoDB**       | 27017       | Banco NoSQL           | root/password     |
| **Mongo Express** | 8081        | Interface Web MongoDB | admin/admin       |
| **MySQL**         | 3306        | Banco Relacional      | root/password     |
| **PostgreSQL**    | 5432        | Banco Relacional      | postgres/postgres |
| **Redis**         | 6379        | Cache em Memória      | -                 |
| **RedisInsight**  | 5540        | Interface Web Redis   | -                 |
| **RabbitMQ**      | 5672, 15672 | Message Broker        | guest/guest       |
| **Loki**          | 3100        | Agregação de Logs     | -                 |
| **Grafana**       | 3000        | Observabilidade       | admin/admin       |

## 🚀 Quick Start

### Windows

```powershell
# Criar rede e volumes
docker network create network
docker volume create mongo
docker volume create mysql
docker volume create postgres
docker volume create redis
docker volume create rabbit
docker volume create loki
docker volume create grafana

# Iniciar serviços
docker-compose -f mongo.yml up -d
docker-compose -f mysql.yml up -d
docker-compose -f postgres.yml up -d
docker-compose -f redis.yml up -d
docker-compose -f rabbitmq.yml up -d
docker-compose -f loki.yml up -d
```

### Ubuntu/Linux

```bash
# Usar o script automatizado
chmod +x deploy-ubuntu.sh
./deploy-ubuntu.sh

# Ou manualmente (mesmos comandos do Windows)
```

## 📖 Documentação Detalhada

### Guias de Setup

- **[UBUNTU-SETUP.md](UBUNTU-SETUP.md)** - Guia completo de instalação e configuração no Ubuntu
- **[README-LOKI-GRAFANA.md](README-LOKI-GRAFANA.md)** - Documentação específica do Loki e Grafana

### Guias de Grafana & Loki

- **[GRAFANA-QUICKSTART.md](GRAFANA-QUICKSTART.md)** - ⚡ Crie seu primeiro dashboard em 5 minutos
- **[GRAFANA-DASHBOARD-GUIDE.md](GRAFANA-DASHBOARD-GUIDE.md)** - 📊 Guia completo de dashboards
- **[LOKI-API-GUIDE.md](LOKI-API-GUIDE.md)** - 📤 Como enviar logs para o Loki via API
- **[grafana-sample-data.sql](grafana-sample-data.sql)** - 💾 Dados de exemplo para praticar

### Guias de Configuração

- **[REDIS-PASSWORD-GUIDE.md](REDIS-PASSWORD-GUIDE.md)** - 🔐 Como configurar senha no Redis
- **[NGINX-SSL-GUIDE.md](NGINX-SSL-GUIDE.md)** - 🔒 Configurar HTTPS com Nginx e Let's Encrypt

## 🛠️ Scripts Auxiliares

### deploy-ubuntu.sh

Script automatizado de deploy para Ubuntu. Verifica dependências, cria rede/volumes e inicia serviços.

```bash
chmod +x deploy-ubuntu.sh
./deploy-ubuntu.sh
```

### stop-all.sh

Para todos os serviços de uma vez.

```bash
chmod +x stop-all.sh
./stop-all.sh
```

### check-status.sh

Verifica o status completo de todos os serviços, rede, volumes e conectividade.

```bash
chmod +x check-status.sh
./check-status.sh
```

## 🌐 Arquitetura de Rede

Todos os serviços estão conectados à rede externa `network`, permitindo comunicação entre containers:

```
┌─────────────────────────────────────────┐
│          Rede: network (bridge)         │
├─────────────────────────────────────────┤
│  mongo          →  172.18.0.x           │
│  mongo-express  →  172.18.0.x           │
│  mysql          →  172.18.0.x           │
│  postgres       →  172.18.0.x           │
│  redis          →  172.18.0.x           │
│  redisinsight   →  172.18.0.x           │
│  rabbitmq       →  172.18.0.x           │
│  loki           →  172.18.0.x           │
│  grafana        →  172.18.0.x           │
└─────────────────────────────────────────┘
```

### Comunicação entre containers

Containers podem se comunicar usando seus hostnames:

```bash
# Exemplo: Do container do Grafana para o PostgreSQL
psql -h postgres -p 5432 -U postgres

# Exemplo: Do container do MySQL para o MongoDB
mongo --host mongo --port 27017
```

## 💾 Volumes Persistentes

Todos os dados são armazenados em volumes Docker externos:

```bash
docker volume ls
```

## ⚙️ Configuração

### Alterar Senhas (Recomendado para Produção)

Edite os arquivos `.yml` antes de fazer deploy em produção:

- `mongo.yml` → `MONGO_INITDB_ROOT_PASSWORD`
- `mysql.yml` → `MYSQL_ROOT_PASSWORD`
- `postgres.yml` → `POSTGRES_PASSWORD`
- `rabbitmq.yml` → `RABBITMQ_DEFAULT_PASS`
- `loki.yml` → `GF_SECURITY_ADMIN_PASSWORD`

### Configurações Customizadas

- **Redis**: Edite `redis.conf`
- **Loki**: Edite `loki-config.yml`
- **Grafana**: Datasources em `grafana/provisioning/datasources/datasources.yml`

## 🔍 Comandos Úteis

### Ver logs de um serviço

```bash
docker logs mongo -f
docker logs grafana -f
```

### Reiniciar um serviço

```bash
docker-compose -f mongo.yml restart
```

### Parar um serviço específico

```bash
docker-compose -f mongo.yml down
```

### Ver status de todos os containers

```bash
docker ps
```

### Ver uso de recursos

```bash
docker stats
```

### Conectar via linha de comando

```bash
# MongoDB
docker exec -it mongo mongosh -u root -p password

# MySQL
docker exec -it mysql mysql -u root -p

# PostgreSQL
docker exec -it postgres psql -U postgres

# Redis
docker exec -it redis redis-cli
```

## 🔒 Segurança

### ⚠️ Atenção para Produção

1. **Altere todas as senhas padrão**
2. **Configure firewall** para permitir apenas IPs confiáveis
3. **Use HTTPS/TLS** para serviços web
4. **Crie backups regulares** dos volumes
5. **Monitore logs** regularmente
6. **Atualize imagens** periodicamente

### Configurar Firewall (Ubuntu)

```bash
# Permitir apenas de IPs específicos
sudo ufw allow from 192.168.1.0/24 to any port 3306
sudo ufw allow from 192.168.1.0/24 to any port 5432
```

## 🆘 Troubleshooting

### Porta já em uso

```bash
# Ver o que está usando a porta
sudo lsof -i :3306
sudo netstat -tulpn | grep 3306
```

### Container não inicia

```bash
# Ver logs detalhados
docker logs nome-do-container

# Ver últimas 50 linhas
docker logs nome-do-container --tail 50
```

### Resetar um serviço completamente

```bash
# Parar e remover container
docker-compose -f servico.yml down

# Remover volume (⚠️ PERDE DADOS)
docker volume rm nome-do-volume

# Recriar volume
docker volume create nome-do-volume

# Reiniciar
docker-compose -f servico.yml up -d
```

## 📊 Backup e Restore

### Backup de volumes

```bash
# Backup MongoDB
docker run --rm -v mongo:/data -v $(pwd):/backup alpine tar czf /backup/mongo-backup.tar.gz -C /data .

# Backup PostgreSQL
docker exec postgres pg_dump -U postgres postgres > postgres-backup.sql

# Backup MySQL
docker exec mysql mysqldump -u root -ppassword --all-databases > mysql-backup.sql
```

### Restore de volumes

```bash
# Restore MongoDB
docker run --rm -v mongo:/data -v $(pwd):/backup alpine tar xzf /backup/mongo-backup.tar.gz -C /data

# Restore PostgreSQL
docker exec -i postgres psql -U postgres < postgres-backup.sql

# Restore MySQL
docker exec -i mysql mysql -u root -ppassword < mysql-backup.sql
```

## 📝 Estrutura de Arquivos

```
.
├── mongo.yml                    # Docker Compose - MongoDB
├── mysql.yml                    # Docker Compose - MySQL
├── postgres.yml                 # Docker Compose - PostgreSQL
├── redis.yml                    # Docker Compose - Redis
├── redis.conf                   # Configuração Redis
├── rabbitmq.yml                 # Docker Compose - RabbitMQ
├── loki.yml                     # Docker Compose - Loki + Grafana
├── loki-config.yml              # Configuração Loki
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── datasources.yml  # Datasources Grafana
├── deploy-ubuntu.sh             # Script de deploy Ubuntu
├── stop-all.sh                  # Script para parar tudo
├── check-status.sh              # Script de verificação
├── UBUNTU-SETUP.md              # Guia Ubuntu completo
└── README-LOKI-GRAFANA.md       # Documentação Loki/Grafana
```

## 🌟 Recursos Adicionais

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)

## 📄 Licença

Este projeto é open source e está disponível sob a licença MIT.

## 👤 Autor

**denernun**

- GitHub: [@denernun](https://github.com/denernun)
- Repository: [docker](https://github.com/denernun/docker)

---

⭐ Se este projeto foi útil, considere dar uma estrela no GitHub!
