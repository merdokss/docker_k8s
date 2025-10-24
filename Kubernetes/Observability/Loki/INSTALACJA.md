# Grafana Loki - Instalacja i konfiguracja

## ✅ Status instalacji

### Zainstalowane komponenty:
- ✅ **Loki Server** (StatefulSet) - agregacja i przechowywanie logów
- ✅ **Promtail** (DaemonSet, 4 instancje) - zbieranie logów z podów
- ✅ **Integracja z Grafaną** - datasource skonfigurowany

**Namespace:** `monitoring`  
**Release:** `loki`

---

## 🔐 Dostęp do logów

### Przez Grafanę (zalecane)

```bash
# Port-forward już może być uruchomiony
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Otwórz: http://localhost:3000
# Login: admin / Hasło: prom-operator
```

**W Grafanie:**
1. Kliknij **Explore** (ikona kompasu)
2. Wybierz datasource **Loki** (góra, dropdown)
3. Wpisz zapytanie, np: `{namespace="default"}`
4. Kliknij **Run query**

---

## 🚀 Reinstalacja (jeśli potrzebne)

```bash
# 1. Dodaj repozytorium
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 2. Zainstaluj Loki Stack
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false,prometheus.enabled=false,promtail.enabled=true

# 3. Dodaj datasource do Grafany
kubectl apply -f Kubernetes/Observability/Loki/update-grafana-datasources.yaml

# 4. Restart Grafany
kubectl rollout restart deployment -n monitoring prometheus-grafana
```

---

## 🔍 Sprawdzanie statusu

```bash
# Status Loki i Promtail
kubectl get pods -n monitoring | grep loki

# Logi Loki
kubectl logs -n monitoring loki-0 --tail=50

# Logi Promtail (wybierz konkretny pod)
kubectl logs -n monitoring loki-promtail-xxxxx --tail=50

# Serwisy
kubectl get svc -n monitoring | grep loki
```

---

## 📝 Przykładowe zapytania LogQL

### W Grafanie (Explore → Loki)

```logql
# Wszystkie logi z namespace default
{namespace="default"}

# Logi z konkretnego poda
{pod="nginx-with-metrics-7485b6df58-ccw5d"}

# Logi z aplikacji NGINX
{app="nginx"}

# Logi zawierające "error"
{namespace="default"} |= "error"

# Rate logów per sekunda
rate({namespace="default"}[5m])

# Count logów w ostatnich 5 minutach
count_over_time({namespace="default"}[5m])

# Top 5 podów z największą liczbą logów
topk(5, sum by (pod) (rate({namespace="default"}[5m])))
```

---

## 🎨 Pierwsze kroki - Demo

### 1. Sprawdź logi NGINX

W Grafanie Explore:
```logql
{app="nginx"}
```

### 2. Live streaming logów

1. Wpisz zapytanie: `{namespace="default"}`
2. Kliknij przycisk **Live** (prawy górny róg)
3. Logi będą odświeżane w czasie rzeczywistym

### 3. Filtrowanie

```logql
# Logi z konkretnego kontenera
{namespace="default", container="nginx"}

# Tylko błędy
{namespace="default"} |~ "(?i)(error|exception|fatal)"

# Wykluczenie debug logów
{namespace="default"} != "debug"
```

### 4. Tworzenie dashboarda

1. **Dashboards** → **New Dashboard**
2. **Add visualization**
3. Wybierz datasource: **Loki**
4. Zapytanie:
   ```logql
   sum by (namespace) (rate({job="promtail"}[1m]))
   ```
5. Typ: **Time series** lub **Logs**
6. **Save dashboard**

---

## 🏷️ Automatyczne labele

Promtail automatycznie dodaje labele z Kubernetes:

- `namespace` - namespace poda
- `pod` - nazwa poda
- `container` - nazwa kontenera  
- `app` - label app z poda
- `node_name` - węzeł
- `job` - promtail

**Przykład:**
```
{namespace="default", pod="nginx-with-metrics-abc", app="nginx", container="nginx"} 
2025-10-24T12:00:00Z [INFO] Server started
```

