# Grafana Loki - System agregacji logów

## ✅ Zainstalowane komponenty

### Loki Stack
- **Namespace:** `monitoring`
- **Release:** `loki`
- **Komponenty:**
  - **Loki** - serwer agregacji i przechowywania logów
  - **Promtail** - agent zbierający logi z podów (DaemonSet na każdym węźle)
  - **Grafana** - wizualizacja (zintegrowana z istniejącą instalacją)

---

## 📖 Co to jest Loki?

**Grafana Loki** to system agregacji logów inspirowany Prometheusem, ale zaprojektowany dla logów zamiast metryk.

### Główne cechy:
- 📊 **Podobny do Prometheus** - używa labelów zamiast indeksowania pełnej treści
- 🚀 **Wydajny** - niskie zużycie zasobów dzięki braku full-text indexu
- 🔍 **Integracja z Grafaną** - logi i metryki w jednym miejscu
- 🏷️ **Label-based** - wyszukiwanie oparte na labelach Kubernetes
- 💰 **Tani w utrzymaniu** - mniejsze wymagania storage niż ELK

### Architektura:

```
┌─────────────┐     ┌──────────────┐     ┌──────────┐
│  Pod logs   │────▶│   Promtail   │────▶│   Loki   │
│   stdout    │     │  (DaemonSet) │     │ (Server) │
└─────────────┘     └──────────────┘     └──────────┘
                                                │
                                                ▼
                                          ┌──────────┐
                                          │ Grafana  │
                                          │ (Query)  │
                                          └──────────┘
```

---

## 🚀 Instalacja (wykonana)

```bash
# 1. Dodaj repozytorium Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 2. Zainstaluj Loki Stack
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false,prometheus.enabled=false,promtail.enabled=true

# 3. Zaktualizuj datasources w Grafanie
kubectl apply -f Kubernetes/Observability/Loki/update-grafana-datasources.yaml

# 4. Restart Grafany
kubectl rollout restart deployment -n monitoring prometheus-grafana
```

---

## 🔍 Sprawdzanie statusu

```bash
# Status Loki
kubectl get pods -n monitoring -l app=loki

# Status Promtail (jeden pod na węzeł)
kubectl get pods -n monitoring -l app=promtail

# Serwisy Loki
kubectl get svc -n monitoring | grep loki

# Logi Loki
kubectl logs -n monitoring loki-0

# Logi Promtail
kubectl logs -n monitoring -l app=promtail --tail=50
```

---

## 🔐 Dostęp do Loki

### Przez Grafanę (zalecane)
1. Otwórz Grafanę: http://localhost:3000 (login: admin / hasło: prom-operator)
2. Przejdź do **Explore**
3. Wybierz datasource **Loki** z górnego menu
4. Wpisz zapytanie LogQL

### Port-forward bezpośrednio do Loki
```bash
kubectl port-forward -n monitoring svc/loki 3100:3100
# API: http://localhost:3100
# Query API: http://localhost:3100/loki/api/v1/query
```

---

## 📝 Przykładowe zapytania LogQL

### Podstawowe zapytania

```logql
# Wszystkie logi z namespace default
{namespace="default"}

# Logi z konkretnego poda
{pod="nginx-with-metrics-7485b6df58-ccw5d"}

# Logi z określonej aplikacji
{app="nginx"}

# Logi z namespace monitoring
{namespace="monitoring"}
```

### Filtrowanie treści

```logql
# Logi zawierające słowo "error"
{namespace="default"} |= "error"

# Logi NIE zawierające "debug"
{namespace="default"} != "debug"

# Regex - logi zawierające error lub ERROR
{namespace="default"} |~ "(?i)error"

# Logi z konkretnego kontenera
{namespace="default", container="nginx"}
```

### Zaawansowane zapytania

```logql
# Rate - liczba logów per sekunda
rate({namespace="default"}[5m])

# Count - ile logów w ostatnich 5 minutach
count_over_time({namespace="default"}[5m])

# Logi z błędami w ostatnich 5 minutach
{namespace="default"} |= "error" | line_format "{{.timestamp}} {{.message}}"

# Topk - top 5 podów z największą liczbą logów
topk(5, sum by (pod) (rate({namespace="default"}[5m])))
```

### Kombinacja z labelami Kubernetes

```logql
# Logi z określonego deployment
{namespace="default", app="nginx", container="nginx"}

# Logi z błędami z konkretnego node
{node_name="aks-nodepool1-33619919-vmss000000"} |= "error"

# Wszystkie logi z production namespace
{namespace=~"prod.*"}
```

---

## 🎨 Pierwsze kroki w Grafanie

### 1. Otwórz Explore

