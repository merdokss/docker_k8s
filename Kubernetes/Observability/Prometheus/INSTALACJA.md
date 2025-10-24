# Prometheus + Grafana w Kubernetes

## ✅ Zainstalowane komponenty

### Prometheus Operator Stack
- **Namespace:** `monitoring`
- **Release:** `prometheus`
- **Komponenty:**
  - Prometheus Server (zbieranie metryk)
  - Grafana (wizualizacja)
  - Alertmanager (zarządzanie alertami)
  - Node Exporter (metryki węzłów)
  - Kube State Metrics (metryki obiektów K8s)
  - Prometheus Operator (automatyczne zarządzanie)

### NGINX z metrykami
- **Namespace:** `default`
- **Deployment:** `nginx-with-metrics`
- **Komponenty:** NGINX + nginx-prometheus-exporter
- **ServiceMonitor:** skonfigurowany automatyczny scraping

---

## 🔐 Dostęp do interfejsów

### Grafana
```bash
# Port-forward (może być już uruchomiony w tle)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Otworzyć w przeglądarce
http://localhost:3000

# Dane logowania:
Login: admin
Hasło: prom-operator
```

**Aby pobrać hasło ręcznie:**
```bash
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

### Prometheus
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# http://localhost:9090
```

### Alertmanager
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
# http://localhost:9093
```

---

## 🚀 Instalacja (jeśli trzeba reinstalować)

### 1. Zainstaluj Prometheus Operator z Grafaną
```bash
# Dodaj repozytorium Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Zainstaluj kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

### 2. Wdróż NGINX z metrykami
```bash
kubectl apply -f Kubernetes/Observability/Prometheus/nginx/deployment.yaml
```

### 3. Skonfiguruj ServiceMonitor
```bash
kubectl apply -f Kubernetes/Observability/Prometheus/servicemonitor-nginx.yaml
```

---

## 🔍 Sprawdzanie statusu

```bash
# Status komponentów Prometheus
kubectl get pods -n monitoring

# Status NGINX z metrykami
kubectl get pods -l app=nginx

# Wszystkie ServiceMonitory
kubectl get servicemonitors -n monitoring

# CRDs zainstalowane przez Operator
kubectl get crd | grep monitoring.coreos.com

# Sprawdź instancje Prometheusa
kubectl get prometheus -n monitoring
```

---

## 📊 Pierwsze kroki w Grafanie

