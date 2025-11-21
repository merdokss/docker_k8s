# Example App - Przykładowa aplikacja dla Observability

Aplikacja demonstrująca integrację z Prometheus, Loki i Tempo.

## Funkcje

- **Metryki Prometheus**: Endpoint `/metrics` z metrykami HTTP, czasu wykonania, połączeń
- **Strukturalne logi JSON**: Wszystkie logi w formacie JSON dla łatwego parsowania przez Loki
- **OpenTelemetry Traces**: Automatyczne śledzenie requestów i wysyłanie do Tempo

## Endpointy

- `GET /` - Informacje o aplikacji
- `GET /api/hello?name=World` - Prosty endpoint z logami i traces
- `GET /api/calculate?numbers=1&numbers=2&numbers=3` - Obliczenia z metrykami czasu
- `GET /api/error?type=generic` - Generowanie błędów (do testowania alertów)
- `GET /api/connection?action=connect` - Zarządzanie połączeniami (Gauge metric)
- `GET /metrics` - Prometheus metrics
- `GET /health` - Health check

## Budowanie

```bash
./build.sh
```

Lub ręcznie:

```bash
docker build -t example-app:latest .
```

Jeśli używasz kind:

```bash
kind load docker-image example-app:latest
```

## Instalacja

```bash
kubectl apply -f deployment.yaml
```

## Testowanie

### Podstawowe testy

```bash
# Pobierz adres aplikacji
kubectl get svc example-app

# Test hello endpoint
curl http://example-app.default.svc.cluster.local:8080/api/hello?name=Test

# Test calculate endpoint
curl "http://example-app.default.svc.cluster.local:8080/api/calculate?numbers=10&numbers=20&numbers=30"

# Test error endpoint
curl http://example-app.default.svc.cluster.local:8080/api/error

# Sprawdź metryki
curl http://example-app.default.svc.cluster.local:8080/metrics
```

### Generowanie load

```bash
# W osobnym terminalu - generuj ciągły load
kubectl run -it --rm load-generator --image=curlimages/curl --restart=Never -- \
  sh -c "while true; do curl -s http://example-app.default.svc.cluster.local:8080/api/hello?name=LoadTest; sleep 0.5; done"
```

### Generowanie różnych typów requestów

```bash
# Mix różnych endpointów
for i in {1..100}; do
  curl -s http://example-app.default.svc.cluster.local:8080/api/hello?name=User$i
  curl -s "http://example-app.default.svc.cluster.local:8080/api/calculate?numbers=$i&numbers=$((i+1))"
  sleep 0.2
done
```

## Metryki Prometheus

Aplikacja eksportuje następujące metryki:

- `http_requests_total` - Licznik wszystkich requestów HTTP (z labelami: method, endpoint, status)
- `http_request_duration_seconds` - Histogram czasu wykonania requestów
- `active_connections` - Gauge z liczbą aktywnych połączeń
- `business_operations_total` - Licznik operacji biznesowych (z labelami: operation_type, status)

## Logi

Wszystkie logi są w formacie JSON z następującymi polami:
- `timestamp` - Czas w ISO format
- `level` - Poziom logowania (INFO, ERROR, etc.)
- `message` - Treść wiadomości
- `service` - Nazwa serwisu (example-app)
- Dodatkowe pola kontekstowe (endpoint, method, etc.)

## Traces

Aplikacja używa OpenTelemetry do automatycznego śledzenia:
- Wszystkie requesty HTTP są automatycznie śledzone
- Nested spans dla operacji obliczeniowych
- Atrybuty z informacjami o requestach i odpowiedziach
- Traces są wysyłane do Tempo przez OTLP

## Sprawdzanie w Grafana

### Metryki w Prometheus

1. Otwórz Prometheus: `kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090`
2. Przejdź do http://localhost:9090
3. Wyszukaj metryki: `http_requests_total`, `http_request_duration_seconds`, etc.

### Logi w Loki

1. Otwórz Grafana: `kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80`
2. Przejdź do Explore → wybierz Loki
3. Wyszukaj: `{app="example-app"}` lub `{service="example-app"}`

### Traces w Tempo

1. W Grafana Explore → wybierz Tempo
2. Wyszukaj po service name: `example-app`
3. Lub użyj traceID z logów Loki

## Usunięcie

```bash
kubectl delete -f deployment.yaml
```

