#!/bin/bash

# Script para diagnosticar e corrigir problemas do Grafana com proxy reverso

echo "=========================================="
echo "   Diagnóstico: Grafana + Nginx Proxy"
echo "=========================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar se os containers estão rodando
echo "1. Verificando containers..."
if docker ps | grep -q "grafana"; then
    echo -e "${GREEN}✓${NC} Grafana está rodando"
else
    echo -e "${RED}✗${NC} Grafana NÃO está rodando"
    echo "   Execute: docker-compose -f nginx.yml up -d grafana"
fi

if docker ps | grep -q "nginx"; then
    echo -e "${GREEN}✓${NC} Nginx está rodando"
else
    echo -e "${RED}✗${NC} Nginx NÃO está rodando"
    echo "   Execute: docker-compose -f nginx.yml up -d nginx"
fi

echo ""

# 2. Verificar conectividade entre containers
echo "2. Testando conectividade Nginx -> Grafana..."
if docker exec nginx ping -c 1 grafana &> /dev/null; then
    echo -e "${GREEN}✓${NC} Nginx consegue alcançar o container Grafana"
else
    echo -e "${RED}✗${NC} Nginx NÃO consegue alcançar o container Grafana"
    echo "   Verifique se ambos estão na mesma rede: docker network inspect network"
fi

echo ""

# 3. Verificar se Grafana está respondendo
echo "3. Testando se Grafana está respondendo..."
if docker exec grafana wget -q -O /dev/null http://localhost:3000/api/health; then
    echo -e "${GREEN}✓${NC} Grafana está respondendo no container"
else
    echo -e "${RED}✗${NC} Grafana NÃO está respondendo"
    echo "   Veja os logs: docker logs grafana"
fi

echo ""

# 4. Testar acesso do Nginx ao Grafana
echo "4. Testando proxy Nginx -> Grafana..."
if docker exec nginx wget -q -O /dev/null http://grafana:3000/api/health; then
    echo -e "${GREEN}✓${NC} Nginx consegue acessar Grafana via rede Docker"
else
    echo -e "${RED}✗${NC} Nginx NÃO consegue acessar Grafana"
    echo "   Problema de rede ou configuração"
fi

echo ""

# 5. Verificar configuração do Nginx
echo "5. Verificando configuração do Nginx..."
if docker exec nginx nginx -t &> /dev/null; then
    echo -e "${GREEN}✓${NC} Configuração do Nginx está válida"
else
    echo -e "${RED}✗${NC} Erro na configuração do Nginx"
    docker exec nginx nginx -t
fi

echo ""

# 6. Verificar variáveis de ambiente do Grafana
echo "6. Verificando variáveis de ambiente do Grafana..."
echo ""
docker exec grafana printenv | grep "^GF_" | while read line; do
    echo "   $line"
done

echo ""

# 7. Verificar logs recentes do Grafana
echo "7. Últimas linhas do log do Grafana:"
echo "---"
docker logs grafana --tail 20 2>&1 | grep -i "error\|warn\|listen"
echo "---"

echo ""

# 8. Verificar logs recentes do Nginx
echo "8. Últimas linhas do log de erro do Nginx:"
echo "---"docker logs nginx --tail 20 2>&1 | grep -i "error\|warn"
echo "---"

echo ""

# 9. Testar porta 3000 diretamente
echo "9. Testando acesso direto ao Grafana (localhost:3000)..."
if curl -s http://localhost:3000/api/health | grep -q "ok"; then
    echo -e "${GREEN}✓${NC} Grafana acessível diretamente em localhost:3000"
else
    echo -e "${YELLOW}⚠${NC} Grafana não acessível via localhost:3000 (pode ser normal se exposto só internamente)"
fi

echo ""

# 10. Sugestões de correção
echo "=========================================="
echo "   AÇÕES CORRETIVAS"
echo "=========================================="
echo ""

echo "Se o Grafana não está carregando os assets, execute:"
echo ""
echo "1. Recriar o container do Grafana:"
echo "   ${YELLOW}docker-compose -f nginx.yml up -d --force-recreate grafana${NC}"
echo ""
echo "2. Recarregar a configuração do Nginx:"
echo "   ${YELLOW}docker exec nginx nginx -s reload${NC}"
echo ""
echo "3. Reiniciar ambos os containers:"
echo "   ${YELLOW}docker-compose -f nginx.yml restart grafana nginx${NC}"
echo ""
echo "4. Ver logs em tempo real:"
echo "   ${YELLOW}docker logs grafana -f${NC}"
echo "   ${YELLOW}docker logs nginx -f${NC}"
echo ""
echo "5. Limpar cache do navegador e testar novamente"
echo ""
echo "6. Se ainda não funcionar, verificar se o certificado SSL está correto:"
echo "   ${YELLOW}docker run --rm -v letsencrypt:/certs alpine ls -la /certs/live/${NC}"
echo ""

# Opção para aplicar correções automaticamente
echo ""
read -p "Deseja aplicar as correções automaticamente? (s/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "Aplicando correções..."
    echo ""

    echo "→ Recriando container do Grafana..."
    docker-compose -f nginx.yml up -d --force-recreate grafana

    echo "→ Aguardando Grafana iniciar (15 segundos)..."
    sleep 15

    echo "→ Recarregando configuração do Nginx..."
    docker exec nginx nginx -s reload

    echo ""
    echo -e "${GREEN}✓${NC} Correções aplicadas!"
    echo ""
    echo "Aguarde 10 segundos e tente acessar novamente:"
    echo "   https://grafana.erpclass.com.br"
    echo ""
    echo "Se ainda não funcionar:"
    echo "1. Limpe o cache do navegador (Ctrl+F5)"
    echo "2. Tente em uma aba anônima"
    echo "3. Verifique os logs: docker logs grafana -f"
fi

echo ""
echo "=========================================="
echo "   Diagnóstico concluído!"
echo "=========================================="
