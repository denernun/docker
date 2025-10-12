# 🐧 Guia de Deploy no Ubuntu Server

## Pré-requisitos

### 1. Instalar Docker no Ubuntu

```bash
# Atualizar sistema
sudo apt update
sudo apt upgrade -y

# Instalar dependências
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Adicionar chave GPG do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Adicionar repositório do Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Verificar instalação
sudo docker --version
```

### 2. Instalar Docker Compose

```bash
# Baixar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Dar permissão de execução
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalação
docker-compose --version
```

### 3. Configurar usuário para usar Docker sem sudo (Opcional)

```bash
# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Aplicar mudanças (requer logout/login ou executar)
newgrp docker

# Testar
docker ps
```

## 📦 Preparação dos Arquivos

### 1. Transferir arquivos para o Ubuntu

**Opção A: Via SCP (do Windows para Ubuntu)**

```powershell
# No PowerShell do Windows
scp -r D:\DOCKER usuario@ip-do-servidor:/home/usuario/
```

**Opção B: Via Git (RECOMENDADO)**

```bash
# No Ubuntu
cd ~
git clone https://github.com/denernun/docker.git
cd docker
```

**Opção C: Criar pasta manualmente**

```bash
# No Ubuntu
mkdir -p ~/docker
cd ~/docker
# Depois copie os arquivos via SFTP/SCP
```

## ✅ Verificações Importantes

### 1. Verificar estrutura de arquivos

```bash
cd ~/docker  # ou o diretório onde estão os arquivos
ls -la

# Você deve ver:
# - postgres.yml
# - redis.yml
# - redis.conf
# - loki.yml
# - loki-config.yml
# - grafana/ (diretório)
```

### 2. Verificar permissões

```bash
# Dar permissões de leitura aos arquivos de configuração
chmod 644 redis.conf
chmod 644 loki-config.yml
chmod -R 644 grafana/provisioning/
```

## 🚀 Inicialização dos Serviços

### 1. Criar a rede externa

```bash
docker network create network
```

### 2. Criar os volumes externos

```bash
# Criar todos os volumes necessários
docker volume create postgres
docker volume create redis
docker volume create loki
docker volume create grafana
```

### 3. Iniciar os serviços

#### Iniciar todos os serviços de uma vez:

```bash
cd ~/docker

# Subir todos os serviços
docker-compose -f postgres.yml up -d
docker-compose -f redis.yml up -d
docker-compose -f loki.yml up -d
```

#### Ou criar um script para facilitar:

```bash
# Criar script de inicialização
cat > start-all.sh << 'EOF'
#!/bin/bash
echo "🚀 Iniciando todos os serviços..."

services=("postgres" "redis" "loki")

for service in "${services[@]}"; do
    echo "▶️  Iniciando $service..."
    docker-compose -f ${service}.yml up -d
    echo "✅ $service iniciado"
    echo ""
done

echo "🎉 Todos os serviços foram iniciados!"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
EOF

# Dar permissão de execução
chmod +x start-all.sh

# Executar
./start-all.sh
```

## 🔍 Verificação e Monitoramento

### Verificar containers rodando

```bash
docker ps
```

### Verificar logs de um serviço específico

```bash
docker logs postgres -f
docker logs redis -f
docker logs loki -f
docker logs grafana -f
```

### Verificar rede

```bash
docker network inspect network
```

### Verificar volumes

```bash
docker volume ls
```

## 🔥 Firewall e Portas

### Configurar UFW (se estiver usando)

```bash
# Habilitar UFW
sudo ufw enable

# Permitir SSH (IMPORTANTE!)
sudo ufw allow 22/tcp

# Permitir portas dos serviços
sudo ufw allow 5432/tcp    # PostgreSQL
sudo ufw allow 6379/tcp    # Redis
sudo ufw allow 5540/tcp    # RedisInsight
sudo ufw allow 3100/tcp    # Loki
sudo ufw allow 3000/tcp    # Grafana

# Verificar status
sudo ufw status
```

### Verificar portas abertas

```bash
sudo netstat -tulpn | grep LISTEN
# ou
sudo ss -tulpn | grep LISTEN
```

## 🔄 Gerenciamento de Serviços

### Parar todos os serviços

