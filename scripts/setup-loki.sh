#!/bin/bash

# ========================================
# Script de Setup do Nginx com SSL
# ========================================

set -e

echo "=========================================="
echo "🔧 Setup Nginx + SSL + Grafana"
echo "=========================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# ========================================
# 1. Verificar Docker
# ========================================
echo "1️⃣  Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker não está instalado!"
    exit 1
fi
print_success "Docker OK: $(docker --version | cut -d' ' -f3)"

# ========================================
# 2. Verificar Docker Compose
# ========================================
echo ""
echo "2️⃣  Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose não está instalado!"
    exit 1
fi
print_success "Docker Compose OK: $(docker-compose --version | cut -d' ' -f4)"

# ========================================
# 3. Criar volumes necessários
# ========================================
echo ""
echo "3️⃣  Criando volumes Docker..."

volumes=("letsencrypt" "nginx-logs" "grafana-data")

for vol in "${volumes[@]}"; do
    if docker volume ls | grep -q "^local.*\<$vol\>\$"; then
        print_info "Volume '$vol' já existe"
    else
        docker volume create $vol
        print_success "Volume '$vol' criado"
    fi
done

# ========================================
# 4. Verificar rede
# ========================================
echo ""
echo "4️⃣  Verificando rede 'network'..."
if docker network ls | grep -q "\<network\>"; then
    print_success "Rede 'network' existe"
else
    print_warning "Rede 'network' não existe, criando..."
    docker network create network
    print_success "Rede 'network' criada"
fi

# ========================================
# 5. Gerar DH Parameters (se não existir)
# ========================================
echo ""
echo "5️⃣  Verificando DH Parameters..."
if [ -f "./nginx/dhparam.pem" ]; then
    print_info "dhparam.pem já existe"
else
    print_warning "Gerando dhparam.pem (pode levar alguns minutos)..."
    openssl dhparam -out ./nginx/dhparam.pem 2048
    print_success "dhparam.pem criado"
fi

# ========================================
# 6. Verificar arquivos de configuração
# ========================================
echo ""
echo "6️⃣  Verificando arquivos de configuração..."

config_files=(
    "nginx/nginx.conf"
    "nginx/options.conf"
    "nginx/general.conf"
    "nginx/proxy.conf"
    "nginx/erpclass.conf"
)

all_files_ok=true
for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "Arquivo $file encontrado"
    else
        print_error "Arquivo $file NÃO encontrado!"
        all_files_ok=false
    fi
done

if [ "$all_files_ok" = false ]; then
    print_error "Alguns arquivos de configuração estão faltando!"
    exit 1
fi

# ========================================
# 7. Verificar DNS
# ========================================
echo ""
echo "7️⃣  Verificando DNS..."
domain="grafana.erpclass.com.br"

if host "$domain" &> /dev/null; then
    ip=$(host "$domain" | grep "has address" | head -1 | awk '{print $NF}')
    print_success "DNS '$domain' resolve para: $ip"

    # Verificar se é o IP deste servidor
    server_ip=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
    if [ "$ip" = "$server_ip" ]; then
        print_success "DNS aponta para este servidor!"
    else
        print_warning "DNS resolve para $ip, mas o IP deste servidor é $server_ip"
        print_info "Certifique-se de que o DNS está correto antes de continuar"
    fi
else
    print_warning "DNS '$domain' não resolve ainda"
    print_info "Configure o DNS antes de obter certificado SSL"
fi

# ========================================
# 8. Instalar Certbot (se necessário)
# ========================================
echo ""
echo "8️⃣  Verificando Certbot..."
if command -v certbot &> /dev/null; then
    print_success "Certbot já está instalado"
else
    print_warning "Certbot não está instalado"
    read -p "Deseja instalar o Certbot agora? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        sudo apt update
        sudo apt install -y certbot
        print_success "Certbot instalado"
    else
        print_info "Você pode instalar depois com: sudo apt install certbot"
    fi
fi

