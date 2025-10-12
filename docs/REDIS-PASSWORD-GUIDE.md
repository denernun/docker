# 🔐 Configurando Senha no Redis

## 📝 Como Definir uma Senha

### **Método 1: Editando o redis.conf (Recomendado)**

#### Passo 1: Editar o arquivo redis.conf

Abra o arquivo `redis.conf` e adicione ou descomente a linha:

```bash
# Editar o arquivo
nano redis.conf
# ou
code redis.conf
```

Adicione ou descomente:

```nginx
# Definir senha de autenticação
requirepass SuaSenhaForteAqui123
```

#### Passo 2: Reiniciar o Redis

```bash
# Reiniciar o container para aplicar a mudança
docker-compose -f redis.yml restart redis
```

#### Passo 3: Testar a conexão

```bash
# Sem senha (vai falhar)
docker exec -it redis redis-cli ping
# Resposta: (error) NOAUTH Authentication required

# Com senha (vai funcionar)
docker exec -it redis redis-cli -a SuaSenhaForteAqui123 ping
# Resposta: PONG
```

---

### **Método 2: Via Linha de Comando (Temporário)**

Este método configura a senha apenas até o Redis reiniciar:

```bash
# Entrar no Redis CLI
docker exec -it redis redis-cli

# Definir senha
CONFIG SET requirepass "MinhasenhaForte123"

# Autenticar
AUTH MinhasenhaForte123

# Testar
PING
```

⚠️ **Atenção:** Esta configuração é perdida ao reiniciar o container!

---

### **Método 3: Alterando o docker-compose (Alternativo)**

Você também pode passar a senha como argumento no comando:

**Editar redis.yml:**

```yaml
services:
  redis:
    image: redis
    hostname: redis
    container_name: redis
    restart: always
    command: ['redis-server', '/usr/local/etc/redis/redis.conf', '--requirepass', 'SuaSenhaAqui123']
    ports:
      - '6379:6379'
    networks:
      - network
    volumes:
      - data:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf
```

⚠️ **Menos seguro:** A senha fica visível no arquivo docker-compose

---

## 🚀 Passo a Passo Completo

### 1️⃣ **Editar o redis.conf**

```bash
# Abrir o arquivo
nano d:/DOCKER/redis.conf
```

Adicione esta linha (descomente se já existir):

```nginx
bind 0.0.0.0
port 6379
protected-mode no

# Senha de autenticação
requirepass MinhaSenhaSegura123!
```

### 2️⃣ **Reiniciar o Redis**

```bash
# Reiniciar o container
docker-compose -f redis.yml restart redis

# Ou parar e subir novamente
docker-compose -f redis.yml down
docker-compose -f redis.yml up -d
```

### 3️⃣ **Verificar se a senha está ativa**

```bash
# Tentar sem senha (deve falhar)
docker exec -it redis redis-cli ping

# Com senha (deve funcionar)
docker exec -it redis redis-cli -a MinhaSenhaSegura123! ping
```

---

## 💻 Como Usar o Redis com Senha

### **No Redis CLI**

```bash
# Opção 1: Passar senha no comando
docker exec -it redis redis-cli -a SuaSenha

# Opção 2: Autenticar depois de entrar
docker exec -it redis redis-cli
> AUTH SuaSenha
> PING
PONG
```

### **Em Python**

```python
import redis

# Conectar com senha
r = redis.Redis(
    host='localhost',
    port=6379,
    password='SuaSenha',
    decode_responses=True
)

# Testar conexão
print(r.ping())  # True

# Usar normalmente
r.set('chave', 'valor')
print(r.get('chave'))  # 'valor'
```

### **Em Node.js**

```javascript
const redis = require('redis');

// Conectar com senha
const client = redis.createClient({
  host: 'localhost',
  port: 6379,
  password: 'SuaSenha',
});

client.on('connect', () => {
  console.log('Conectado ao Redis com sucesso!');
});

// Usar normalmente
client.set('chave', 'valor', (err, reply) => {
  console.log(reply); // OK
});
```

### **Em PHP**

```php
<?php
$redis = new Redis();
$redis->connect('localhost', 6379);

// Autenticar com senha
$redis->auth('SuaSenha');

// Testar
echo $redis->ping(); // +PONG

// Usar normalmente
$redis->set('chave', 'valor');
echo $redis->get('chave'); // valor
?>
```

### **Em Go**

```go
package main

import (
    "fmt"
    "github.com/go-redis/redis/v8"
    "context"
)

func main() {
    ctx := context.Background()

    // Conectar com senha
    rdb := redis.NewClient(&redis.Options{
        Addr:     "localhost:6379",
        Password: "SuaSenha",
        DB:       0,
    })

    // Testar
    pong, err := rdb.Ping(ctx).Result()
    fmt.Println(pong, err) // PONG <nil>

    // Usar normalmente
    rdb.Set(ctx, "chave", "valor", 0)
}
```

### **Via cURL (HTTP REST API com Webdis - requer instalação)**

```bash
# Se estiver usando Webdis ou similar
curl -d "AUTH SuaSenha" http://localhost:7379/
curl http://localhost:7379/PING
```

---

## 🔧 Configurar RedisInsight com Senha

Quando você adicionar a conexão no RedisInsight:

1. Abra http://localhost:5540
2. Clique em **"Add Redis Database"**
3. Preencha:
   ```
   Host: redis (ou localhost)
   Port: 6379
   Database Alias: Redis Local
   Username: (deixe em branco)
   Password: SuaSenha
   ```