```bash
# Criar script de parada
cat > stop-all.sh << 'EOF'
#!/bin/bash
echo "🛑 Parando todos os serviços..."

services=("loki" "redis" "postgres")

for service in "${services[@]}"; do
    echo "⏸️  Parando $service..."
    docker-compose -f ${service}.yml down
    echo "✅ $service parado"
    echo ""
done

echo "✅ Todos os serviços foram parados!"
EOF

chmod +x stop-all.sh
./stop-all.sh
```

### Ver uso de recursos

```bash
docker stats
```

## 🆘 Troubleshooting

### Problema: "Permission denied" ao executar docker

**Solução:**

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Problema: Porta já em uso

**Solução:**

```bash
# Ver o que está usando a porta (exemplo: 3306)
sudo lsof -i :3306
# ou
sudo netstat -tulpn | grep 3306

# Matar o processo se necessário
sudo kill -9 PID
```

### Problema: Container não inicia

**Solução:**

```bash
# Ver logs detalhados
docker logs nome-do-container

# Ver eventos
docker events

# Inspecionar container
docker inspect nome-do-container
```

### Problema: Volume com dados corrompidos

**Solução:**

```bash
# Parar o serviço
docker-compose -f servico.yml down

# Remover volume
docker volume rm nome-do-volume

# Recriar volume
docker volume create nome-do-volume

# Reiniciar serviço
docker-compose -f servico.yml up -d
```

## 📊 Monitoramento de Recursos

### Verificar espaço em disco

```bash
# Espaço usado pelo Docker
docker system df

# Detalhes
docker system df -v
```

### Limpar recursos não utilizados

```bash
# Limpar tudo (cuidado!)
docker system prune -a

# Limpar apenas imagens não utilizadas
docker image prune -a

# Limpar volumes não utilizados (CUIDADO - PODE PERDER DADOS!)
docker volume prune
```

## 🔐 Segurança

### 1. Alterar senhas padrão

Edite os arquivos `.yml` e altere as senhas antes de subir em produção:

- MongoDB: `MONGO_INITDB_ROOT_PASSWORD`
- MySQL: `MYSQL_ROOT_PASSWORD`
- PostgreSQL: `POSTGRES_PASSWORD`
- RabbitMQ: `RABBITMQ_DEFAULT_PASS`
- Grafana: `GF_SECURITY_ADMIN_PASSWORD`

### 2. Usar variáveis de ambiente

Crie um arquivo `.env` para cada serviço:

```bash
# Exemplo para postgres
cat > postgres.env << EOF
POSTGRES_PASSWORD=sua-senha-forte-aqui
POSTGRES_USER=postgres
POSTGRES_DB=postgres
EOF

# Referenciar no docker-compose.yml
# env_file:
#   - postgres.env
```

### 3. Restringir acesso externo

Configure o firewall para permitir acesso apenas de IPs específicos:

```bash
# Exemplo: permitir acesso ao PostgreSQL apenas de um IP específico
sudo ufw delete allow 5432/tcp
sudo ufw allow from 192.168.1.100 to any port 5432
```

## 📝 Diferenças Windows vs Linux

| Aspecto            | Windows          | Linux/Ubuntu                         |
| ------------------ | ---------------- | ------------------------------------ |
| **Caminhos**       | `d:/DOCKER/file` | `./file` ou `/home/user/docker/file` |
| **Separador**      | `\` ou `/`       | `/`                                  |
| **Docker Desktop** | Necessário       | Não necessário                       |
| **Performance**    | Via WSL2 ou VM   | Nativo (mais rápido)                 |
| **Comandos**       | PowerShell       | Bash                                 |
| **Permissões**     | Menos restritivo | Mais restritivo (chmod/chown)        |

## ✅ Checklist de Migração

- [ ] Docker e Docker Compose instalados
- [ ] Arquivos transferidos para o servidor
- [ ] Caminhos relativos corrigidos (já feito no redis.yml)
- [ ] Rede `network` criada
- [ ] Volumes externos criados
- [ ] Senhas alteradas (se produção)
- [ ] Firewall configurado
- [ ] Serviços iniciados
- [ ] Testes de conectividade realizados
- [ ] Backup dos volumes configurado (recomendado)

## 🎯 Pronto para Produção

Seu ambiente está pronto! Os arquivos docker-compose já estão configurados para funcionar tanto no Windows quanto no Linux/Ubuntu.

A única alteração necessária foi mudar o caminho absoluto do Windows (`d:/DOCKER/`) para um caminho relativo (`./`) no arquivo `redis.yml`, que já foi corrigido.