# ========================================
# 9. Perguntar sobre certificado SSL
# ========================================
echo ""
echo "9️⃣  Configuração de Certificado SSL"
print_info "Você tem duas opções:"
echo "  1) Já tenho certificado SSL do Let's Encrypt no host"
echo "  2) Ainda não tenho certificado (vou obter depois)"
echo ""
read -p "Escolha uma opção (1 ou 2): " ssl_option

if [ "$ssl_option" = "1" ]; then
    # Copiar certificados existentes para o volume
    print_info "Copiando certificados para o volume Docker..."

    if [ -d "/etc/letsencrypt" ]; then
        # Criar container temporário para copiar arquivos
        docker run --rm -v letsencrypt:/target -v /etc/letsencrypt:/source:ro alpine sh -c "cp -r /source/* /target/"
        print_success "Certificados copiados para o volume 'letsencrypt'"
    else
        print_warning "Diretório /etc/letsencrypt não encontrado"
        print_info "Obtenha o certificado primeiro com:"
        echo "  sudo certbot certonly --standalone -d grafana.erpclass.com.br"
    fi
elif [ "$ssl_option" = "2" ]; then
    print_info "Você precisará obter o certificado SSL antes de usar HTTPS"
    print_info "Passos:"
    echo "  1. Execute: sudo certbot certonly --standalone -d grafana.erpclass.com.br"
    echo "  2. Copie os certificados: docker run --rm -v letsencrypt:/target -v /etc/letsencrypt:/source:ro alpine sh -c 'cp -r /source/* /target/'"
    echo "  3. Inicie o Nginx: docker-compose -f loki.yml up -d"
fi

# ========================================
# 10. Iniciar serviços
# ========================================
echo ""
echo "🔟  Iniciar serviços"
read -p "Deseja iniciar o Nginx e Grafana agora? (s/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[SsYy]$ ]]; then
    echo ""
    print_info "Iniciando serviços..."

    # Verificar se já existem containers rodando
    if docker ps -a | grep -q "nginx"; then
        print_warning "Container nginx já existe, removendo..."
        docker-compose -f loki.yml down
    fi

    # Iniciar serviços
    docker-compose -f loki.yml up -d

    echo ""
    print_success "Serviços iniciados!"
    echo ""

    # Mostrar status
    echo "📊 Status dos containers:"
    docker-compose -f loki.yml ps

    echo ""
    echo "📋 Logs em tempo real:"
    echo "  docker-compose -f loki.yml logs -f"
    echo ""
    echo "🌐 URLs:"
    if [ "$ssl_option" = "1" ]; then
        echo "  https://grafana.erpclass.com.br (HTTPS)"
    else
        echo "  http://grafana.erpclass.com.br (HTTP - configure SSL para HTTPS)"
    fi

else
    print_info "Para iniciar manualmente:"
    echo "  docker-compose -f loki.yml up -d"
fi

# ========================================
# Resumo Final
# ========================================
echo ""
echo "=========================================="
print_success "Setup concluído!"
echo "=========================================="
echo ""
echo "📚 Próximos passos:"
echo ""

if [ "$ssl_option" != "1" ]; then
    echo "1️⃣  Obter certificado SSL:"
    echo "   sudo certbot certonly --standalone -d grafana.erpclass.com.br"
    echo ""
    echo "2️⃣  Copiar certificados para o volume:"
    echo "   docker run --rm -v letsencrypt:/target -v /etc/letsencrypt:/source:ro alpine sh -c 'cp -r /source/* /target/'"
    echo ""
    echo "3️⃣  Reiniciar Nginx:"
    echo "   docker-compose -f loki.yml restart nginx"
    echo ""
fi

echo "🔍 Comandos úteis:"
echo "  docker-compose -f loki.yml ps              # Ver status"
echo "  docker-compose -f loki.yml logs -f         # Ver logs"
echo "  docker-compose -f loki.yml restart nginx   # Reiniciar Nginx"
echo "  docker exec nginx nginx -t                  # Testar configuração"
echo "  docker exec nginx nginx -s reload           # Recarregar config"
echo ""
echo "✅ Tudo pronto!"
