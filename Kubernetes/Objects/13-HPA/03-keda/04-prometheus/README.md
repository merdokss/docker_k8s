# KEDA z Prometheus - Przykład skalowania na podstawie custom metrics

Ten przykład pokazuje jak używać KEDA do skalowania aplikacji na podstawie metryk Prometheus.

## Opis scenariusza

- Aplikacja eksportuje metryki do Prometheus
- KEDA używa Prometheus queries do pobierania metryk
- Skalowanie na podstawie rzeczywistych metryk biznesowych:
  - HTTP requests per second
  - Queue length
  - Error rate
  - Custom business metrics

## Zalety Prometheus Scaler

- **Elastyczność** - dowolne metryki Prometheus
- **Istniejący monitoring** - wykorzystuje obecną infrastrukturę
- **Complex queries** - używa PromQL dla zaawansowanych obliczeń
- **Business metrics** - skaluj na podstawie rzeczywistych potrzeb biznesowych

## Zawartość przykładu

1. `app-with-metrics.yaml` - Aplikacja eksportująca metryki
2. `servicemonitor.yaml` - ServiceMonitor dla Prometheus Operator
3. `scaledobject-http-requests.yaml` - Skalowanie na podstawie HTTP requests
4. `scaledobject-custom-metric.yaml` - Skalowanie na podstawie custom metryki
5. `scaledobject-multiple-queries.yaml` - Wiele query jednocześnie

## Wymagania

- Zainstalowana KEDA w klastrze
- Prometheus lub Prometheus Operator zainstalowany
- kubectl skonfigurowany

## Instalacja Prometheus (jeśli nie masz)

### Używając Prometheus Operator

```bash
# Dodaj Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Zainstaluj kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Sprawdź instalację
kubectl get pods -n monitoring
```

## Jak uruchomić przykład

### Krok 1: Wdróż aplikację z metrykami

```bash
kubectl apply -f app-with-metrics.yaml
```

Ta aplikacja:
- Eksportuje metryki na `/metrics`
- Symuluje HTTP traffic
- Eksportuje custom metryki biznesowe

### Krok 2: Skonfiguruj Prometheus scraping

```bash
# Jeśli używasz Prometheus Operator
kubectl apply -f servicemonitor.yaml

# Jeśli używasz vanilla Prometheus, dodaj do prometheus.yml:
# - job_name: 'my-app'
#   kubernetes_sd_configs:
#   - role: pod
#   relabel_configs:
#   - source_labels: [__meta_kubernetes_pod_label_app]
#     action: keep
#     regex: my-app-with-metrics
```

### Krok 3: Zweryfikuj metryki w Prometheus

```bash
# Port-forward do Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Otwórz http://localhost:9090
# Sprawdź query: rate(http_requests_total[1m])
```

### Krok 4: Wdróż ScaledObject

```bash
# Przykład 1: HTTP requests
kubectl apply -f scaledobject-http-requests.yaml

# LUB Przykład 2: Custom metric
# kubectl apply -f scaledobject-custom-metric.yaml

# LUB Przykład 3: Multiple queries
# kubectl apply -f scaledobject-multiple-queries.yaml
```

### Krok 5: Generuj obciążenie

```bash
# Port-forward do aplikacji
kubectl port-forward svc/my-app-service 8080:80

# W nowym terminalu - generuj traffic
while true; do
  curl http://localhost:8080
  sleep 0.1
done

# Lub użyj Apache Bench
ab -n 100000 -c 100 http://localhost:8080/
```

### Krok 6: Obserwuj skalowanie

```bash
# Terminal 1: Obserwuj pody
kubectl get pods -l app=my-app-with-metrics -w

# Terminal 2: Obserwuj metryki
kubectl get scaledobject -w

# Terminal 3: Sprawdź HPA
kubectl get hpa -w

# Terminal 4: Sprawdź wartość metryki
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/prometheus-scaledobject" | jq .
```

## Przykładowe PromQL queries

### 1. HTTP Requests Per Second

```promql
rate(http_requests_total{app="my-app"}[1m])
```

Skaluj gdy > 100 req/s per pod

### 2. Error Rate

```promql
rate(http_requests_total{app="my-app",status=~"5.."}[5m]) / rate(http_requests_total{app="my-app"}[5m])
```

Skaluj gdy error rate > 0.05 (5%)

### 3. Queue Length

```promql
sum(queue_length{app="my-app"})
```

Skaluj gdy queue > 50

### 4. Response Time (p95)

```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{app="my-app"}[5m]))
```

Skaluj gdy p95 latency > 0.5s

### 5. Active Connections

```promql
sum(active_connections{app="my-app"})
```

Skaluj gdy connections > 100

### 6. Custom Business Metric

```promql
sum(rate(orders_processed_total{app="my-app"}[5m]))
```

Skaluj gdy orders/s > 10

## Konfiguracja Prometheus Scaler

### Podstawowa konfiguracja

```yaml
triggers:
- type: prometheus
  metadata:
    serverAddress: http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090
    metricName: http_requests_per_second
    query: |
      sum(rate(http_requests_total{app="my-app"}[1m]))
    threshold: "100"
```

### Parametry

- `serverAddress` - URL do Prometheus API
- `query` - PromQL query
- `threshold` - wartość progowa
- `metricName` - nazwa metryki (do HPA)
- `namespace` - namespace dla query (opcjonalne)
- `ignoreNullValues` - ignoruj null values (default: true)
- `unsafeSsl` - skip SSL verification (default: false)

### Authentication

