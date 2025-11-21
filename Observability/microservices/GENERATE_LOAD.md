# 🚀 Generowanie Ruchu dla Mikroserwisów - Distributed Tracing

## Sposoby generowania load

### 1. Prosty test - kilka requestów (zalecane na start)

```bash
# Wygeneruj 10 requestów
kubectl run -it --rm load-test --image=curlimages/curl --restart=Never -- \
  sh -c 'for i in {1..10}; do echo "Request $i"; curl -s "http://frontend-service.default.svc.cluster.local:8080/api/order?order_id=test-$i" | head -c 150; echo ""; sleep 1; done'
```

### 2. Ciągły load - w tle (dla obserwacji w Grafana)

```bash
# Uruchom w tle - będzie generować load przez kilka minut
kubectl run load-gen-continuous --image=curlimages/curl --restart=Never -- \
  sh -c 'while true; do curl -s "http://frontend-service.default.svc.cluster.local:8080/api/order?order_id=test-$(date +%s)" > /dev/null; curl -s "http://frontend-service.default.svc.cluster.local:8080/api/user?user_id=user-123" > /dev/null; sleep 2; done'
```

**Zatrzymaj load:**
```bash
kubectl delete pod load-gen-continuous
```

### 3. Różne endpointy - pełny test

```bash
kubectl run -it --rm load-full --image=curlimages/curl --restart=Never -- \
  sh -c 'for i in {1..20}; do 
    echo "=== Request $i ==="
    curl -s "http://frontend-service.default.svc.cluster.local:8080/api/order?order_id=order-$i"
    echo ""
    sleep 1
    curl -s "http://frontend-service.default.svc.cluster.local:8080/api/user?user_id=user-$((i%3))"
    echo ""
    sleep 1
  done'
```

### 4. Intensywny load - wiele równoległych requestów

```bash
# Uruchom 5 równoległych generatorów
for i in {1..5}; do
  kubectl run load-gen-$i --image=curlimages/curl --restart=Never -- \
    sh -c 'while true; do curl -s "http://frontend-service.default.svc.cluster.local:8080/api/order?order_id=load-$i-$(date +%s)" > /dev/null; sleep 1; done' &
done

# Zatrzymaj wszystkie
kubectl delete pod -l run=load-gen-1,run=load-gen-2,run=load-gen-3,run=load-gen-4,run=load-gen-5
```

## 📊 Jak zobaczyć traces w Grafana

### 1. Otwórz Grafana

```bash
# Port-forward do Grafana
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

# Lub użyj LoadBalancer
kubectl get svc -n monitoring prometheus-stack-grafana
```

Otwórz przeglądarkę: http://localhost:3000
- Username: `admin`
- Password: `admin123` (lub sprawdź: `kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d`)

### 2. Przejdź do Explore → Tempo

1. Kliknij **Explore** (ikona kompasu po lewej)
2. Wybierz datasource: **Tempo**
3. Wyszukaj po service name:
   - `frontend-service`
   - `service-a`
   - `service-b`
   - `service-c`

### 3. Filtry wyszukiwania

```
# Wszystkie traces z frontend-service
service.name=frontend-service

# Traces z ostatnich 15 minut
service.name=frontend-service AND duration > 10ms

# Traces z błędami
status=error
```

### 4. Co zobaczysz w trace?

Po kliknięciu na trace zobaczysz:
- **Service Map** - wizualizacja zależności między serwisami
- **Trace Timeline** - czas wykonania każdego span
- **Span Details** - szczegóły każdego wywołania HTTP
- **Propagacja trace context** - jak trace ID jest przekazywany

### Przykładowy trace

Wywołanie `/api/order` tworzy trace z:
1. `frontend-service` (span główny)
   - `frontend-service.call_service_a` (HTTP call)
2. `service-a` (przetwarzanie)
   - `service-a` (HTTP call do service-b)
3. `service-b` (walidacja)
   - `service-b.call_service_c` (HTTP call)
4. `service-c` (końcowe przetwarzanie)

## 🔍 Sprawdzenie czy traces są wysyłane

### Logi z serwisów

```bash
# Sprawdź logi z frontend-service
kubectl logs -l app=frontend-service --tail=20 -f

# Sprawdź logi ze wszystkich serwisów
kubectl logs -l 'app in (frontend-service,service-a,service-b,service-c)' --tail=10
```

### Test połączenia z Tempo

```bash
# Sprawdź czy Tempo jest dostępne
kubectl run -it --rm test-tempo --image=curlimages/curl --restart=Never -- \
  curl -v http://tempo.monitoring.svc.cluster.local:4318
```

## 💡 Szybki start - wszystko w jednym

```bash
# 1. Wygeneruj load (w osobnym terminalu)
kubectl run load-gen --image=curlimages/curl --restart=Never -- \
  sh -c 'for i in {1..50}; do curl -s "http://frontend-service.default.svc.cluster.local:8080/api/order?order_id=test-$i" > /dev/null; sleep 1; done'

# 2. Otwórz Grafana
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

# 3. W Grafana: Explore → Tempo → service.name=frontend-service
```

## 🧹 Czyszczenie

```bash
# Zatrzymaj wszystkie generatory load
kubectl delete pod -l run=load-gen
kubectl delete pod load-gen-continuous 2>/dev/null
kubectl delete pod load-gen-full 2>/dev/null
```