1. **Zaloguj się** do Grafany (http://localhost:3000)
2. **Explore** → wybierz datasource **Prometheus**
3. **Dashboards → Browse** → dostępne gotowe dashboardy:
   - Kubernetes / Compute Resources / Cluster
   - Kubernetes / Compute Resources / Namespace
   - Kubernetes / Kubelet
   - Node Exporter / Nodes

### Import gotowego dashboarda dla NGINX

1. **Dashboards → Import**
2. Wpisz ID: **12708** (NGINX Prometheus Exporter)
3. Wybierz datasource: **Prometheus**
4. Kliknij **Import**

---

## 📝 Przykładowe zapytania PromQL

### Metryki NGINX
```promql
# Aktywne połączenia NGINX
nginx_connections_active

# Zaakceptowane połączenia
nginx_connections_accepted

# Request rate (żądania na sekundę)
rate(nginx_http_requests_total[5m])

# Liczba połączeń obsłużonych
nginx_connections_handled
```

### Metryki Kubernetes
```promql
# Status podów
kube_pod_status_phase

# Zużycie pamięci przez kontenery
container_memory_usage_bytes

# Zużycie CPU przez pody
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)

# Liczba podów w namespace
count(kube_pod_info) by (namespace)

# Dostępność węzłów
up{job="node-exporter"}
```

### Testowanie zapytań

**W Prometheusie:**
- Otwórz http://localhost:9090
- Przejdź do zakładki **Graph**
- Wpisz zapytanie i kliknij **Execute**

**W Grafanie:**
- Przejdź do **Explore**
- Wybierz datasource **Prometheus**
- Wpisz zapytanie i kliknij **Run query**

---

## 🎨 Monitoring własnych aplikacji

### Wymagania dla aplikacji
1. Aplikacja musi eksponować endpoint `/metrics` w formacie Prometheus
2. Service musi mieć odpowiednie etykiety
3. Port metryk musi być nazwany (np. `metrics`)

### Przykład: Deployment z metrykami
```yaml
apiVersion: v1
kind: Service
metadata:
  name: moja-aplikacja
  labels:
    app: moja-aplikacja
spec:
  ports:
  - name: metrics      # Ważne: nazwany port
    port: 8080
  selector:
    app: moja-aplikacja
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: moja-aplikacja
  namespace: monitoring
  labels:
    release: prometheus   # Ważne: label do matchowania
spec:
  selector:
    matchLabels:
      app: moja-aplikacja
  namespaceSelector:
    matchNames:
      - default          # Namespace gdzie jest aplikacja
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Sprawdzanie czy metryki są zbierane

```bash
# Sprawdź ServiceMonitor
kubectl describe servicemonitor -n monitoring moja-aplikacja

# Zobacz targets w Prometheusie
# http://localhost:9090/targets

# Sprawdź czy metryki są dostępne bezpośrednio
kubectl port-forward svc/moja-aplikacja 8080:8080
curl http://localhost:8080/metrics
```

---

## 🔧 Przydatne komendy

### Zarządzanie
```bash
# Restart Grafany
kubectl rollout restart deployment -n monitoring prometheus-grafana

# Restart Prometheusa
kubectl rollout restart statefulset -n monitoring prometheus-prometheus-kube-prometheus-prometheus

# Aktualizacja Prometheus Operator
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Sprawdź wersję
helm list -n monitoring
```

### Diagnostyka
```bash
# Logi Prometheusa
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 prometheus

# Logi Grafany
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Logi Operatora
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus-operator

# Logi NGINX exporter
kubectl logs -l app=nginx -c nginx-exporter

# Lista PrometheusRules
kubectl get prometheusrules -n monitoring
```

---

## 🚨 Rozwiązywanie problemów

### Problem: ServiceMonitor nie zbiera metryk

**Sprawdź:**
1. Czy Service ma odpowiednie labele?
   ```bash
   kubectl get svc moja-aplikacja -o yaml
   ```

2. Czy ServiceMonitor ma label `release: prometheus`?
   ```bash
   kubectl get servicemonitor -n monitoring moja-aplikacja -o yaml
   ```

3. Czy targets są widoczne w Prometheusie?
   - http://localhost:9090/targets

4. Czy port jest nazwany w Service?
   ```yaml
   ports:
   - name: metrics   # MUSI być nazwany!
     port: 8080
   ```

### Problem: Grafana nie łączy się z Prometheusem

**Rozwiązanie:**
1. Przejdź do **Configuration → Data sources**
2. Kliknij na **Prometheus**
3. Sprawdź URL: `http://prometheus-kube-prometheus-prometheus:9090`
4. Kliknij **Save & test**

### Problem: Brak metryk dla aplikacji

**Sprawdź bezpośrednio endpoint:**
```bash
kubectl port-forward svc/moja-aplikacja 8080:8080
curl http://localhost:8080/metrics
```

Jeśli nie zwraca metryk - problem jest w aplikacji, nie w Prometheusie.

### Problem: Port-forward się przerywa

**Uruchom w tle:**
```bash
nohup kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 > /dev/null 2>&1 &
```

---

## 📚 Custom Resource Definitions (CRDs)

Prometheus Operator dostarcza następujące CRDs:

- **Prometheus** - definiuje instancje Prometheusa
- **ServiceMonitor** - automatyczne wykrywanie serwisów
- **PodMonitor** - monitorowanie bezpośrednio podów
- **PrometheusRule** - reguły alertowania i nagrywania
- **AlertmanagerConfig** - konfiguracja alertów
- **Probe** - blackbox monitoring

```bash
# Lista wszystkich CRDs
kubectl get crd | grep monitoring.coreos.com
```

---

## 🎯 Przykładowe scenariusze użycia

### Scenariusz 1: Monitoring obciążenia aplikacji

**Cel:** Dashboard pokazujący RPS, latencję, błędy

**W Grafanie utwórz panel:**
```promql
# Request rate
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# Latencja (p95)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### Scenariusz 2: HPA z custom metrics

**Prometheus Adapter** (wchodzi w skład kube-prometheus-stack) pozwala używać metryk Prometheus w HPA:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-with-metrics
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Pods
    pods:
      metric:
        name: nginx_connections_active
      target:
        type: AverageValue
        averageValue: "100"
```
