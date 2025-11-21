# 🚀 Szybki Start - Stack Observability

## Instalacja (5 minut)

### 1. Zainstaluj stack observability

```bash
cd Observability
./install.sh
```

### 2. Zbuduj i zainstaluj przykładową aplikację

```bash
cd example-app
./build.sh
kubectl apply -f deployment.yaml
```

### 3. Dostęp do Grafana

Grafana jest dostępna przez LoadBalancer:

```bash
kubectl get svc -n monitoring prometheus-stack-grafana
```

Otwórz przeglądarkę na adresie z kolumny `EXTERNAL-IP` (np. http://4.245.142.179)

**Alternatywa - port-forward:**
```bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```
Otwórz: http://localhost:3000

- **Username**: `admin`
- **Password**: `admin123`

## 🎯 Szybkie testy

### Generuj load na aplikację

```bash
# W osobnym terminalu
kubectl run -it --rm load-gen --image=curlimages/curl --restart=Never -- \
  sh -c 'while true; do curl -s http://example-app.default.svc.cluster.local:8080/api/hello?name=Test; sleep 0.5; done'
```

### Sprawdź metryki w Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
```

Otwórz: http://localhost:9090

Przykładowe zapytania:
- `rate(http_requests_total[5m])`
- `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`
- `active_connections`

### Sprawdź logi w Grafana

1. Otwórz Grafana (http://localhost:3000)
2. Przejdź do **Explore** (ikona kompasu)
3. Wybierz datasource: **Loki**
4. Wpisz zapytanie: `{app="example-app"}`

### Sprawdź traces w Grafana

1. W Grafana **Explore**
2. Wybierz datasource: **Tempo**
3. Wyszukaj po service: `example-app`
4. Kliknij na trace, aby zobaczyć szczegóły

## 📊 Co zobaczysz?

### Metryki (Prometheus)
- Liczba requestów HTTP
- Czas wykonania requestów
- Aktywne połączenia
- Operacje biznesowe

### Logi (Loki)
- Strukturalne logi JSON z aplikacji
- Logi z wszystkich podów Kubernetes
- Możliwość filtrowania po labelach

### Traces (Tempo)
- Śledzenie requestów przez aplikację
- Czas wykonania każdej operacji
- Zależności między serwisami
- Integracja z logami (kliknięcie w trace pokazuje powiązane logi)

## 🔍 Przykładowe zapytania

### Prometheus

```promql
# Rate requestów
rate(http_requests_total[5m])

# 95th percentile czasu wykonania
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Błędy
rate(http_requests_total{status="500"}[5m])
```

### Loki

```logql
# Wszystkie logi z aplikacji
{app="example-app"}

# Tylko błędy
{app="example-app"} |= "ERROR"

# Logi z konkretnego endpointu
{app="example-app"} | json | endpoint="/api/calculate"
```

### Tempo

- Service name: `example-app`
- Tag search: `http.method=GET`
- TraceID: (z logów Loki)

## 🎓 Ćwiczenia

1. **Metryki**: Stwórz alert w Prometheus dla wysokiego czasu odpowiedzi
2. **Logi**: Znajdź wszystkie błędy z ostatniej godziny
3. **Traces**: Prześledź request od początku do końca
4. **Dashboard**: Stwórz własny dashboard w Grafana łączący metryki, logi i traces

## 🧹 Czyszczenie

```bash
# Usuń aplikację
kubectl delete -f example-app/deployment.yaml

# Usuń stack
helm uninstall loki tempo prometheus-stack -n monitoring
kubectl delete namespace monitoring
```

