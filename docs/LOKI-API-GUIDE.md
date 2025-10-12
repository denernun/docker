# 📤 Enviando Dados para o Loki via API

## 🔓 Autenticação

### **Resposta Rápida: NÃO precisa de autenticação!**

Na configuração atual do seu Loki:

```yaml
auth_enabled: false
```

✅ **Não é necessária autenticação**
✅ **Não precisa de tokens ou headers especiais**
✅ **Apenas envie o POST diretamente**

---

## 📡 Endpoint da API

### **URL do Loki:**

```
POST http://localhost:3100/loki/api/v1/push
```

Se estiver de outro container na mesma rede:

```
POST http://loki:3100/loki/api/v1/push
```

---

## 📝 Formato do Request

### **Headers Obrigatórios:**

```http
Content-Type: application/json
```

### **Body (JSON):**

```json
{
  "streams": [
    {
      "stream": {
        "label1": "value1",
        "label2": "value2"
      },
      "values": [["<timestamp_nanoseconds>", "<log_message>"]]
    }
  ]
}
```

---

## 🚀 Exemplos Práticos

### **Exemplo 1: Envio Simples (cURL)**

```bash
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [
      {
        "stream": {
          "job": "my-app",
          "level": "info"
        },
        "values": [
          ["'$(date +%s)000000000'", "Aplicação iniciada com sucesso"]
        ]
      }
    ]
  }'
```

### **Exemplo 2: Múltiplas Linhas de Log**

```bash
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [
      {
        "stream": {
          "job": "api-vendas",
          "env": "production",
          "server": "web-01"
        },
        "values": [
          ["'$(date +%s)000000000'", "Usuario login: joao@email.com"],
          ["'$(($(date +%s)+1))000000000'", "Venda processada: ID=12345"],
          ["'$(($(date +%s)+2))000000000'", "Email enviado com sucesso"]
        ]
      }
    ]
  }'
```

### **Exemplo 3: Log de Erro**

```bash
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [
      {
        "stream": {
          "job": "api-vendas",
          "level": "error",
          "service": "payment"
        },
        "values": [
          ["'$(date +%s)000000000'", "{\"error\": \"Payment failed\", \"code\": 500, \"user_id\": 123}"]
        ]
      }
    ]
  }'
```

---

## 💻 Exemplos em Diferentes Linguagens

### **Python**

```python
import requests
import time

url = "http://localhost:3100/loki/api/v1/push"

# Timestamp em nanosegundos
timestamp_ns = str(int(time.time() * 1e9))

payload = {
    "streams": [
        {
            "stream": {
                "job": "python-app",
                "level": "info",
                "host": "server-01"
            },
            "values": [
                [timestamp_ns, "Aplicação Python iniciada"]
            ]
        }
    ]
}

headers = {
    "Content-Type": "application/json"
}

response = requests.post(url, json=payload, headers=headers)
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
```

### **Python - Classe Helper**

```python
import requests
import time
import json

class LokiLogger:
    def __init__(self, loki_url="http://localhost:3100", job="my-app"):
        self.url = f"{loki_url}/loki/api/v1/push"
        self.job = job

    def log(self, message, level="info", **extra_labels):
        timestamp_ns = str(int(time.time() * 1e9))

        labels = {
            "job": self.job,
            "level": level,
            **extra_labels
        }

        payload = {
            "streams": [{
                "stream": labels,
                "values": [[timestamp_ns, message]]
            }]
        }

        try:
            response = requests.post(
                self.url,
                json=payload,
                headers={"Content-Type": "application/json"}
            )
            return response.status_code == 204
        except Exception as e:
            print(f"Erro ao enviar log: {e}")
            return False

# Uso
logger = LokiLogger(job="api-vendas")
logger.log("Usuario fez login", level="info", user="joao@email.com")
logger.log("Erro ao processar pagamento", level="error", code=500)
```

### **Node.js / JavaScript**

```javascript
const axios = require('axios');

const lokiUrl = 'http://localhost:3100/loki/api/v1/push';

async function sendLog(message, labels = {}) {
  const timestamp = (Date.now() * 1000000).toString();

  const payload = {
    streams: [
      {
        stream: {
          job: 'nodejs-app',
          level: 'info',
          ...labels,
        },
        values: [[timestamp, message]],
      },
    ],
  };

  try {
    const response = await axios.post(lokiUrl, payload, {
      headers: {
        'Content-Type': 'application/json',
      },
    });
    console.log('Log enviado com sucesso!', response.status);
  } catch (error) {
    console.error('Erro ao enviar log:', error.message);
  }
}

// Uso
sendLog('Aplicação Node.js iniciada', { env: 'production' });
sendLog('Erro no banco de dados', { level: 'error', db: 'postgres' });
```

### **PHP**

```php
<?php

function sendToLoki($message, $labels = []) {
    $url = 'http://localhost:3100/loki/api/v1/push';

    // Timestamp em nanosegundos
    $timestamp = (string)(microtime(true) * 1e9);

    $defaultLabels = [
        'job' => 'php-app',
        'level' => 'info'
    ];

    $allLabels = array_merge($defaultLabels, $labels);

    $payload = [
        'streams' => [
            [
                'stream' => $allLabels,
                'values' => [
                    [$timestamp, $message]
                ]
            ]
        ]
    ];

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return $httpCode === 204;
}

// Uso
sendToLoki('Aplicação PHP iniciada', ['env' => 'production']);
sendToLoki('Erro ao conectar ao banco', ['level' => 'error', 'db' => 'mysql']);
?>
```

### **Go**

