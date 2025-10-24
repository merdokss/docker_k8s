# Prometheus - Wartości instalacji Helm

## 📋 Podsumowanie instalacji

**Release:** `prometheus`  
**Namespace:** `monitoring`  
**Chart:** `kube-prometheus-stack-78.4.0`  
**App Version:** `v0.86.1`  
**Data instalacji:** 24 października 2025, 07:15

---

## ⚙️ Sposób instalacji

```bash
# Prometheus został zainstalowany z domyślnymi wartościami:
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

**Uwaga:** Instalacja nie użyła żadnych custom values (`USER-SUPPLIED VALUES: null`), co oznacza, że używane są **domyślne wartości z chart'u**.

---

## 📁 Pliki z wartościami

### 1. User-supplied values (wartości podane przy instalacji)
```yaml
# BRAK - użyto domyślnych wartości
null
```

### 2. Pełne wartości (computed values)
Plik: `prometheus-values-full.yaml` (2537 linii)

Ten plik zawiera wszystkie wartości używane przez Prometheus, łącznie z domyślnymi z chart'u.

---

## 🔑 Najważniejsze komponenty zainstalowane

### 1. **Prometheus Server**
- **Repliki:** 1
- **Storage:** Domyślne (emptyDir lub PVC w zależności od konfiguracji)
- **Retention:** 10 dni (domyślnie)
- **Image:** `quay.io/prometheus/prometheus:v2.55.1`

### 2. **Grafana**
- **Enabled:** `true` (domyślnie)
- **Datasources:** Prometheus (automatycznie skonfigurowany)
- **Admin password:** `prom-operator` (domyślne)
- **Service Type:** ClusterIP

### 3. **Alertmanager**
- **Repliki:** 1
- **Retention:** 120h
- **Config:** Domyślna konfiguracja z basic routing

### 4. **Node Exporter**
- **DaemonSet:** Zbiera metryki z każdego node'a
- **Enabled:** `true`

### 5. **Kube State Metrics**
- **Enabled:** `true`
- **Zbiera metryki o stanie zasobów Kubernetes**

### 6. **Prometheus Operator**
- **Enabled:** `true`
- **Zarządza CustomResourceDefinitions (CRDs)**

---

## 📊 Domyślne Service Monitors

Chart automatycznie tworzy Service Monitors dla:

- ✅ **apiserver** - Kubernetes API Server
- ✅ **kubelet** - Kubelet metrics
- ✅ **kube-state-metrics** - Stan zasobów K8s
- ✅ **node-exporter** - Metryki node'ów
- ✅ **prometheus-operator** - Operator metrics
- ✅ **prometheus** - Sam Prometheus
- ✅ **alertmanager** - Alertmanager metrics
- ✅ **grafana** - Grafana metrics

---

## 🔐 Dostęp do komponentów

### Prometheus UI
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# http://localhost:9090
```

### Grafana
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# http://localhost:3000
# Login: admin / Hasło: prom-operator
```

### Alertmanager
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
# http://localhost:9093
```

---

## 🎯 Najważniejsze wartości domyślne

### Prometheus Server
```yaml
prometheus:
  prometheusSpec:
    replicas: 1
    retention: 10d
    retentionSize: ""
    storageSpec: {}  # Używa domyślnego storage
    resources: {}    # Bez limitów
    nodeSelector: {}
    tolerations: []
```

### Grafana
```yaml
grafana:
  enabled: true
  adminPassword: prom-operator
  persistence:
    enabled: false  # Bez persistence
  service:
    type: ClusterIP
    port: 80
```

### Alertmanager
```yaml
alertmanager:
  alertmanagerSpec:
    replicas: 1
    retention: 120h
    storage: {}
    resources: {}
```

---

## 🔄 Jak zaktualizować wartości

### Metoda 1: Upgrade z nowymi wartościami

```bash
# Stwórz plik custom-values.yaml z własnymi wartościami
cat > custom-values.yaml <<EOF
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
grafana:
  adminPassword: "mojeSuperHaslo123"
  persistence:
    enabled: true
    size: 10Gi
EOF

# Upgrade instalacji
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f custom-values.yaml
```

### Metoda 2: Upgrade z inline wartościami

```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.retention=30d \
  --set grafana.adminPassword=noweHaslo
```

---

## 📖 Jak zobaczyć aktualnie używane wartości

### Tylko user-supplied values
```bash
helm get values prometheus -n monitoring
```

### Wszystkie wartości (domyślne + custom)
```bash
helm get values prometheus -n monitoring --all > prometheus-all-values.yaml
```

### Manifest (deployed resources)
```bash
helm get manifest prometheus -n monitoring > prometheus-manifest.yaml
```

---

## 🔍 Sprawdzanie konfiguracji po instalacji

### Status release'u
```bash
helm status prometheus -n monitoring
```

### Lista zainstalowanych zasobów
```bash
kubectl get all -n monitoring -l release=prometheus
```

### CRDs zainstalowane przez operator
```bash
kubectl get crd | grep monitoring.coreos.com
```

Powinno pokazać:
- `prometheuses.monitoring.coreos.com`
- `prometheusrules.monitoring.coreos.com`
- `servicemonitors.monitoring.coreos.com`
- `podmonitors.monitoring.coreos.com`
- `alertmanagers.monitoring.coreos.com`

---

## 💡 Przykłady customizacji

### Włączenie persistence dla Prometheus
```yaml
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
          storageClassName: managed-csi  # Azure disk
```

### Zwiększenie retention
```yaml
prometheus:
  prometheusSpec:
    retention: 30d
    retentionSize: "45GB"
```

### Dodanie resource limits
```yaml
prometheus:
  prometheusSpec:
    resources:
      requests:
        memory: 2Gi
        cpu: 500m
      limits:
        memory: 4Gi
        cpu: 2000m
```

### Zmiana hasła Grafany
```yaml
grafana:
  adminPassword: "noweSuperbezpieczneHaslo123!"
```

### Włączenie persistence dla Grafany
```yaml
grafana:
  persistence:
    enabled: true
    storageClassName: managed-csi
    size: 10Gi
```

---

## 🚨 Ważne uwagi

1. **Brak custom values** - Obecna instalacja używa 100% domyślnych wartości z chart'u
2. **Brak persistence** - Dane Prometheusa i Grafany są volatile (zostaną utracone przy restarcie podów)
3. **Domyślne hasło** - Grafana używa domyślnego hasła `prom-operator`
4. **Single replica** - Prometheus i Alertmanager działają w single-instance (brak HA)
5. **Brak resource limits** - Pody nie mają ustawionych limitów CPU/memory

---

## 📚 Przydatne komendy

```bash
# Sprawdź wersję chart'u
helm list -n monitoring

# Zobacz historię upgradów
helm history prometheus -n monitoring

# Rollback do poprzedniej wersji
helm rollback prometheus -n monitoring

# Usuń release (UWAGA: traci dane!)
helm uninstall prometheus -n monitoring

# Eksportuj wszystkie wartości do pliku
helm get values prometheus -n monitoring --all > my-prometheus-values.yaml
```

---

## 🔗 Dodatkowe zasoby

- [Kube Prometheus Stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

**Wygenerowano:** 24 października 2025  
**Pełne wartości:** Zobacz `prometheus-values-full.yaml` (2537 linii)

