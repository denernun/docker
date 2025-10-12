#!/bin/bash

# Script para parar todos os serviços

echo "🛑 Parando todos os serviços Docker..."
echo ""

services=("loki" "grafana" "nginx" "redis" "postgres")

for service in "${services[@]}"; do
    echo "⏸️  Parando $service..."
    docker-compose -f ${service}.yml down
    echo "✅ $service parado"
    echo ""
done

echo "✅ Todos os serviços foram parados!"
echo ""
echo "📊 Containers restantes:"
docker ps -a
