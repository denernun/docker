#!/bin/bash

# Script para verificar o status de todos os serviços

echo "=================================="
echo "📊 Status dos Serviços Docker"
echo "=================================="
echo ""

# Verificar se a rede existe
echo "🌐 Rede:"
if docker network ls | grep -q "network"; then
    echo "✅ Rede 'network' existe"
else
    echo "❌ Rede 'network' NÃO existe"
fi
echo ""

# Verificar volumes
echo "💾 Volumes:"
volumes=("postgres" "redis" "loki" "grafana")
for vol in "${volumes[@]}"; do
    if docker volume ls | grep -q "^local.*$vol\$"; then
        echo "✅ Volume '$vol' existe"
    else
        echo "❌ Volume '$vol' NÃO existe"
    fi
done
echo ""

# Verificar containers
echo "🐳 Containers em execução:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|postgres|redis|loki|grafana"
echo ""

# Verificar uso de recursos
echo "📈 Uso de Recursos:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -20
echo ""

# Verificar espaço em disco
echo "💿 Espaço em Disco Docker:"
docker system df
echo ""

# URLs de acesso
echo "🌐 URLs de Acesso:"
echo "  - PostgreSQL: localhost:5432 (postgres/postgres)"
echo "  - Redis: localhost:6379"
echo "  - RedisInsight: http://localhost:5540"
echo "  - Grafana: http://localhost:3000 (admin/admin)"
echo "  - Loki: http://localhost:3100"
echo ""

# Testar conectividade
echo "🔍 Teste de Conectividade:"
services=("localhost:5432" "localhost:6379" "localhost:5540" "localhost:3000" "localhost:3100")
names=("PostgreSQL" "Redis" "RedisInsight" "Grafana" "Loki")

for i in "${!services[@]}"; do
    service="${services[$i]}"
    name="${names[$i]}"
    host=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)

    if timeout 2 bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null; then
        echo "✅ $name - Porta $port aberta"
    else
        echo "❌ $name - Porta $port fechada/não responde"
    fi
done
echo ""

echo "=================================="
echo "✅ Verificação completa!"
echo "=================================="