1. Zaloguj się do Grafany (http://localhost:3000)
2. Kliknij ikonę **Explore** (kompas) w lewym menu
3. Wybierz **Loki** z dropdown datasource

### 2. Testuj zapytania

**Przykład 1: Zobacz logi NGINX**
```logql
{app="nginx"}
```

**Przykład 2: Przefiltruj po błędach**
```logql
{namespace="default"} |= "error"
```

**Przykład 3: Live tail (streaming logów)**
- Kliknij **Live** w prawym górnym rogu
- Zapytanie będzie odświeżane w czasie rzeczywistym

### 3. Tworzenie dashboarda z logami

1. **Dashboards** → **New Dashboard** → **Add visualization**
2. Wybierz datasource: **Loki**
3. Wpisz zapytanie:
   ```logql
   sum by (pod) (rate({namespace="default"}[1m]))
   ```
4. Zmień typ wizualizacji na **Logs** lub **Time series**
5. Zapisz dashboard

---

## 🏷️ Jak działa labelowanie w Loki

### Automatyczne labele z Kubernetes

Promtail automatycznie dodaje labele z metadanych Kubernetes:

- `namespace` - namespace poda
- `pod` - nazwa poda
- `container` - nazwa kontenera
- `app` - label app z poda
- `job` - nazwa job
- `node_name` - węzeł gdzie działa pod

### Przykład logowania w aplikacji

```python
# Aplikacja loguje do stdout
print(f"[INFO] Request processed successfully")
print(f"[ERROR] Database connection failed")
```

Promtail zbiera to i dodaje labele:
```
{namespace="default", pod="my-app-123", container="app", app="my-app"} 
[INFO] Request processed successfully
```

---

## 🔧 Konfiguracja Promtail

### Sprawdź konfigurację Promtail

```bash
kubectl get configmap -n monitoring loki-promtail -o yaml
```

### Domyślna konfiguracja:
- Zbiera logi z `/var/log/pods/**/*.log`
- Dodaje labele Kubernetes
- Wysyła do Loki na `http://loki:3100`

---

## 🚨 Rozwiązywanie problemów

### Problem: Nie widzę logów w Grafanie

**Sprawdź:**

1. Czy Promtail działa?
   ```bash
   kubectl get pods -n monitoring -l app=promtail
   ```

2. Czy Promtail wysyła logi do Loki?
   ```bash
   kubectl logs -n monitoring -l app=promtail --tail=50
   ```

3. Czy Loki odbiera logi?
   ```bash
   kubectl logs -n monitoring loki-0 --tail=50
   ```

4. Czy datasource w Grafanie jest skonfigurowany?
   - Grafana → Configuration → Data sources → Loki
   - URL: `http://loki:3100`
   - Kliknij **Save & test**

### Problem: Promtail nie może połączyć się z Loki

```bash
# Sprawdź czy serwis Loki istnieje
kubectl get svc -n monitoring loki

# Test połączenia z Promtail
kubectl exec -n monitoring -it loki-promtail-XXXXX -- wget -O- http://loki:3100/ready
```

### Problem: Za dużo logów (performance)

**Rozwiązanie: Filtrowanie w Promtail**

Edytuj ConfigMap `loki-promtail` i dodaj pipeline stage:
```yaml
pipeline_stages:
  - match:
      selector: '{namespace="kube-system"}'
      action: drop
```

---

## 📊 Porównanie Loki vs ELK

| Feature | Loki | ELK Stack |
|---------|------|-----------|
| **Indeksowanie** | Tylko labele | Full-text index |
| **Zużycie zasobów** | Niskie | Wysokie |
| **Koszt storage** | Niski | Wysoki |
| **Szybkość zapytań** | Szybka (labele) | Bardzo szybka (full-text) |
| **Łatwość instalacji** | Prosta | Złożona |
| **Integracja z K8s** | Natywna | Wymaga konfiguracji |
| **Best for** | Cloud-native apps | Enterprise logging |

---

## 🎯 Przykładowe use cases

### Use Case 1: Debugging aplikacji

**Cel:** Znajdź błędy w aplikacji w ostatnich 15 minutach

```logql
{namespace="default", app="my-app"} |= "error" or "ERROR" or "exception"
```

W Grafanie:
1. Explore → Loki
2. Wklej zapytanie
3. Ustaw czas na **Last 15 minutes**
4. Kliknij **Run query**

### Use Case 2: Monitoring rate logów

**Cel:** Monitoruj ile logów produkuje każdy pod

Dashboard panel:
```logql
sum by (pod) (rate({namespace="default"}[5m]))
```

Vizualizacja: **Time series**

### Use Case 3: Alerting na podstawie logów

**Cel:** Alert gdy pojawi się "FATAL" w logach

W Grafanie:
1. Utwórz dashboard panel z zapytaniem:
   ```logql
   count_over_time({namespace="default"} |= "FATAL"[5m]) > 0
   ```
2. Dodaj alert rule
3. Skonfiguruj notification channel

---

## 📚 Składnia LogQL (cheat sheet)

### Selektory logów
```logql
{label="value"}           # Exact match
{label=~"regex"}          # Regex match
{label!="value"}          # Not equal
{label!~"regex"}          # Not regex match
{label1="val1",label2="val2"}  # AND
```

### Operatory filtrowania
```logql
|= "text"       # Zawiera
!= "text"       # Nie zawiera
|~ "regex"      # Regex match
!~ "regex"      # Regex not match
```

### Funkcje agregacji
```logql
rate()          # Rate per second
count_over_time()   # Count entries
sum()           # Sum
avg()           # Average
min() / max()   # Min/Max
topk()          # Top K entries
```

### Przykłady zaawansowane
```logql
# Parsed JSON logs
{app="api"} | json | status_code >= 500

# Extracted values
{app="nginx"} | pattern `<_> <method> <uri>` | method="POST"

# With functions
sum(rate({namespace="prod"}[5m])) by (pod)
```

---

## 🗑️ Deinstalacja

```bash
# Usuń Loki Stack
helm uninstall loki -n monitoring

# Usuń datasource z Grafany (opcjonalnie)
# Przywróć oryginalną ConfigMapę bez Loki

# Usuń pliki
rm -rf Kubernetes/Observability/Loki/
```

---

## 📖 Dodatkowe zasoby

- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/configuration/)
- [Best Practices](https://grafana.com/docs/loki/latest/best-practices/)
- [Loki vs ELK](https://grafana.com/docs/loki/latest/fundamentals/overview/)

---

**Data instalacji:** 24 października 2025  
**Wersja:** loki-stack (latest)  
**Integracja:** Z istniejącą Grafaną (prometheus-grafana)

