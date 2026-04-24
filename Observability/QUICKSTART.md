# Szybki Start - Stack Observability

## Instalacja

```bash
cd Observability
./install.sh
```

Skrypt instaluje: Prometheus + Grafana, Tempo, Loki, Promtail i konfiguruje datasources.

## Dostęp do Grafana

```bash
kubectl get svc -n monitoring prometheus-stack-grafana
# Otwórz EXTERNAL-IP w przeglądarce
```

- **Username**: `admin`
- **Password**: `admin123`

## Uruchomienie aplikacji demo

```bash
kubectl apply -f microservices/deployment.yaml
```

### Generowanie ruchu (traces)

```bash
kubectl run load-generator --image=curlimages/curl --restart=Never -- \
  sh -c 'i=0; while true; do i=$((i+1));
    curl -s "http://frontend-service.default.svc.cluster.local:8080/api/order?order_id=test-$i" > /dev/null;
    curl -s "http://frontend-service.default.svc.cluster.local:8080/api/user?user_id=user-$i" > /dev/null;
    sleep 1; done'

# Zatrzymaj
kubectl delete pod load-generator
```

## Gdzie szukać danych w Grafana

| Co | Gdzie |
|----|-------|
| Metryki klastra | Dashboards → Kubernetes / Compute Resources |
| Logi | Explore → Loki → `{namespace="default"}` |
| Traces | Explore → Tempo → Search → service: `frontend-service` |
| Service Map | Explore → Tempo → Service Graph |

## Przykładowe zapytania

### Prometheus
```promql
# Liczba requestów HTTP do mikroserwisów
rate(http_requests_total[5m])

# 95. percentyl czasu odpowiedzi
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### Loki
```logql
# Logi z mikroserwisów
{namespace="default", app="frontend-service"}

# Tylko błędy
{namespace="default"} |= "ERROR"

# Logi z konkretnego order_id
{app="frontend-service"} | json | order_id="test-1"
```

### Tempo (TraceQL)
```
# Wszystkie trace'y frontend-service
{resource.service.name="frontend-service"}

# Tylko wolne spany (> 100ms)
{resource.service.name="frontend-service"} | duration > 100ms

# Cały łańcuch dla konkretnego order_id
{span.order.id="test-1"}
```

## Sprawdzenie stanu

```bash
# Status podów
kubectl get pods -n monitoring

# Czy Loki odbiera logi
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=5

# Czy Tempo odbiera traces
kubectl logs -n monitoring tempo-0 --tail=10
```

## Czyszczenie

```bash
kubectl delete pod load-generator --ignore-not-found
kubectl delete -f microservices/deployment.yaml
helm uninstall promtail loki tempo prometheus-stack -n monitoring
kubectl delete namespace monitoring
```
