# 🚀 Szybki Start - Mikroserwisy z OpenTelemetry

## Architektura

```
Frontend Service → Service A → Service B → Service C
```

Każdy serwis wywołuje następny, tworząc distributed trace widoczny w Grafana Tempo.

## Instalacja (3 kroki)

### 1. Zbuduj obrazy Docker

```bash
cd microservices
./build.sh
```

### 2. Zainstaluj w Kubernetes

```bash
kubectl apply -f deployment.yaml
```

### 3. Sprawdź status

```bash
kubectl get pods -l 'app in (frontend-service,service-a,service-b,service-c)'
kubectl get svc -l 'app in (frontend-service,service-a,service-b,service-c)'
```

## 🧪 Testowanie

### Generuj load (wywołuje cały łańcuch serwisów)

```bash
./generate-load.sh
```

### Lub ręcznie przez port-forward

```bash
# Terminal 1: Port-forward
kubectl port-forward svc/frontend-service 8080:8080

# Terminal 2: Wywołaj endpointy
curl http://localhost:8080/api/order?order_id=test-123
curl http://localhost:8080/api/user?user_id=user-123
```

### Lub przez kubectl

```bash
kubectl run -it --rm curl-test --image=curlimages/curl --restart=Never -- \
  sh -c "curl http://frontend-service.default.svc.cluster.local:8080/api/order?order_id=test-123"
```

## 📊 Obserwuj Traces w Grafana

1. Otwórz Grafana (port-forward lub LoadBalancer)
2. Przejdź do **Explore** → wybierz **Tempo**
3. Wyszukaj po service: `frontend-service`, `service-a`, `service-b`, `service-c`
4. Kliknij na trace, aby zobaczyć pełny łańcuch wywołań

### Co zobaczysz?

- **Service Map** - wizualizacja zależności między serwisami
- **Trace Timeline** - czas wykonania każdego span
- **Span Details** - szczegóły każdego wywołania HTTP
- **Propagacja trace context** - jak trace ID jest przekazywany między serwisami

## 🔍 Przykładowy Trace

Wywołanie `/api/order` na `frontend-service` tworzy trace z:

1. `frontend-service` (span główny)
   - `frontend-service.call_service_a` (HTTP call)
2. `service-a` (przetwarzanie)
   - `service-a` (HTTP call do service-b)
3. `service-b` (walidacja)
   - `service-b.call_service_c` (HTTP call)
4. `service-c` (końcowe przetwarzanie)

## 📝 Logi

```bash
# Logi z wszystkich serwisów
kubectl logs -l 'app in (frontend-service,service-a,service-b,service-c)' --tail=50 -f
```

W Grafana Loki:
```
{app="frontend-service"} | json
{app="service-a"} | json
```

## 🧹 Usunięcie

```bash
kubectl delete -f deployment.yaml
```