---

## 🔧 Konfiguracja

### Sprawdź konfigurację Promtail
```bash
kubectl get configmap loki-promtail -n monitoring -o yaml
```

### Sprawdź datasources w Grafanie
```bash
kubectl get configmap prometheus-kube-prometheus-grafana-datasource -n monitoring -o yaml
```

---

## 🚨 Troubleshooting

### Problem: Nie widzę żadnych logów

**Rozwiązanie:**

1. Sprawdź czy Promtail działa:
   ```bash
   kubectl get pods -n monitoring -l app=promtail
   ```

2. Sprawdź logi Promtail:
   ```bash
   kubectl logs -n monitoring -l app=promtail --tail=100
   ```

3. Sprawdź czy Loki odbiera dane:
   ```bash
   kubectl logs -n monitoring loki-0 | grep "POST /loki/api/v1/push"
   ```

4. Test datasource w Grafanie:
   - **Configuration** → **Data sources** → **Loki**
   - Kliknij **Save & test**
   - Powinno być: "Data source connected and labels found"

### Problem: Promtail nie wysyła logów

```bash
# Sprawdź czy Promtail ma dostęp do logów podów
kubectl exec -n monitoring -it loki-promtail-xxxxx -- ls -la /var/log/pods

# Sprawdź czy może połączyć się z Loki
kubectl exec -n monitoring -it loki-promtail-xxxxx -- wget -O- http://loki:3100/ready
```

### Problem: Grafana nie widzi datasource Loki

**Rozwiązanie:**
```bash
# 1. Sprawdź ConfigMap
kubectl get configmap prometheus-kube-prometheus-grafana-datasource -n monitoring -o yaml

# 2. Jeśli brak Loki, zastosuj:
kubectl apply -f Kubernetes/Observability/Loki/update-grafana-datasources.yaml

# 3. Restart Grafany
kubectl rollout restart deployment -n monitoring prometheus-grafana

# 4. Poczekaj ~30s i sprawdź w Grafanie
```

---

## 📊 Monitoring Loki

### Metryki Loki w Prometheusie

Loki eksportuje metryki, które możesz zobaczyć w Prometheusie:

```promql
# Ingested log entries
loki_ingester_streams_created_total

# Storage usage
loki_ingester_memory_chunks

# Request duration
loki_request_duration_seconds_bucket
```

### Dashboard dla Loki

Import gotowego dashboarda w Grafanie:
- **Dashboards** → **Import**  
- ID: **13639** (Loki & Promtail)
- Datasource: **Prometheus**

---

## 🎯 Use Cases

### Use Case 1: Debugging błędów aplikacji

```logql
# Wszystkie errory z ostatnich 15 minut
{namespace="default"} |~ "(?i)(error|exception)" 
```

### Use Case 2: Monitoring rate logów

Dashboard panel:
```logql
sum by (pod) (rate({namespace="default"}[5m]))
```

### Use Case 3: Alert na FATAL logs

```logql
count_over_time({namespace="default"} |= "FATAL"[5m]) > 0
```

---

## 📁 Pliki

```
Kubernetes/Observability/Loki/
├── README.md                        # Pełna dokumentacja
├── INSTALACJA.md                    # Ten plik
├── loki-datasource.yaml             # Datasource config (legacy)
└── update-grafana-datasources.yaml  # Updated datasources (używany)
```

---

## 🗑️ Deinstalacja

```bash
# Usuń Loki
helm uninstall loki -n monitoring

# Opcjonalnie: Przywróć oryginalne datasources Grafany
# (usuń sekcję Loki z ConfigMapy i zrestartuj Grafanę)
```

---

## 📖 Przydatne linki

- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/)
- [Best Practices](https://grafana.com/docs/loki/latest/best-practices/)
- [Grafana Loki Documentation](https://grafana.com/docs/loki/latest/)

---

**Data instalacji:** 24 października 2025  
**Stack:** Loki + Promtail + Grafana  
**Wersja:** loki-stack (latest via Helm)

