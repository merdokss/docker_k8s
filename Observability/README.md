# Stack Observability - Prometheus, Grafana, Tempo, Loki

Kompletny stack observability dla Kubernetes zawierający:
- **Prometheus** - zbieranie metryk
- **Grafana** - wizualizacja metryk, logów i traces
- **Grafana Tempo** - zbieranie i przechowywanie traces
- **Grafana Loki** - zbieranie i przechowywanie logów

## 📋 Wymagania

- Kubernetes cluster (1.19+)
- Helm 3.x
- kubectl skonfigurowany do pracy z klastrem

## 🚀 Instalacja

### 1. Dodaj repozytoria Helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### 2. Utwórz namespace

```bash
kubectl create namespace monitoring
```

### 3. Zainstaluj kube-prometheus-stack

```bash
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-stack-values.yaml \
  --wait
```

### 4. Zainstaluj Grafana Tempo

```bash
helm install tempo grafana/tempo \
  --namespace monitoring \
  --values tempo-values.yaml \
  --wait
```

### 5. Zainstaluj Grafana Loki

```bash
helm install loki grafana/loki \
  --namespace monitoring \
  --values loki-values.yaml \
  --wait
```

### 6. Zaktualizuj Grafana, aby używała Tempo i Loki

```bash
kubectl apply -f grafana-datasources.yaml
```

### 7. Zainstaluj przykładową aplikację

```bash
kubectl apply -f example-app/
```

## 🔍 Dostęp do Grafana

### LoadBalancer (zalecane)

Grafana jest dostępna przez LoadBalancer:

```bash
kubectl get svc -n monitoring prometheus-stack-grafana
```

Otwórz przeglądarkę na adresie z kolumny `EXTERNAL-IP` (np. http://4.245.142.179)

### Port-forward (alternatywa)

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```

Następnie otwórz przeglądarkę: http://localhost:3000

### Domyślne dane logowania

- **Username**: `admin`
- **Password**: Sprawdź hasło:
  ```bash
  kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d
  ```

## 📊 Przykładowa aplikacja

Aplikacja `example-app` generuje:
- **Metryki**: Prometheus metrics na `/metrics` endpoint
- **Logi**: Strukturalne logi JSON
- **Traces**: OpenTelemetry traces

### Testowanie aplikacji

```bash
# Pobierz adres aplikacji
kubectl get svc example-app -n default

# Wygeneruj load (w osobnym terminalu)
kubectl run -it --rm load-generator --image=curlimages/curl --restart=Never -- \
  sh -c "while true; do curl http://example-app.default.svc.cluster.local:8080/api/hello; sleep 1; done"
```

## 📈 Dashboardy Grafana

Po zalogowaniu do Grafana, dostępne są następujące dashboardy:

1. **Kubernetes / Compute Resources / Cluster** - metryki klastra
2. **Kubernetes / Compute Resources / Namespace** - metryki namespace
3. **Kubernetes / Compute Resources / Pod** - metryki podów
4. **Example App Dashboard** - custom dashboard dla przykładowej aplikacji
5. **Tempo Service Map** - mapa serwisów z traces
6. **Loki Logs Explorer** - eksplorator logów

## 🔧 Konfiguracja

### Prometheus

- Zbiera metryki z klastra (nodes, pods, services)
- Zbiera metryki z przykładowej aplikacji (ServiceMonitor)
- Retencja: 15 dni
- Storage: 50GB

### Grafana

- Pre-instalowane datasources: Prometheus, Loki, Tempo
- Pre-instalowane dashboardy Kubernetes
- Ingress: opcjonalnie (sprawdź `grafana-ingress.yaml`)

### Tempo

- Backend: S3-compatible storage (lokalny storage dla demo)
- Retencja: 7 dni
- Port: 3200 (gRPC), 4317 (OTLP HTTP), 4318 (OTLP gRPC)

### Loki

- Backend: filesystem storage
- Retencja: 30 dni
- Port: 3100 (HTTP)

## 🧹 Usunięcie

```bash
# Usuń przykładową aplikację
kubectl delete -f example-app/

# Usuń stack observability
helm uninstall loki -n monitoring
helm uninstall tempo -n monitoring
helm uninstall prometheus-stack -n monitoring

# Usuń namespace
kubectl delete namespace monitoring
```

## 📚 Przydatne komendy

```bash
# Sprawdź status
kubectl get pods -n monitoring

# Sprawdź logi Prometheus
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Sprawdź logi Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Sprawdź metryki z przykładowej aplikacji
kubectl port-forward svc/example-app 8080:8080
curl http://localhost:8080/metrics
```

## 🎯 Ćwiczenia

1. **Metryki**: Sprawdź metryki aplikacji w Prometheus
2. **Logi**: Przeszukaj logi aplikacji w Loki
3. **Traces**: Prześledź request przez aplikację w Tempo
4. **Dashboardy**: Stwórz własny dashboard w Grafana
5. **Alerty**: Skonfiguruj alerty w Prometheus