```yaml
# Basic Auth
apiVersion: v1
kind: Secret
metadata:
  name: prometheus-auth
type: Opaque
stringData:
  username: admin
  password: secret
---
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: prometheus-trigger-auth
spec:
  secretTargetRef:
  - parameter: username
    name: prometheus-auth
    key: username
  - parameter: password
    name: prometheus-auth
    key: password
---
# Bearer Token
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: prometheus-trigger-auth
spec:
  secretTargetRef:
  - parameter: bearerToken
    name: prometheus-auth
    key: token
```

## Przykłady zaawansowane

### Skalowanie na podstawie wielu metryk

```yaml
triggers:
# HTTP requests per second
- type: prometheus
  metadata:
    serverAddress: http://prometheus.monitoring.svc:9090
    query: sum(rate(http_requests_total[1m]))
    threshold: "100"

# CPU usage
- type: prometheus
  metadata:
    serverAddress: http://prometheus.monitoring.svc:9090
    query: avg(rate(container_cpu_usage_seconds_total{pod=~"my-app.*"}[1m]))
    threshold: "0.8"

# Memory pressure
- type: prometheus
  metadata:
    serverAddress: http://prometheus.monitoring.svc:9090
    query: avg(container_memory_working_set_bytes{pod=~"my-app.*"}) / avg(container_spec_memory_limit_bytes{pod=~"my-app.*"})
    threshold: "0.75"
```

### Agregacje per pod

```yaml
triggers:
- type: prometheus
  metadata:
    serverAddress: http://prometheus.monitoring.svc:9090
    query: |
      sum(rate(http_requests_total{app="my-app"}[1m])) / 
      count(up{app="my-app"})
    threshold: "50"    # 50 req/s per pod
```

### Time-based queries

```yaml
triggers:
- type: prometheus
  metadata:
    serverAddress: http://prometheus.monitoring.svc:9090
    # Skaluj jeśli średnia z ostatnich 5 minut > threshold
    query: |
      avg_over_time(
        sum(rate(http_requests_total{app="my-app"}[1m]))[5m:]
      )
    threshold: "100"
```

## Debugowanie

### Sprawdź czy query działa

```bash
# Port-forward do Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Otwórz http://localhost:9090
# Wklej query i sprawdź wynik
```

### Sprawdź metryki KEDA

```bash
# Logi KEDA operator
kubectl logs -n keda -l app=keda-operator | grep prometheus

# External metrics
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1" | jq .

# Konkretna metryka
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/<metricName>" | jq .
```

### Test connectivity

```bash
# Z poda KEDA
kubectl exec -n keda -it $(kubectl get pod -n keda -l app=keda-operator -o jsonpath='{.items[0].metadata.name}') -- sh

# W kontenerze:
wget -qO- http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090/api/v1/query?query=up
```

## Best Practices

### 1. Używaj rate() dla counters

```promql
# ❌ Źle - counter zawsze rośnie
sum(http_requests_total)

# ✅ Dobrze - requests per second
sum(rate(http_requests_total[1m]))
```

### 2. Odpowiedni time range

```promql
# Zbyt krótki [10s] - zbyt wrażliwe, flapping
# Zbyt długi [10m] - wolna reakcja
# Optymalnie: [1m] - [5m]
rate(http_requests_total[1m])
```

### 3. Threshold per pod, nie total

```yaml
# ❌ Źle - total requests (nie skaluje proporcjonalnie)
query: sum(rate(http_requests_total[1m]))
threshold: "1000"

# ✅ Dobrze - per pod (skaluje proporcjonalnie)
query: sum(rate(http_requests_total[1m])) / count(up{app="my-app"})
threshold: "100"
```

### 4. Używaj sum/avg dla wielu podów

```promql
# Suma ze wszystkich podów
sum(rate(http_requests_total{app="my-app"}[1m]))

# Średnia ze wszystkich podów
avg(rate(http_requests_total{app="my-app"}[1m]))
```

### 5. Ignoruj null values

```yaml
metadata:
  ignoreNullValues: "true"  # Nie skaluj do 0 gdy brak metryk
```

## Monitoring i Alerting

### Grafana Dashboard

Przykładowe panele do monitorowania:

1. **Current replicas** vs **Desired replicas**
2. **Metric value** (z threshold linią)
3. **Scale up/down events**
4. **HPA status**

### Prometheus Alerts

```yaml
groups:
- name: keda
  rules:
  - alert: KEDAScalerError
    expr: keda_scaler_errors_total > 0
    for: 5m
    annotations:
      summary: "KEDA scaler errors"
      
  - alert: KEDAMaxReplicasReached
    expr: keda_scaled_object_replicas >= keda_scaled_object_max_replicas
    for: 10m
    annotations:
      summary: "Max replicas reached - consider increasing"
```

## Troubleshooting

### Problem: KEDA nie może połączyć się z Prometheus

```bash
# Sprawdź czy Prometheus jest dostępny
kubectl get svc -n monitoring | grep prometheus

# Test connectivity
kubectl run test --rm -it --image=curlimages/curl -- \
  curl http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090/api/v1/query?query=up
```

### Problem: Query nie zwraca wartości

```bash
# Sprawdź query w Prometheus UI
# Sprawdź czy labele są poprawne
# Sprawdź czy aplikacja eksportuje metryki

# Sprawdź ServiceMonitor (jeśli używasz Prometheus Operator)
kubectl get servicemonitor
kubectl describe servicemonitor my-app-monitor
```

### Problem: Metryka null

```yaml
# Dodaj ignoreNullValues
metadata:
  ignoreNullValues: "true"

# Lub użyj or 0 w query
query: |
  sum(rate(http_requests_total[1m])) or vector(0)
```

## Cleanup

```bash
kubectl delete -f .
```

## Dalsze zasoby

- [KEDA Prometheus Scaler Docs](https://keda.sh/docs/2.12/scalers/prometheus/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Dashboards for KEDA](https://github.com/kedacore/keda/tree/main/config/grafana)

