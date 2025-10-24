# ✅ Upgrade Loki do wersji 3.5.7 - WYKONANY

## 📊 Podsumowanie upgrade'u

**Data:** 24 października 2025, 15:10  
**Wersja przed:** Loki v2.9.3 (loki-stack chart 2.10.2)  
**Wersja po:** Loki v3.5.7 (loki chart 6.44.0)  
**Tryb wdrożenia:** SingleBinary

---

## 🎯 Cel upgrade'u

**Włączenie `volume_enabled: true` w limits_config**

To ustawienie pozwala na korzystanie z Volume API w Loki, co umożliwia:
- Zapytania o wolumen logów w Grafanie
- Lepszą wizualizację przepustowości logowania
- Bardziej zaawansowane analizy w Grafana Explore

---

## 🚀 Wykonane kroki

### 1. Przygotowanie konfiguracji

**Plik:** `loki-upgrade-values.yaml`

Kluczowe ustawienia:
```yaml
deploymentMode: SingleBinary

loki:
  auth_enabled: false
  
  limits_config:
    max_entries_limit_per_query: 5000
    reject_old_samples: true
    reject_old_samples_max_age: 168h
    volume_enabled: true  # <-- WŁĄCZONE!
  
  storage:
    type: 'filesystem'
    filesystem:
      chunks_directory: /var/loki/chunks
      rules_directory: /var/loki/rules

singleBinary:
  replicas: 1
  persistence:
    enabled: true
    size: 10Gi
```

**Plik:** `promtail-values.yaml`

```yaml
config:
  clients:
    - url: http://loki:3100/loki/api/v1/push
  
  scrape_configs:
    - job_name: kubernetes-pods
      # Automatyczne zbieranie logów ze wszystkich podów
```

### 2. Odinstalowanie starego Loki

```bash
helm uninstall loki -n monitoring
```

**Uwaga:** To usunęło również stary Promtail.

### 3. Instalacja nowego Loki v3

```bash
helm install loki grafana/loki \
  --namespace monitoring \
  --version 6.44.0 \
  -f Kubernetes/Observability/Loki/loki-upgrade-values.yaml
```

**Rezultat:**
- ✅ Loki v3.5.7 zainstalowany
- ✅ SingleBinary mode (1 pod)
- ✅ Persistence włączone (10Gi)
- ✅ `volume_enabled: true` w konfiguracji

### 4. Napotkane problemy i rozwiązania

#### Problem 1: `enforce_metric_name` nie jest obsługiwane w v3

**Błąd:**
```
field enforce_metric_name not found in type validation.plain
```

**Rozwiązanie:**  
Usunięto `enforce_metric_name` z `limits_config` - to pole zostało usunięte w Loki v3.

#### Problem 2: Promtail wysyłał do złego URL

**Błąd:**
```
lookup loki-v3 on 10.0.0.10:53: no such host
```

**Rozwiązanie:**  
Poprawiono URL w `promtail-values.yaml` z `loki-v3` na `loki`.

### 5. Instalacja Promtail

```bash
helm install promtail grafana/promtail \
  --namespace monitoring \
  -f Kubernetes/Observability/Loki/promtail-values.yaml
```

**Rezultat:**
- ✅ Promtail v3.5.1 zainstalowany
- ✅ DaemonSet na wszystkich node'ach
- ✅ Wysyła logi do `http://loki:3100`

### 6. Aktualizacja datasource w Grafanie

Datasource już był poprawnie skonfigurowany:
```yaml
- name: "Loki"
  type: loki
  uid: loki
  url: http://loki:3100
  access: proxy
  isDefault: false
  editable: true
```

Zrestartowano Grafanę:
```bash
kubectl rollout restart deployment -n monitoring prometheus-grafana
```

---

## 📦 Zainstalowane komponenty

### Loki

```bash
kubectl get pods -n monitoring | grep loki
```

- **loki-0** (2/2 Running) - główny pod Loki
  - Kontener `loki` - serwer Loki
  - Kontener `loki-sc-rules` - sidecar do syncowania rules
- **loki-canary-*** - canary pody do testowania
- **loki-results-cache-0** - cache dla wyników zapytań
- **loki-chunks-cache-0** - cache dla chunks

### Promtail

```bash
kubectl get daemonset -n monitoring promtail
```

- **promtail** - DaemonSet zbierający logi z wszystkich node'ów
- ~6 podów (jeden na każdy node)

---

## ✅ Weryfikacja

### Sprawdzenie statusu Loki

```bash
# Status poda
kubectl get pods -n monitoring loki-0

# Readiness
kubectl run test-curl --image=curlimages/curl:latest --rm -it --restart=Never -- \
  curl -s http://loki.monitoring:3100/ready

# Powinno zwrócić: ready
```

### Sprawdzenie czy Promtail wysyła logi

```bash
# Logi Promtail
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=50

# Nie powinno być błędów "lookup loki-v3"
```

### Sprawdzenie w Grafanie

1. Otwórz Grafanę: http://localhost:3000 (admin / prom-operator)
2. Przejdź do **Explore**
3. Wybierz datasource **Loki**
4. Wpisz zapytanie:
   ```logql
   {namespace=~".+"}
   ```
5. Logi powinny się wyświetlać!

### Test Volume API

W Grafanie, w Explore z datasource Loki, powinny być dostępne zaawansowane opcje volume:

