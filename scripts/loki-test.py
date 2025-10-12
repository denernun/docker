#!/usr/bin/env python3
"""
Exemplo prático de envio de logs para o Loki
Uso: python loki-test.py
"""

import requests
import time
import json
from datetime import datetime

# Configuração
LOKI_URL = "http://localhost:3100/loki/api/v1/push"

class LokiLogger:
    """Cliente simples para enviar logs ao Loki"""

    def __init__(self, loki_url=LOKI_URL, job="test-app"):
        self.url = loki_url
        self.job = job

    def log(self, message, level="info", **extra_labels):
        """Envia um log para o Loki"""
        # Timestamp em nanosegundos
        timestamp_ns = str(int(time.time() * 1e9))

        # Preparar labels
        labels = {
            "job": self.job,
            "level": level,
            **extra_labels
        }

        # Preparar payload
        payload = {
            "streams": [{
                "stream": labels,
                "values": [[timestamp_ns, message]]
            }]
        }

        # Enviar request
        try:
            response = requests.post(
                self.url,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=5
            )

            if response.status_code == 204:
                print(f"✅ Log enviado: [{level}] {message[:50]}...")
                return True
            else:
                print(f"❌ Erro ao enviar log: Status {response.status_code}")
                print(f"   Response: {response.text}")
                return False

        except requests.exceptions.ConnectionError:
            print(f"❌ Erro: Não foi possível conectar ao Loki em {self.url}")
            print(f"   Verifique se o Loki está rodando: docker ps | grep loki")
            return False
        except Exception as e:
            print(f"❌ Erro inesperado: {e}")
            return False

    def send_batch(self, messages):
        """Envia múltiplos logs de uma vez"""
        timestamp_ns = str(int(time.time() * 1e9))

        values = []
        for msg in messages:
            level = msg.get('level', 'info')
            text = msg.get('message', '')
            # Incrementar timestamp para cada mensagem
            ts = str(int(timestamp_ns) + len(values) * 1000000)
            values.append([ts, text])

        labels = {
            "job": self.job,
            "batch": "true"
        }

        payload = {
            "streams": [{
                "stream": labels,
                "values": values
            }]
        }

        try:
            response = requests.post(
                self.url,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=5
            )

            if response.status_code == 204:
                print(f"✅ Batch de {len(messages)} logs enviado com sucesso")
                return True
            else:
                print(f"❌ Erro ao enviar batch: Status {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Erro ao enviar batch: {e}")
            return False


def main():
    """Função principal - testa o envio de logs"""
    print("=" * 60)
    print("🚀 Teste de Envio de Logs para o Loki")
    print("=" * 60)
    print()

    # Criar logger
    logger = LokiLogger(job="python-test-app")

    # Verificar conectividade
    print("📡 Verificando conexão com o Loki...")
    try:
        response = requests.get("http://localhost:3100/ready", timeout=5)
        if response.status_code == 200:
            print("✅ Loki está acessível e pronto!")
        else:
            print(f"⚠️  Loki respondeu com status: {response.status_code}")
    except:
        print("❌ Não foi possível conectar ao Loki")
        print("   Execute: docker ps | grep loki")
        return

    print()
    print("-" * 60)
    print("📤 Enviando logs de teste...")
    print("-" * 60)
    print()

    # Teste 1: Log simples
    logger.log("Aplicação iniciada com sucesso", level="info")
    time.sleep(0.5)

    # Teste 2: Log com labels extras
    logger.log(
        "Usuário fez login no sistema",
        level="info",
        user="joao@example.com",
        action="login"
    )
    time.sleep(0.5)

    # Teste 3: Log de warning
    logger.log(
        "Tentativa de acesso a recurso protegido",
        level="warning",
        resource="/admin",
        ip="192.168.1.100"
    )
    time.sleep(0.5)

    # Teste 4: Log de erro
    logger.log(
        "Falha ao conectar ao banco de dados",
        level="error",
        db="postgres",
        error_code="CONN_TIMEOUT"
    )
    time.sleep(0.5)

    # Teste 5: Log estruturado (JSON)
    log_data = {
        "event": "venda_processada",
        "venda_id": 12345,
        "valor": 150.00,
        "cliente_id": 789
    }
    logger.log(
        json.dumps(log_data),
        level="info",
        event_type="transaction"
    )
    time.sleep(0.5)

    # Teste 6: Batch de logs
    print()
    print("📦 Enviando batch de logs...")
    batch_logs = [
        {"level": "info", "message": "Batch log 1: Sistema iniciado"},
        {"level": "info", "message": "Batch log 2: Configurações carregadas"},
        {"level": "info", "message": "Batch log 3: Conectado ao banco"},
        {"level": "info", "message": "Batch log 4: Cache inicializado"},
        {"level": "info", "message": "Batch log 5: API pronta para receber requisições"}
    ]
    logger.send_batch(batch_logs)

    print()
    print("=" * 60)
    print("✅ Teste concluído!")
    print("=" * 60)
    print()
    print("📊 Visualizar logs no Grafana:")
    print("   1. Acesse: http://localhost:3000")
    print("   2. Vá em 'Explore' (ícone de bússola)")
    print("   3. Selecione 'Loki' como data source")
    print("   4. Use a query: {job=\"python-test-app\"}")
    print()
    print("🔍 Queries úteis:")
    print("   - Ver todos: {job=\"python-test-app\"}")
    print("   - Só erros: {job=\"python-test-app\", level=\"error\"}")
    print("   - Buscar texto: {job=\"python-test-app\"} |= \"banco\"")
    print()


if __name__ == "__main__":
    # Verificar se requests está instalado
    try:
        import requests
    except ImportError:
        print("❌ Módulo 'requests' não encontrado")
        print("   Instale com: pip install requests")
        exit(1)

    main()