```go
package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
    "strconv"
    "time"
)

type Stream struct {
    Stream map[string]string `json:"stream"`
    Values [][]string        `json:"values"`
}

type Payload struct {
    Streams []Stream `json:"streams"`
}

func sendToLoki(message string, labels map[string]string) error {
    url := "http://localhost:3100/loki/api/v1/push"

    // Timestamp em nanosegundos
    timestamp := strconv.FormatInt(time.Now().UnixNano(), 10)

    if labels == nil {
        labels = make(map[string]string)
    }
    labels["job"] = "go-app"

    payload := Payload{
        Streams: []Stream{
            {
                Stream: labels,
                Values: [][]string{{timestamp, message}},
            },
        },
    }

    jsonData, err := json.Marshal(payload)
    if err != nil {
        return err
    }

    resp, err := http.Post(url, "application/json", bytes.NewBuffer(jsonData))
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    if resp.StatusCode != 204 {
        return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
    }

    return nil
}

func main() {
    labels := map[string]string{
        "level": "info",
        "env":   "production",
    }

    err := sendToLoki("Aplicação Go iniciada", labels)
    if err != nil {
        fmt.Println("Erro:", err)
    } else {
        fmt.Println("Log enviado com sucesso!")
    }
}
```

### **C# / .NET**

```csharp
using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

public class LokiClient
{
    private readonly string _lokiUrl;
    private readonly HttpClient _httpClient;

    public LokiClient(string lokiUrl = "http://localhost:3100")
    {
        _lokiUrl = $"{lokiUrl}/loki/api/v1/push";
        _httpClient = new HttpClient();
    }

    public async Task<bool> SendLogAsync(string message, string level = "info",
        Dictionary<string, string> extraLabels = null)
    {
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000000;

        var labels = new Dictionary<string, string>
        {
            { "job", "dotnet-app" },
            { "level", level }
        };

        if (extraLabels != null)
        {
            foreach (var label in extraLabels)
            {
                labels[label.Key] = label.Value;
            }
        }

        var payload = new
        {
            streams = new[]
            {
                new
                {
                    stream = labels,
                    values = new[] { new[] { timestamp.ToString(), message } }
                }
            }
        };

        var json = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        try
        {
            var response = await _httpClient.PostAsync(_lokiUrl, content);
            return response.StatusCode == System.Net.HttpStatusCode.NoContent;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Erro ao enviar log: {ex.Message}");
            return false;
        }
    }
}

// Uso
var loki = new LokiClient();
await loki.SendLogAsync("Aplicação .NET iniciada", "info");
await loki.SendLogAsync("Erro ao processar", "error",
    new Dictionary<string, string> { { "module", "payment" } });
```

---

## 🏷️ Boas Práticas para Labels

### **Labels Recomendados:**

```json
{
  "job": "nome-da-aplicacao",
  "level": "info|warn|error|debug",
  "env": "dev|staging|production",
  "host": "nome-do-servidor",
  "service": "nome-do-servico",
  "version": "v1.2.3"
}
```

### **⚠️ Evite:**

- ❌ Muitos labels diferentes (alta cardinalidade)
- ❌ Labels com valores muito variáveis (IDs, timestamps)
- ❌ Labels com valores únicos

### **✅ Prefira:**

- ✅ Labels fixos e predefinidos
- ✅ Categorias e classificações
- ✅ Informações estruturais

---

## 📊 Verificar Logs no Grafana

Depois de enviar os logs, visualize no Grafana:

1. Acesse: http://localhost:3000
2. Vá em **Explore** (ícone de bússola no menu lateral)
3. Selecione **Loki** como data source
4. Use queries LogQL:

```logql
# Ver todos os logs do seu job
{job="my-app"}

# Filtrar por nível
{job="my-app", level="error"}

# Buscar por texto
{job="my-app"} |= "erro"

# Ver logs das últimas 5 minutos
{job="my-app"} [5m]
```

---

## 🔒 Habilitar Autenticação (Opcional)

Se você quiser adicionar autenticação no futuro:

### **1. Alterar loki-config.yml:**

```yaml
auth_enabled: true

server:
  http_listen_port: 3100

# Adicionar configuração de multi-tenancy
limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
```

### **2. Usar Header de Tenant:**

```bash
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -H "X-Scope-OrgID: tenant1" \
  -d '{ ... }'
```

---

## ✅ Resposta da API

### **Sucesso:**

- **Status Code**: `204 No Content`
- **Body**: Vazio

### **Erro:**

- **Status Code**: `400 Bad Request` (formato inválido)
- **Status Code**: `500 Internal Server Error` (erro no servidor)
- **Body**: JSON com detalhes do erro

---

## 🎯 Resumo

| Pergunta                  | Resposta                                      |
| ------------------------- | --------------------------------------------- |
| **Precisa autenticação?** | ❌ Não (auth_enabled: false)                  |
| **Endpoint?**             | `POST http://localhost:3100/loki/api/v1/push` |
| **Headers?**              | `Content-Type: application/json`              |
| **Formato?**              | JSON com streams, labels e values             |
| **Timestamp?**            | Nanosegundos desde epoch                      |
| **Status sucesso?**       | 204 No Content                                |

---

## 📚 Recursos Adicionais

- **Documentação Loki API**: https://grafana.com/docs/loki/latest/api/
- **LogQL**: https://grafana.com/docs/loki/latest/logql/
- **Best Practices**: https://grafana.com/docs/loki/latest/best-practices/

---

**🚀 Comece a enviar seus logs agora mesmo! Não precisa de autenticação, apenas faça o POST!**