```logql
# Zapytanie o volume (wymaga volume_enabled: true)
sum by (namespace) (
  bytes_over_time({namespace=~".+"}[5m])
)
```

---

## 🔧 Konfiguracja

### Loki Values

**Plik:** `Kubernetes/Observability/Loki/loki-upgrade-values.yaml`

Najważniejsze ustawienia:
- `deploymentMode: SingleBinary` - prosty tryb, jeden pod
- `limits_config.volume_enabled: true` - **GŁÓWNY CEL UPGRADE'U**
- `singleBinary.persistence.enabled: true` - dane przetrwają restart
- `singleBinary.persistence.size: 10Gi` - 10GB na logi

### Promtail Values

**Plik:** `Kubernetes/Observability/Loki/promtail-values.yaml`

Najważniejsze ustawienia:
- `clients[0].url: http://loki:3100/loki/api/v1/push` - endpoint Loki
- `scrape_configs[0].job_name: kubernetes-pods` - zbiera wszystkie pody
- Automatyczne labeling z Kubernetes metadata

---

## 📊 Porównanie: Loki v2.9.3 vs v3.5.7

| Feature | v2.9.3 (loki-stack) | v3.5.7 (loki) |
|---------|---------------------|---------------|
| **Chart** | loki-stack 2.10.2 | loki 6.44.0 |
| **Volume API** | ❌ Nie obsługiwane | ✅ Obsługiwane |
| **`enforce_metric_name`** | ✅ Obsługiwane | ❌ Usunięte |
| **Deployment Modes** | Tylko monolith | SingleBinary, SimpleScalable, Distributed |
| **Persistence** | Opcjonalne | Zalecane (włączone) |
| **Canary** | Brak | ✅ Włączone domyślnie |
| **Cache** | Brak | ✅ Results + Chunks cache |

---

## 🗂️ Pliki konfiguracyjne

```
Kubernetes/Observability/Loki/
├── README.md                           # Pełna dokumentacja Loki
├── INSTALACJA.md                       # Instrukcja instalacji (stara wersja)
├── UPGRADE-LOKI-V3.md                  # Ten plik
├── loki-upgrade-values.yaml            # Values dla Loki v3 ✨
├── promtail-values.yaml                # Values dla Promtail ✨
├── update-grafana-datasources.yaml     # Datasource w Grafanie
└── loki-datasource.yaml                # (legacy - nieużywane)
```

---

## 🔄 Przywracanie poprzedniej wersji (rollback)

Jeśli coś pójdzie nie tak, możesz wrócić do poprzedniej wersji:

```bash
# 1. Odinstaluj nowy Loki i Promtail
helm uninstall loki -n monitoring
helm uninstall promtail -n monitoring

# 2. Zainstaluj stary loki-stack
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --version 2.10.2 \
  --set grafana.enabled=false \
  --set prometheus.enabled=false \
  --set promtail.enabled=true

# 3. Restart Grafany
kubectl rollout restart deployment -n monitoring prometheus-grafana
```

**UWAGA:** Stracisz logi zebrane przez nowy Loki!

---

## 📝 Przykładowe zapytania LogQL z Volume API

### Wolumen logów per namespace

```logql
sum by (namespace) (
  bytes_over_time({namespace=~".+"}[5m])
)
```

### Top 5 namespace'ów generujących najwięcej logów

```logql
topk(5, 
  sum by (namespace) (
    bytes_over_time({namespace=~".+"}[1h])
  )
)
```

### Rate logów per pod

```logql
sum by (pod) (
  rate({namespace="default"}[5m])
)
```

### Wszystkie logi z błędami

```logql
{namespace=~".+"} |~ "(?i)(error|exception|fatal)"
```

---

## 🚨 Znane problemy

### 1. "too many unhealthy instances in the ring"

**Przyczyna:** Loki się jeszcze stabilizuje po uruchomieniu.

**Rozwiązanie:** Poczekaj 1-2 minuty, problem zniknie automatycznie.

### 2. Promtail nie wysyła logów

**Sprawdź:**
```bash
# URL w konfiguracji
kubectl get secret -n monitoring promtail -o jsonpath='{.data.promtail\.yaml}' | base64 -d | grep url

# Powinno być: http://loki:3100/loki/api/v1/push
```

### 3. Chunks cache Pending

**Przyczyna:** Brak storage class lub PVC nie może być utworzone.

**Rozwiązanie:** Wyłącz chunks cache w values jeśli nie potrzebujesz:
```yaml
chunksCache:
  enabled: false
```

---

## 📖 Przydatne komendy

```bash
# Status wszystkich komponentów Loki
kubectl get all -n monitoring -l app.kubernetes.io/name=loki

# Status Promtail
kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail

# Logi Loki
kubectl logs -n monitoring loki-0 -c loki --tail=50

# Logi Promtail
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=50

# Test API Loki
kubectl port-forward -n monitoring svc/loki 3100:3100
curl http://localhost:3100/ready

# Lista release'ów Helm
helm list -n monitoring

# Values używane przy instalacji
helm get values loki -n monitoring
helm get values promtail -n monitoring
```

---

## 🎉 Rezultat

✅ **Loki v3.5.7 zainstalowany i działa!**  
✅ **`volume_enabled: true` - włączone!**  
✅ **Promtail zbiera logi ze wszystkich podów**  
✅ **Grafana połączona z nowym Loki**  
✅ **Volume API dostępne w zapytaniach LogQL**

---

**Autor:** AI Assistant  
**Data:** 24 października 2025

