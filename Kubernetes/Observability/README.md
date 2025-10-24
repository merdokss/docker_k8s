# Stack Observability w Kubernetes

## 🎯 Zainstalowane komponenty

### 📊 Prometheus + Grafana (Metryki)
- **Lokalizacja:** `Prometheus/`
- **Namespace:** `monitoring`
- **Komponenty:**
  - Prometheus Server
  - Grafana
  - Alertmanager
  - Node Exporter
  - Kube State Metrics
  - NGINX z metrykami + ServiceMonitor

**Dokumentacja:** [Prometheus/INSTALACJA.md](./Prometheus/INSTALACJA.md)

### 📝 Loki + Promtail (Logi)
- **Lokalizacja:** `Loki/`
- **Namespace:** `monitoring`
- **Komponenty:**
  - Loki Server
  - Promtail (DaemonSet)
  - Integracja z Grafaną

**Dokumentacja:** [Loki/INSTALACJA.md](./Loki/INSTALACJA.md)

---

## 🔐 Szybki dostęp

### Grafana (metryki + logi)
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# http://localhost:3000
# Login: admin / Hasło: prom-operator
```

### Prometheus (metryki)
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# http://localhost:9090
```

### Loki (logi - przez API)
```bash
kubectl port-forward -n monitoring svc/loki 3100:3100
# http://localhost:3100
```

---

## 🚀 Kompletny stack w Grafanie

W Grafanie masz dostęp do:

1. **Explore** → **Prometheus** - zapytania PromQL do metryk
2. **Explore** → **Loki** - zapytania LogQL do logów  
3. **Dashboards** - gotowe dashboardy dla Kubernetes
4. **Alerting** - konfiguracja alertów

### Przykładowa sesja debugowania:

**Krok 1: Sprawdź metryki**
```promql
# W Explore → Prometheus
container_memory_usage_bytes{pod="my-app-123"}
```

**Krok 2: Sprawdź logi tego samego poda**
```logql
# W Explore → Loki
{pod="my-app-123"}
```

**Krok 3: Filtruj błędy**
```logql
{pod="my-app-123"} |= "error"
```

---

## 📊 Gotowe dashboardy

### Zainstalowane automatycznie:
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace
- Kubernetes / Kubelet
- Node Exporter / Nodes

### Do zaimportowania:
- **12708** - NGINX Prometheus Exporter (metryki NGINX)
- **13639** - Loki & Promtail (metryki logowania)

**Import:** Dashboards → Import → wpisz ID

---

## 🔍 Sprawdzanie statusu

```bash
# Wszystkie komponenty w monitoring namespace
kubectl get pods -n monitoring

# Tylko Prometheus stack
kubectl get pods -n monitoring -l release=prometheus

# Tylko Loki stack  
kubectl get pods -n monitoring | grep loki

# ServiceMonitory (zbieranie metryk)
kubectl get servicemonitors -n monitoring

# Serwisy
kubectl get svc -n monitoring
```

---

## 🎨 Przykładowe scenariusze

### Scenariusz 1: Debugowanie wysokiego CPU

**W Grafanie:**

1. **Explore → Prometheus**
   ```promql
   topk(5, rate(container_cpu_usage_seconds_total[5m]))
   ```

2. Znajdź pod z wysokim CPU

3. **Explore → Loki** (ten sam pod)
   ```logql
   {pod="nazwa-poda"} | json | level="error"
   ```

### Scenariusz 2: Monitoring aplikacji

**Dashboard z 3 panelami:**

Panel 1 - Request rate (Prometheus):
```promql
rate(http_requests_total[5m])
```

Panel 2 - Error rate (Prometheus):
```promql
rate(http_requests_total{status=~"5.."}[5m])
```

Panel 3 - Error logs (Loki):
```logql
{app="my-app"} |= "error"
```

### Scenariusz 3: Alert na błędy w logach

1. Utwórz dashboard panel z Loki:
   ```logql
   count_over_time({namespace="prod"} |= "FATAL"[5m])
   ```

2. Dodaj alert: value > 0

3. Skonfiguruj notification channel (Slack/Email)

---

## 📚 Dokumentacja

### Prometheus
- **README.md** - teoria, komponenty, porównanie metod
- **INSTALACJA.md** - praktyczny przewodnik, przykłady, troubleshooting

### Loki
- **README.md** - teoria, architektura, składnia LogQL
- **INSTALACJA.md** - szybki start, przykłady, troubleshooting

---

## 🔧 Monitoring własnych aplikacji

### Dodanie metryk (Prometheus)

1. Aplikacja eksportuje `/metrics` endpoint
2. Stwórz Service z nazwanymi portami
3. Stwórz ServiceMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  namespace: monitoring
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: my-app
  namespaceSelector:
    matchNames:
      - default
  endpoints:
  - port: metrics
    interval: 30s
```

### Zbieranie logów (Loki)

Promtail **automatycznie** zbiera logi ze wszystkich podów!

Po prostu loguj do stdout:
```python
print("[INFO] Request processed")
print("[ERROR] Database connection failed")
```

Query w Loki:
```logql
{namespace="default", app="my-app"}
```

---

## 🚨 Typowe problemy

### Problem: Grafana nie działa
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
kubectl rollout restart deployment -n monitoring prometheus-grafana
```

### Problem: Nie widzę metryk z aplikacji
1. Sprawdź ServiceMonitor: `kubectl get servicemonitors -n monitoring`
2. Sprawdź targets w Prometheus: http://localhost:9090/targets
3. Sprawdź labele Service i ServiceMonitor

### Problem: Nie widzę logów w Loki
1. Sprawdź Promtail: `kubectl get pods -n monitoring -l app=promtail`
2. Sprawdź logi Promtail: `kubectl logs -n monitoring -l app=promtail`
3. Test datasource w Grafanie: Configuration → Data sources → Loki → Save & test

---

## 📖 Zasoby

### Prometheus
- [Prometheus Docs](https://prometheus.io/docs/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)

### Loki
- [Loki Docs](https://grafana.com/docs/loki/)
- [LogQL Syntax](https://grafana.com/docs/loki/latest/logql/)

### Grafana
- [Grafana Tutorials](https://grafana.com/tutorials/)
- [Dashboard Gallery](https://grafana.com/grafana/dashboards/)

---

## 🎉 Podsumowanie

Masz teraz kompletny stack observability:

✅ **Metryki** - Prometheus (time-series data)  
✅ **Logi** - Loki (log aggregation)  
✅ **Wizualizacja** - Grafana (metryki + logi w jednym miejscu)  
✅ **Alerty** - Alertmanager (powiadomienia)  
✅ **Automatyczne zbieranie** - ServiceMonitor + Promtail  

**Wszystko zintegrowane w jednym interfejsie - Grafana! 🚀**

---

**Data instalacji:** 24 października 2025  
**Namespace:** `monitoring`

