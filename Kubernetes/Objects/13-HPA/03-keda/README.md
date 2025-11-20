# KEDA - Kubernetes Event-Driven Autoscaling - Przykłady

## Spis treści

Ten katalog zawiera praktyczne przykłady użycia KEDA w różnych scenariuszach:

1. **01-rabbitmq/** - Skalowanie na podstawie kolejki RabbitMQ
2. **02-cron/** - Skalowanie według harmonogramu CRON
3. **03-kafka/** - Skalowanie na podstawie konsumpcji z Kafka
4. **04-prometheus/** - Skalowanie na podstawie metryk Prometheus

## Wymagania wstępne

Przed uruchomieniem przykładów upewnij się, że:

1. Masz działający klaster Kubernetes (lokalny lub chmurowy)
2. Zainstalowano KEDA w klastrze
3. kubectl jest skonfigurowany i połączony z klastrem

## Instalacja KEDA

### Metoda 1: Helm (zalecana)

```bash
# Dodaj repozytorium Helm
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

# Zainstaluj KEDA
helm install keda kedacore/keda --namespace keda --create-namespace

# Weryfikacja instalacji
kubectl get pods -n keda
```

### Metoda 2: YAML

```bash
# Zainstaluj najnowszą wersję KEDA
kubectl apply --server-side -f https://github.com/kedacore/keda/releases/download/v2.12.0/keda-2.12.0.yaml

# Sprawdź status
kubectl get pods -n keda
```

## Weryfikacja instalacji

Po instalacji powinieneś zobaczyć następujące pody:

```bash
kubectl get pods -n keda

# Oczekiwany wynik:
# NAME                                               READY   STATUS    RESTARTS   AGE
# keda-operator-xxxxxxxxxx-xxxxx                     1/1     Running   0          1m
# keda-operator-metrics-apiserver-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
```

Sprawdź czy API KEDA jest dostępne:

```bash
kubectl api-resources | grep keda

# Powinieneś zobaczyć:
# scaledjobs          sj        keda.sh/v1alpha1     true    ScaledJob
# scaledobjects       so        keda.sh/v1alpha1     true    ScaledObject
# triggerauthentications  ta    keda.sh/v1alpha1     true    TriggerAuthentication
```

## Kluczowe koncepcje KEDA

### ScaledObject

`ScaledObject` jest głównym zasobem KEDA. Definiuje:
- Cel skalowania (Deployment/StatefulSet)
- Źródła zdarzeń (triggers)
- Minimalna i maksymalna liczba replik
- Polityki skalowania

### ScaledJob

`ScaledJob` służy do skalowania Kubernetes Jobs na podstawie zdarzeń.

### TriggerAuthentication

`TriggerAuthentication` przechowuje dane uwierzytelniające dla źródeł zdarzeń (np. connection strings, API keys).

## Podstawowa struktura ScaledObject

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: my-scaledobject
  namespace: default
spec:
  scaleTargetRef:
    name: my-deployment          # Deployment do skalowania
  minReplicaCount: 0             # Może być 0!
  maxReplicaCount: 10
  pollingInterval: 30            # Jak często sprawdzać metryki (sekundy)
  cooldownPeriod: 300            # Czas oczekiwania przed skalowaniem w dół (sekundy)
  triggers:
  - type: rabbitmq               # Typ scalera
    metadata:
      queueName: my-queue
      queueLength: "5"
```

## Najważniejsze parametry

### pollingInterval

Jak często KEDA sprawdza źródło zdarzeń (domyślnie: 30 sekund)

### cooldownPeriod

Czas oczekiwania po ostatnim zdarzeniu przed skalowaniem do minReplicas (domyślnie: 300 sekund)

### minReplicaCount

Minimalna liczba replik (może być 0 dla KEDA!)

### maxReplicaCount

Maksymalna liczba replik

## Przydatne komendy

```bash
# Lista wszystkich ScaledObjects
kubectl get scaledobjects
kubectl get so

# Szczegóły ScaledObject
kubectl describe scaledobject <name>

# Lista ScaledJobs
kubectl get scaledjobs
kubectl get sj

# Sprawdź HPA utworzone przez KEDA
kubectl get hpa

# Logi KEDA operator
kubectl logs -n keda -l app=keda-operator -f

# Logi metrics server
kubectl logs -n keda -l app=keda-operator-metrics-apiserver -f

# Sprawdź metryki KEDA
kubectl get --raw /apis/external.metrics.k8s.io/v1beta1

# Usuń KEDA
helm uninstall keda -n keda
# lub
kubectl delete -f https://github.com/kedacore/keda/releases/download/v2.12.0/keda-2.12.0.yaml
```

## Debugowanie

### Sprawdzanie statusu ScaledObject

```bash
kubectl describe scaledobject <name>

# Sprawdź sekcję Events i Conditions
```

### Problemy z metrykami

```bash
# Sprawdź czy metrics server KEDA działa
kubectl get pods -n keda

# Sprawdź logi
kubectl logs -n keda -l app=keda-operator-metrics-apiserver

# Sprawdź czy external metrics są dostępne
kubectl get apiservices | grep external.metrics
```

### Problemy ze skalowaniem

```bash
# Sprawdź czy HPA jest utworzony
kubectl get hpa

# Sprawdź status HPA
kubectl describe hpa keda-hpa-<scaledobject-name>

# Sprawdź logi KEDA operator
kubectl logs -n keda -l app=keda-operator --tail=50
```

## Różnice między KEDA a standardowym HPA

| Funkcjonalność | KEDA | Standardowy HPA |
|----------------|------|-----------------|
| Skalowanie do 0 | ✅ Tak | ❌ Nie (min 1) |
| Źródła metryk | 60+ wbudowanych scalerów | CPU, Memory, Custom metrics (wymaga adaptera) |
| Konfiguracja | Prosta, deklaratywna | Wymaga dodatkowych komponentów dla custom metrics |
| Event-driven | ✅ Natywnie | ❌ Wymaga workaroundów |
| Integracje | Wbudowane dla popularnych systemów | Wymaga ręcznej konfiguracji |
| Skalowanie Jobs | ✅ ScaledJob | ❌ Nie wspiera |

## Przykładowe przypadki użycia

### 1. Queue-based processing (RabbitMQ, Kafka, SQS)

Skaluj workers na podstawie liczby wiadomości w kolejce.

**Zalety:**
- Automatyczne skalowanie do 0 gdy brak wiadomości
- Szybka reakcja na wzrost ruchu
- Oszczędność zasobów

**Przykład:** Zobacz `01-rabbitmq/`

### 2. Scheduled workloads (CRON)

Uruchamiaj workloads o określonych porach.

**Zalety:**
- Idealne dla scheduled jobs
- Automatyczne zarządzanie cyklem życia
- Zero replik poza harmonogramem

**Przykład:** Zobacz `02-cron/`

### 3. Stream processing (Kafka)

Skaluj konsumentów Kafka na podstawie lag.

**Zalety:**
- Automatyczna optymalizacja przepustowości
- Redukcja lag w czasie wysokiego obciążenia
- Efektywne wykorzystanie zasobów

**Przykład:** Zobacz `03-kafka/`

### 4. Custom metrics (Prometheus)

Skaluj na podstawie dowolnych metryk biznesowych.

**Zalety:**
- Pełna kontrola nad metrykami skalowania
- Integracja z istniejącym monitoringiem
- Skalowanie oparte na rzeczywistych potrzebach biznesowych

**Przykład:** Zobacz `04-prometheus/`

## Best Practices

1. **Zawsze testuj skalowanie w środowisku testowym** przed wdrożeniem na produkcję
2. **Ustaw rozsądne limity** minReplicaCount i maxReplicaCount
3. **Monitoruj koszty** - skalowanie do większej liczby replik = większe koszty
4. **Używaj pollingInterval odpowiedniego do Twojego przypadku**
   - Krótszy dla szybkiej reakcji (np. 10s)
   - Dłuższy dla oszczędności zasobów (np. 60s)
5. **Skonfiguruj cooldownPeriod** aby uniknąć "flapping" (częstego skalowania w górę i w dół)
6. **Używaj TriggerAuthentication** dla bezpiecznego przechowywania credentials
7. **Monitoruj metryki KEDA** używając Prometheus/Grafana
8. **Ustaw resource limits** na Deployments które skalujesz

## Monitoring KEDA

KEDA eksportuje metryki Prometheus:

```yaml
# ServiceMonitor dla KEDA (jeśli używasz Prometheus Operator)
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: keda
  namespace: keda
spec:
  selector:
    matchLabels:
      app: keda-operator
  endpoints:
  - port: metrics
    interval: 30s
```

Kluczowe metryki:
- `keda_scaler_errors_total` - błędy scalerów
- `keda_scaled_object_errors` - błędy ScaledObjects
- `keda_scaler_metrics_value` - wartości metryk z scalerów
- `keda_scaled_object_paused` - wstrzymane ScaledObjects

## Zasoby i linki

- [Oficjalna dokumentacja KEDA](https://keda.sh)
- [Lista wszystkich scalerów (60+)](https://keda.sh/docs/2.12/scalers/)
- [GitHub KEDA](https://github.com/kedacore/keda)
- [Przykłady społeczności](https://github.com/kedacore/samples)
- [KEDA FAQ](https://keda.sh/docs/2.12/faq/)
- [Troubleshooting Guide](https://keda.sh/docs/2.12/troubleshooting/)

## Wsparcie i społeczność

- [KEDA Slack](https://kubernetes.slack.com/messages/keda)
- [GitHub Issues](https://github.com/kedacore/keda/issues)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/keda)

## Co dalej?

Przejdź do przykładów w podkatalogach aby zobaczyć konkretne implementacje KEDA w działaniu!

