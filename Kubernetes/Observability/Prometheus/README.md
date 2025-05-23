# Prometheus w Kubernetes

## Wprowadzenie

Prometheus to system monitorowania i alertowania typu open-source, zaprojektowany specjalnie dla środowisk konteneryzowanych. Jest to kluczowy element w monitorowaniu aplikacji działających w Kubernetes.

## Komponenty Prometheus Operator

Prometheus Operator składa się z następujących głównych komponentów:

### 1. Operator
- Główny komponent zarządzający
- Implementuje Custom Resource Definitions (CRDs)
- Automatycznie konfiguruje i zarządza zasobami Prometheusa
- Obsługuje aktualizacje i skalowanie

### 2. Custom Resource Definitions (CRDs)
- **Prometheus**: definiuje instancje Prometheusa
- **ServiceMonitor**: konfiguruje monitorowanie serwisów
- **PodMonitor**: konfiguruje monitorowanie podów
- **AlertmanagerConfig**: konfiguruje reguły alertów
- **Probe**: definiuje sondy do monitorowania zewnętrznych endpointów
- **ThanosRuler**: integracja z Thanos dla długoterminowego przechowywania danych

### 3. Prometheus Server
- Zbiera i przechowuje metryki
- Wykonuje zapytania PromQL
- Generuje alerty
- Integruje się z Alertmanagerem

### 4. Alertmanager
- Zarządza alertami
- Grupuje i deduplikuje powiadomienia
- Wysyła powiadomienia do różnych kanałów (email, Slack, PagerDuty)
- Implementuje polityki routingu alertów

### 5. Grafana (opcjonalnie)
- Wizualizacja metryk
- Tworzenie dashboardów
- Integracja z Prometheusem
- Zaawansowane możliwości wizualizacji

### 6. Node Exporter
- Zbiera metryki z węzłów Kubernetes
- Monitoruje zasoby systemowe
- Dostarcza metryki o CPU, pamięci, dyskach i sieci

### 7. Kube State Metrics
- Eksportuje metryki o stanie obiektów Kubernetes
- Monitoruje zasoby klastra
- Dostarcza informacje o podach, serwisach, deploymentach

### 8. Prometheus Adapter
- Implementuje Custom Metrics API
- Umożliwia skalowanie HPA na podstawie metryk Prometheusa
- Konwertuje metryki Prometheusa do formatu Kubernetes

## Metody instalacji

### 1. Prometheus Operator (Zalecane)

#### Wymagania wstępne
- Kubernetes cluster (v1.16+)
- kubectl
- Helm 3

#### Instalacja
```bash
# Dodaj repozytorium
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Zainstaluj Prometheus Operator
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

### 2. Helm Chart (Szybka instalacja)

```bash
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --create-namespace
```

### 3. Ręczna instalacja

Ręczna instalacja wymaga utworzenia następujących zasobów:
- ConfigMap dla konfiguracji
- Deployment dla Prometheusa
- Service dla dostępu
- RBAC (Role, RoleBinding, ServiceAccount)

## Konfiguracja

### ServiceMonitor
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: example-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: example-app
  endpoints:
  - port: metrics
```

### PodMonitor
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: example-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: example-app
  podMetricsEndpoints:
  - port: metrics
```

## Dostęp do interfejsu

```bash
# Port-forward do interfejsu Prometheusa
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
```

## Przydatne komendy

```bash
# Sprawdź status podów
kubectl get pods -n monitoring

# Sprawdź konfigurację Prometheusa
kubectl get prometheus -n monitoring

# Sprawdź ServiceMonitors
kubectl get servicemonitors -n monitoring

# Sprawdź reguły
kubectl get prometheusrules -n monitoring
```

## Porównanie metod instalacji

### Prometheus Operator
- ✅ Automatyczne zarządzanie zasobami
- ✅ CRD dla ServiceMonitor i PodMonitor
- ✅ Łatwe zarządzanie regułami
- ✅ Automatyczne wykrywanie usług
- ❌ Większe zużycie zasobów
- ❌ Bardziej złożona konfiguracja

### Helm Chart
- ✅ Szybka instalacja
- ✅ Podstawowa konfiguracja
- ✅ Łatwe aktualizacje
- ❌ Mniej elastyczna
- ❌ Ograniczona konfiguracja

### Ręczna instalacja
- ✅ Pełna kontrola
- ✅ Mniejsze zużycie zasobów
- ❌ Czasochłonna
- ❌ Trudna w utrzymaniu

## Rekomendacje

- **Produkcja**: Prometheus Operator
- **Testy**: Helm Chart
- **Specjalne przypadki**: Ręczna instalacja

## Monitoring aplikacji

### Wymagania dla aplikacji
1. Endpoint `/metrics` zwracający metryki w formacie Prometheus
2. Odpowiednie etykiety na serwisach i podach
3. Skonfigurowany ServiceMonitor lub PodMonitor

### Przykładowa konfiguracja aplikacji
```yaml
apiVersion: v1
kind: Service
metadata:
  name: example-app
  labels:
    app: example-app
spec:
  ports:
  - name: metrics
    port: 8080
  selector:
    app: example-app
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: example-app
spec:
  selector:
    matchLabels:
      app: example-app
  endpoints:
  - port: metrics
```

## Rozwiązywanie problemów

### Typowe problemy
1. Brak dostępu do metryk
   - Sprawdź etykiety na serwisach
   - Zweryfikuj konfigurację ServiceMonitor
   - Sprawdź logi Prometheusa

2. Problemy z RBAC
   - Sprawdź uprawnienia ServiceAccount
   - Zweryfikuj Role i RoleBinding

3. Problemy z konfiguracją
   - Sprawdź ConfigMap
   - Zweryfikuj reguły Prometheusa

### Przydatne komendy diagnostyczne
```bash
# Sprawdź logi Prometheusa
kubectl logs -n monitoring -l app=prometheus

# Sprawdź status endpointów
kubectl get endpoints -n monitoring

# Sprawdź konfigurację
kubectl get configmap -n monitoring
``` 