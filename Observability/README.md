# Stack Observability - Prometheus, Grafana, Tempo, Loki

Kompletny stack observability dla Kubernetes zawierający:
- **Prometheus** - zbieranie metryk
- **Grafana** - wizualizacja metryk, logów i traces
- **Grafana Tempo** - zbieranie i przechowywanie traces (OTLP)
- **Grafana Loki** - zbieranie i przechowywanie logów
- **Promtail** - agent zbierający logi z podów Kubernetes

## Wymagania

- Kubernetes cluster (1.19+)
- Helm 3.x
- kubectl skonfigurowany do pracy z klastrem
- Min. 5 węzłów (lub dostosuj `replication_factor` i wyłącz cache)

## Instalacja

### Automatyczna

```bash
cd Observability
./install.sh
```

### Ręczna krok po kroku

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

# 1. kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --values prometheus-stack-values.yaml --wait --timeout 10m

# 2. Tempo (distributed tracing)
helm upgrade --install tempo grafana/tempo \
  --namespace monitoring --values tempo-values.yaml --wait --timeout 10m

# 3. Loki (logi)
helm upgrade --install loki grafana/loki \
  --namespace monitoring --values loki-values.yaml --wait --timeout 10m

# 4. Promtail (agent logów - osobny chart, NIE subchart Loki)
helm upgrade --install promtail grafana/promtail \
  --namespace monitoring --values promtail-values.yaml --wait --timeout 5m

# 5. Datasources Grafana (Loki + Tempo - Prometheus jest już skonfigurowany przez chart)
kubectl apply -f grafana-datasources.yaml
```

## Ważne uwagi do konfiguracji

### Loki - małe klastry (< 3 węzłów)

Domyślny `replication_factor: 3` wymaga 3 instancji. Na małych klastrach ustaw w `loki-values.yaml`:

```yaml
loki:
  commonConfig:
    replication_factor: 1
```

Bez tego Loki zwraca `at least 2 live replicas required` i odrzuca wszystkie zapisy.

Wyłącz też niepotrzebne komponenty pochłaniające zasoby:

```yaml
lokiCanary:
  enabled: false
test:
  enabled: false
chunksCache:
  enabled: false
```

### Loki - retencja

Przy włączonej retencji wymagane jest `delete_request_store`:

```yaml
loki:
  compactor:
    retention_enabled: true
    delete_request_store: filesystem
```

### Tempo - metricsGenerator

`metricsGenerator` musi być zagnieżdżony pod `tempo:`, nie jako klucz główny:

```yaml
tempo:
  metricsGenerator:
    enabled: true
    remoteWriteUrl: "http://prometheus-stack-kube-prom-prometheus.monitoring.svc.cluster.local:9090/api/v1/write"
```

### Prometheus - remote write receiver

Wymagany dla metrics generator Tempo (service graphs, span metrics). Włącz w `prometheus-stack-values.yaml`:

```yaml
prometheus:
  prometheusSpec:
    enableRemoteWriteReceiver: true
```

### Grafana datasources

`grafana-datasources.yaml` zawiera tylko Loki i Tempo. Prometheus jest już konfigurowany automatycznie przez kube-prometheus-stack — duplikowanie go spowoduje błąd `Only one datasource per organization can be marked as default`.

## Dostęp do Grafana

```bash
# Adres LoadBalancer
kubectl get svc -n monitoring prometheus-stack-grafana

# Port-forward (alternatywa)
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```

- **Username**: `admin`
- **Password**: `admin123`

## Mikroserwisy demo (distributed tracing)

Gotowe mikroserwisy z OpenTelemetry w katalogu `microservices/`:

```bash
kubectl apply -f microservices/deployment.yaml
```

Łańcuch wywołań: `frontend-service → service-a → service-b → service-c`

### Generowanie ruchu

```bash
kubectl run load-generator --image=curlimages/curl --restart=Never -- \
  sh -c 'i=0; while true; do
    i=$((i+1))
    curl -s "http://frontend-service.default.svc.cluster.local:8080/api/order?order_id=test-$i" > /dev/null
    curl -s "http://frontend-service.default.svc.cluster.local:8080/api/user?user_id=user-$i" > /dev/null
    sleep 1
  done'

# Zatrzymaj
kubectl delete pod load-generator
```

### NetworkPolicy

Jeśli namespace `default` ma `isolate-namespace` NetworkPolicy, aplikacje nie mogą wysyłać traces do Tempo w `monitoring`. Dodaj regułę egress:

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-monitoring
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
EOF
```

## Konfiguracja komponentów

| Komponent | Port | Protokół |
|-----------|------|----------|
| Prometheus | 9090 | HTTP |
| Grafana | 80 (LB) | HTTP |
| Tempo | 3200 | HTTP (API) |
| Tempo | 4317 | gRPC (OTLP) |
| Tempo | 4318 | HTTP (OTLP) |
| Loki | 3100 | HTTP |
| Loki Gateway | 80 | HTTP (nginx) |

## Przydatne komendy

```bash
# Status podów
kubectl get pods -n monitoring

# Sprawdź logi Loki
kubectl logs -n monitoring loki-0

# Sprawdź logi Tempo
kubectl logs -n monitoring tempo-0

# Sprawdź logi Promtail
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=20

# Sprawdź czy Loki odbiera logi
kubectl exec -n monitoring deployment/prometheus-stack-grafana -c grafana -- \
  curl -s "http://loki:3100/loki/api/v1/labels"

# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
```

## Usunięcie

```bash
kubectl delete pod load-generator --ignore-not-found
kubectl delete -f microservices/deployment.yaml
helm uninstall promtail loki tempo prometheus-stack -n monitoring
kubectl delete namespace monitoring
```

## Ćwiczenia

1. **Metryki**: Sprawdź metryki klastra w Prometheus (`kubectl port-forward ... 9090:9090`)
2. **Logi**: Przeszukaj logi w Grafana Explore → Loki → `{namespace="default"}`
3. **Traces**: Prześledź request przez mikroserwisy w Grafana Explore → Tempo
4. **Service Map**: Sprawdź mapę serwisów w Grafana → Tempo → Service Graph
5. **Korelacja**: Kliknij w trace i przejdź do powiązanych logów (TraceID w Loki)
6. **Alerty**: Skonfiguruj alert w Prometheus dla wysokiego czasu odpowiedzi
