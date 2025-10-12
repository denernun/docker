# Loki e Grafana Stack

## Descrição

Stack completa de observabilidade com Loki para logs e Grafana para visualização, integrado com PostgreSQL como fonte de dados.

## Serviços

### Loki

- **Porta**: 3100
- **Hostname**: loki
- **Descrição**: Sistema de agregação de logs
- **Configuração**: `loki-config.yml`

### Grafana

- **Porta**: 3000
- **Hostname**: grafana
- **Usuário**: admin
- **Senha**: admin
- **Descrição**: Plataforma de observabilidade e visualização

## Fontes de Dados Configuradas

O Grafana vem pré-configurado com as seguintes fontes de dados:

### 1. Loki (Padrão)

- **URL**: http://loki:3100
- **Tipo**: Logs
- **Status**: Configurado automaticamente

### 2. PostgreSQL

- **Host**: postgres:5432
- **Database**: postgres
- **Usuário**: postgres
- **Senha**: postgres
- **Status**: Configurado automaticamente

## Como Usar

### 1. Criar os volumes externos

```bash
docker volume create loki
docker volume create grafana
```

### 2. Subir os serviços

```bash
docker-compose -f loki.yml up -d
```

### 3. Acessar o Grafana

Abra o navegador em: http://localhost:3000

- Usuário: `admin`
- Senha: `admin`

### 4. Verificar as fontes de dados

Vá em: **Configuration** → **Data Sources**

Você verá:

- ✅ Loki
- ✅ PostgreSQL

## Estrutura de Arquivos

```
D:\DOCKER\
├── loki.yml                              # Docker Compose principal
├── loki-config.yml                       # Configuração do Loki
└── grafana/
    └── provisioning/
        └── datasources/
            └── datasources.yml           # Fontes de dados pré-configuradas
```

## Comandos Úteis

### Ver logs do Loki

```bash
docker logs loki -f
```

### Ver logs do Grafana

```bash
docker logs grafana -f
```

### Parar os serviços

```bash
docker-compose -f loki.yml down
```

### Reiniciar os serviços

```bash
docker-compose -f loki.yml restart
```

## Verificar Conectividade

### Testar Loki

```bash
curl http://localhost:3100/ready
```

### Testar Grafana

```bash
curl http://localhost:3000/api/health
```

## Integração com Outros Serviços

Como todos os serviços estão na rede `network` (externa), eles podem se comunicar:

- **Grafana** → **Loki**: http://loki:3100
- **Grafana** → **PostgreSQL**: postgres:5432

## Plugins Instalados

O Grafana vem com os seguintes plugins:

- grafana-clock-panel
- grafana-simple-json-datasource

## Troubleshooting

### Grafana não inicia

```bash
docker logs grafana
```

### Fontes de dados não aparecem

Verifique se o arquivo de provisionamento está montado corretamente:

```bash
docker exec grafana ls -la /etc/grafana/provisioning/datasources/
```

## Notas Importantes

1. ⚠️ A rede `network` deve existir antes de executar o compose
2. ⚠️ Os volumes `loki` e `grafana` devem ser criados antes
3. ⚠️ O serviço PostgreSQL deve estar rodando para a fonte de dados funcionar
4. 📝 As credenciais padrão devem ser alteradas em produção

## Próximos Passos

1. Criar dashboards no Grafana
2. Configurar alertas no Loki
3. Adicionar mais fontes de dados conforme necessário
4. Configurar retention de logs no Loki
