# Mikroserwisy z OpenTelemetry - Distributed Tracing Demo

Zestaw mikroserwisów demonstrujących distributed tracing z OpenTelemetry i Grafana Tempo.

## 🏗️ Architektura

```
Frontend Service (Python/Flask)
    ↓
Service A (Node.js/Express)
    ↓
Service B (Python/Flask)
    ↓
Service C (Node.js/Express) - końcowy serwis
```

Każdy serwis:
- Wywołuje następny serwis w łańcuchu
- Wysyła traces do Grafana Tempo przez OpenTelemetry
- Propaguje trace context między serwisami
- Generuje strukturalne logi JSON

## 📋 Serwisy

### Frontend Service (Python)
- **Port**: 8080
- **Endpoints**:
  - `GET /` - Informacje o serwisie
  - `GET /api/order?order_id=xxx` - Tworzy zamówienie (wywołuje service-a)
  - `GET /api/user?user_id=xxx` - Pobiera użytkownika (wywołuje service-a)
  - `GET /health` - Health check

### Service A (Node.js)
- **Port**: 8080
- **Endpoints**:
  - `GET /` - Informacje o serwisie
  - `GET /api/process?order_id=xxx` - Przetwarza zamówienie (wywołuje service-b)
  - `GET /api/user?user_id=xxx` - Pobiera użytkownika (wywołuje service-b)
  - `GET /health` - Health check

### Service B (Python)
- **Port**: 8080
- **Endpoints**:
  - `GET /` - Informacje o serwisie
  - `GET /api/validate?order_id=xxx` - Waliduje zamówienie (wywołuje service-c)
  - `GET /api/user?user_id=xxx` - Pobiera użytkownika
  - `GET /health` - Health check

### Service C (Node.js)
- **Port**: 8080
- **Endpoints**:
  - `GET /` - Informacje o serwisie
  - `GET /api/complete?order_id=xxx` - Kończy przetwarzanie zamówienia
  - `GET /api/user?user_id=xxx` - Pobiera szczegóły użytkownika
  - `GET /api/orders/:orderId` - Pobiera zamówienie
  - `GET /health` - Health check

## 🚀 Instalacja

### 1. Przygotuj multi-platform builder (wymagane raz)

Domyślny driver Dockera nie obsługuje multi-platform builds. Utwórz builder z odpowiednim driverem:

```bash
docker buildx create --name multiarch --driver docker-container --use
docker buildx inspect --bootstrap
```

> **Dlaczego multi-platform?** Klastry Kubernetes zazwyczaj działają na `linux/amd64` (x86_64), natomiast Mac z Apple Silicon buduje obrazy domyślnie dla `linux/arm64`. Bez flagi `--platform` pod skończy się błędem `exec format error`.

### 2. Zbuduj i wypchnij obrazy Docker

```bash
cd microservices
chmod +x build.sh
./build.sh
```

Lub zbuduj każdy serwis osobno (build + push w jednym kroku):

```bash
# Frontend Service
cd frontend-service
docker buildx build --platform linux/amd64,linux/arm64 \
  -t dawidsages.azurecr.io/frontend-service:latest --push .
cd ..

# Service A
cd service-a
docker buildx build --platform linux/amd64,linux/arm64 \
  -t dawidsages.azurecr.io/service-a:latest --push .
cd ..

# Service B
cd service-b
docker buildx build --platform linux/amd64,linux/arm64 \
  -t dawidsages.azurecr.io/service-b:latest --push .
cd ..

# Service C
cd service-c
docker buildx build --platform linux/amd64,linux/arm64 \
  -t dawidsages.azurecr.io/service-c:latest --push .
cd ..
```

### 3. Zainstaluj w Kubernetes

```bash
kubectl apply -f deployment.yaml
```

### 4. Sprawdź status

```bash
kubectl get pods -l 'app in (frontend-service,service-a,service-b,service-c)'
kubectl get svc -l 'app in (frontend-service,service-a,service-b,service-c)'
```

## 🧪 Testowanie

### Generuj load na serwisy

```bash
chmod +x generate-load.sh
./generate-load.sh
```

Lub ręcznie:

```bash
# Port-forward do frontend-service
kubectl port-forward svc/frontend-service 8080:8080

# W osobnym terminalu - wywołaj endpointy
curl http://localhost:8080/api/order?order_id=test-123
curl http://localhost:8080/api/user?user_id=user-123
```

### Wywołaj przez kubectl

```bash
# Uruchom pod z curl
kubectl run -it --rm curl-test --image=curlimages/curl --restart=Never -- \
  sh -c "while true; do curl -s http://frontend-service.default.svc.cluster.local:8080/api/order?order_id=test-\$(date +%s); sleep 2; done"
```

## 📊 Observability

### Traces w Grafana Tempo

1. Otwórz Grafana (http://localhost:3000 lub LoadBalancer IP)
2. Przejdź do **Explore**
3. Wybierz datasource: **Tempo**
4. Wyszukaj po service name:
   - `frontend-service`
   - `service-a`
   - `service-b`
   - `service-c`
5. Kliknij na trace, aby zobaczyć pełny łańcuch wywołań

### Service Map

W Grafana Explore z Tempo, możesz zobaczyć:
- **Service Map** - wizualizację zależności między serwisami
- **Trace Timeline** - czas wykonania każdego span w łańcuchu
- **Span Details** - szczegóły każdego wywołania

### Przykładowy Trace

Gdy wywołasz `/api/order` na frontend-service, zobaczysz trace z:
1. `frontend-service` - span główny
2. `frontend-service.call_service_a` - wywołanie service-a
3. `service-a` - przetwarzanie w service-a
4. `service-a` (HTTP call) - wywołanie service-b
5. `service-b` - walidacja w service-b
6. `service-b.call_service_c` - wywołanie service-c
7. `service-c` - końcowe przetwarzanie

## 🔍 Logi

Wszystkie serwisy generują strukturalne logi JSON. Możesz je przeglądać w Loki:

```bash
# Logi z frontend-service
kubectl logs -l app=frontend-service --tail=50 -f

# Logi ze wszystkich serwisów
kubectl logs -l 'app in (frontend-service,service-a,service-b,service-c)' --tail=50
```

W Grafana Explore z Loki:
```
{app="frontend-service"} | json
{app="service-a"} | json
```

## 🧹 Usunięcie

```bash
kubectl delete -f deployment.yaml
```

## 📝 Uwagi

- Wszystkie serwisy są skonfigurowane do wysyłania traces do `tempo.monitoring.svc.cluster.local:4317`
- Trace context jest automatycznie propagowany przez OpenTelemetry instrumentation
- Każdy serwis ma health check endpoint
- Serwisy są skalowalne (replicas: 2)
- Resource limits są ustawione dla każdego serwisu

## 🎯 Ćwiczenia

1. **Obserwuj distributed traces**: Wywołaj `/api/order` i zobacz pełny trace w Tempo
2. **Analizuj czas wykonania**: Sprawdź który serwis jest najwolniejszy
3. **Service Map**: Zobacz wizualizację zależności między serwisami
4. **Trace propagation**: Sprawdź jak trace ID jest propagowany między serwisami
5. **Błędy**: Dodaj endpoint generujący błędy i zobacz jak są śledzone w traces