4. Clique em **"Add Redis Database"**

---

## 📊 Configurar Redis como Data Source no Grafana (se usar plugin)

Se você instalar um plugin de Redis no Grafana:

```yaml
# Em grafana/provisioning/datasources/datasources.yml
- name: Redis
  type: redis-datasource
  access: proxy
  url: redis:6379
  jsonData:
    client: standalone
  secureJsonData:
    password: SuaSenha
```

---

## 🔐 Boas Práticas de Segurança

### ✅ **Recomendações:**

1. **Use senhas fortes:**

   ```
   ✅ Boa: X7#mK9$pL2@nQ4&vR8!wT3
   ❌ Ruim: 123456, senha, redis
   ```

2. **Gere senhas aleatórias:**

   ```bash
   # No Linux/Ubuntu
   openssl rand -base64 32

   # No PowerShell
   -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | % {[char]$_})
   ```

3. **Use variáveis de ambiente:**

   ```yaml
   # docker-compose.yml
   command: ['redis-server', '--requirepass', '${REDIS_PASSWORD}']
   ```

4. **Não exponha a porta publicamente:**

   ```yaml
   # Apenas local
   ports:
     - '127.0.0.1:6379:6379'
   ```

5. **Configure firewall:**
   ```bash
   # Ubuntu - permitir apenas de IPs confiáveis
   sudo ufw allow from 192.168.1.0/24 to any port 6379
   ```

### ⚠️ **Evite:**

❌ Senhas fracas (123456, senha, etc.)
❌ Senha no histórico de comandos
❌ Senha em logs ou arquivos públicos
❌ Redis sem senha em produção
❌ Expor porta 6379 na internet sem proteção

---

## 🔍 Verificar Configuração

### **Ver configuração atual:**

```bash
# Entrar no Redis CLI
docker exec -it redis redis-cli -a SuaSenha

# Ver se a senha está configurada
CONFIG GET requirepass
```

### **Ver todas as configurações:**

```bash
# Dentro do Redis CLI
CONFIG GET *
```

### **Verificar arquivo de configuração:**

```bash
# Ver o conteúdo do redis.conf
docker exec redis cat /usr/local/etc/redis/redis.conf
```

---

## 🆘 Troubleshooting

### **Problema: "NOAUTH Authentication required"**

✅ **Solução:**

```bash
# Você precisa autenticar
docker exec -it redis redis-cli -a SuaSenha
# ou
docker exec -it redis redis-cli
> AUTH SuaSenha
```

### **Problema: "ERR invalid password"**

✅ **Verifique:**

- Senha está correta?
- Reiniciou o Redis após editar o redis.conf?
- Caracteres especiais precisam de escape?

### **Problema: Senha não está sendo aplicada**

✅ **Verifique:**

```bash
# Ver se o arquivo está sendo montado corretamente
docker exec redis cat /usr/local/etc/redis/redis.conf | grep requirepass

# Ver logs do Redis
docker logs redis
```

### **Problema: Aplicação não consegue conectar**

✅ **Verifique:**

- A senha está correta no código?
- A aplicação está na mesma rede Docker?
- Use hostname `redis` (não `localhost`) se estiver em outro container

---

## 🔄 Alterar a Senha

Se você já tem uma senha e quer alterar:

1. **Edite o redis.conf:**

   ```nginx
   requirepass NovaSenhaAqui
   ```

2. **Reinicie o Redis:**

   ```bash
   docker-compose -f redis.yml restart redis
   ```

3. **Atualize suas aplicações** com a nova senha

---

## 📝 Exemplo Completo de redis.conf com Senha

```nginx
# Bind para aceitar conexões de qualquer IP
bind 0.0.0.0

# Porta padrão
port 6379

# Desabilitar protected-mode (já que usamos senha)
protected-mode no

# SENHA DE AUTENTICAÇÃO
requirepass MinhaSenhaSegura123!

# Persistência de dados
save 900 1
save 300 10
save 60 10000

# Arquivo de persistência
dbfilename dump.rdb
dir /data

# Logs
loglevel notice

# Máximo de memória (opcional)
# maxmemory 256mb
# maxmemory-policy allkeys-lru

# Configurações de performance
tcp-keepalive 300
timeout 0
```

---

## ✅ Checklist de Configuração

- [ ] Editar `redis.conf` e adicionar `requirepass SuaSenha`
- [ ] Reiniciar o Redis com `docker-compose -f redis.yml restart`
- [ ] Testar conexão com senha: `docker exec -it redis redis-cli -a SuaSenha ping`
- [ ] Atualizar RedisInsight com a senha
- [ ] Atualizar suas aplicações com a senha
- [ ] Documentar a senha em local seguro (gerenciador de senhas)
- [ ] Configurar firewall se necessário
- [ ] Testar backup/restore com senha

---

## 🎯 Resumo Rápido

```bash
# 1. Editar redis.conf
echo "requirepass MinhaSenha123" >> redis.conf

# 2. Reiniciar Redis
docker-compose -f redis.yml restart redis

# 3. Testar
docker exec -it redis redis-cli -a MinhaSenha123 ping
# Resposta: PONG

# 4. Usar normalmente
docker exec -it redis redis-cli -a MinhaSenha123
> SET teste "valor"
> GET teste
```

---

**🔐 Agora seu Redis está protegido com senha!**

**💡 Dica:** Guarde a senha em um gerenciador de senhas seguro e atualize todas as aplicações que usam o Redis.
