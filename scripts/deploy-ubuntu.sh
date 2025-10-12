#!/bin/bash

# Script de Deploy Completo para Ubuntu
# Autor: Auto-gerado
# Data: 2025-10-11

set -e  # Parar em caso de erro

echo "=================================="
echo "🐧 Deploy Docker Stack - Ubuntu"
echo "=================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir com cores
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Verificar se Docker está instalado
echo "1. Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker não está instalado!"
    echo "Execute: curl -fsSL https://get.docker.com | sh"
    exit 1
fi
print_success "Docker instalado: $(docker --version)"

# Verificar se Docker Compose está instalado
echo ""
echo "2. Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose não está instalado!"
    echo "Execute: sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
    echo "sudo chmod +x /usr/local/bin/docker-compose"
    exit 1
fi
print_success "Docker Compose instalado: $(docker-compose --version)"

# Criar rede externa
echo ""
echo "3. Criando rede externa 'network'..."
if docker network ls | grep -q "network"; then
    print_info "Rede 'network' já existe"
else
    docker network create network
    print_success "Rede 'network' criada"
fi

# Criar volumes externos
echo ""
echo "4. Criando volumes externos..."
volumes=("postgres" "redis" "loki" "grafana")

for vol in "${volumes[@]}"; do
    if docker volume ls | grep -q "^local.*$vol\$"; then
        print_info "Volume '$vol' já existe"
    else
        docker volume create $vol
        print_success "Volume '$vol' criado"
    fi
done

# Verificar arquivos necessários
echo ""
echo "5. Verificando arquivos necessários..."
files=("postgres.yml" "redis.yml" "redis.conf" "loki.yml" "loki-config.yml")

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        print_success "Arquivo '$file' encontrado"
    else
        print_error "Arquivo '$file' não encontrado!"
        exit 1
    fi
done

# Perguntar se quer iniciar os serviços
echo ""
read -p "Deseja iniciar todos os serviços agora? (s/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[SsYy]$ ]]; then
    echo ""
    echo "6. Iniciando serviços..."

    services=("postgres" "redis" "loki")

    for service in "${services[@]}"; do
        echo ""
        print_info "Iniciando $service..."
        docker-compose -f ${service}.yml up -d
        print_success "$service iniciado"
        sleep 2
    done

    echo ""
    echo "=================================="
    print_success "Todos os serviços foram iniciados!"
    echo "=================================="
    echo ""

    echo "📊 Status dos containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    echo ""
    echo "🌐 URLs de acesso:"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Redis: localhost:6379"
    echo "  - RedisInsight: http://localhost:5540"
    echo "  - Grafana: http://localhost:3000"
    echo "  - Loki: http://localhost:3100"

else
    print_info "Serviços não foram iniciados. Execute manualmente:"
    echo "  docker-compose -f postgres.yml up -d"
    echo "  docker-compose -f redis.yml up -d"
    echo "  docker-compose -f loki.yml up -d"
fi

echo ""
print_success "Setup completo!"
