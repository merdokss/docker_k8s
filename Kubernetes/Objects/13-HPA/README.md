# Horizontal Pod Autoscaler (HPA) w Kubernetes

## Czym jest HPA?

Horizontal Pod Autoscaler to mechanizm w Kubernetes, który automatycznie skaluje liczbę podów w deployment, replication controller lub replica set na podstawie obserwowanego wykorzystania zasobów (np. CPU, pamięci) lub własnych metryk.

## Jak działa HPA?

1. HPA okresowo sprawdza metryki podów (domyślnie co 15 sekund)
2. Na podstawie zebranych metryk oblicza pożądaną liczbę replik
3. Dostosowuje liczbę replik w górę lub w dół w zależności od potrzeb
4. Uwzględnia minimalne i maksymalne limity replik określone w konfiguracji

## Przykładowa konfiguracja HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: example-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: example-deployment
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 50
```

## Wymagania

Aby HPA działał poprawnie, należy:

1. Mieć zainstalowany i skonfigurowany metrics-server w klastrze
2. Zdefiniować limity zasobów (resources) w podach
3. Prawidłowo skonfigurować metryki w HPA

## Przykłady użycia

W tym katalogu znajdziesz następujące przykłady:

1. `01-basic-cpu-memory/` - Podstawowy przykład skalowania na podstawie CPU i pamięci
2. `02-custom-metrics/` - Przykład skalowania na podstawie własnych metryk
3. `03-keda/` - Przykłady użycia KEDA do event-driven autoscaling

## Przydatne komendy

```bash
# Utworzenie HPA
kubectl apply -f hpa.yaml

# Sprawdzenie statusu HPA
kubectl get hpa
kubectl describe hpa example-hpa

# Monitorowanie metryk
kubectl top pods

# Usunięcie HPA
kubectl delete hpa example-hpa
```

## Dobre praktyki

1. Zawsze ustawiaj rozsądne limity minReplicas i maxReplicas
2. Ustaw odpowiednie progi skalowania (nie za niskie, nie za wysokie)
3. Monitoruj zachowanie HPA i dostosuj konfigurację w razie potrzeby
4. Pamiętaj o ustawieniu requests i limits dla zasobów w podach
5. Testuj skalowanie w środowisku testowym przed wdrożeniem na produkcję

---

## HPA z metrykami Prometheus (bez KEDA)

### Czy można użyć metryk Prometheus z zwykłym HPA?

**TAK!** Standardowy HPA może korzystać z metryk Prometheus, ale wymaga to dodatkowego komponentu - **Prometheus Adapter**.

### Jak to działa?

```
Prometheus → Prometheus Adapter → Custom Metrics API → HPA → Scaling
```

1. **Prometheus** zbiera metryki z aplikacji
2. **Prometheus Adapter** odpytuje Prometheus i eksponuje metryki przez Kubernetes Custom Metrics API
3. **HPA** używa Custom Metrics API do pobierania metryk
4. **HPA** skaluje deployment na podstawie metryk

### Instalacja Prometheus Adapter

```bash
# Dodaj Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Zainstaluj Prometheus Adapter
helm install prometheus-adapter prometheus-community/prometheus-adapter \
  --namespace monitoring \
  --set prometheus.url=http://prometheus-kube-prometheus-prometheus.monitoring.svc \
  --set prometheus.port=9090

# Sprawdź instalację
kubectl get pods -n monitoring | grep prometheus-adapter

# Sprawdź czy Custom Metrics API działa
kubectl get apiservices | grep custom.metrics
```

### Konfiguracja Prometheus Adapter

Prometheus Adapter potrzebuje konfiguracji jak mapować metryki Prometheus na Custom Metrics API:

```yaml
# prometheus-adapter-values.yaml
rules:
- seriesQuery: 'http_requests_total{namespace!="",pod!=""}'
  resources:
    overrides:
      namespace: {resource: "namespace"}
      pod: {resource: "pod"}
  name:
    matches: "^(.*)_total$"
    as: "${1}_per_second"
  metricsQuery: 'sum(rate(<<.Series>>{<<.LabelMatchers>>}[2m])) by (<<.GroupBy>>)'

- seriesQuery: 'application_queue_length{namespace!="",pod!=""}'
  resources:
    overrides:
      namespace: {resource: "namespace"}
      pod: {resource: "pod"}
  name:
    as: "queue_length"
  metricsQuery: 'avg(<<.Series>>{<<.LabelMatchers>>}) by (<<.GroupBy>>)'
```

Zaktualizuj instalację:

```bash
helm upgrade prometheus-adapter prometheus-community/prometheus-adapter \
  --namespace monitoring \
  -f prometheus-adapter-values.yaml
```

### Przykład HPA z Custom Metrics

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-custom-metrics
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 1
  maxReplicas: 10
  metrics:
  # Metryka z Prometheus przez Custom Metrics API
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "100"
  
  # Można łączyć z Resource metrics
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Weryfikacja metryk

```bash
# Lista dostępnych custom metrics
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1" | jq .

# Sprawdź konkretną metrykę
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/http_requests_per_second" | jq .

# Sprawdź HPA
kubectl describe hpa hpa-custom-metrics
```

### Prometheus Adapter vs KEDA - Porównanie

| Aspekt | Prometheus Adapter + HPA | KEDA |
|--------|--------------------------|------|
| **Instalacja** | Wymaga konfiguracji rules | Prosta - bez dodatkowej konfiguracji |
| **Konfiguracja metryk** | Skomplikowana - rules w YAML | Prosta - query w ScaledObject |
| **Elastyczność** | Tylko Prometheus | 60+ różnych źródeł |
| **Skalowanie do 0** | ❌ Nie (min 1) | ✅ Tak |
| **Maintenance** | Wymaga aktualizacji rules | Auto-skalowanie reguł |
| **Learning curve** | Stroma | Łagodna |
| **Use case** | Gdy już masz Prometheus i HPA | Event-driven workloads |

### Przykład kompletnej konfiguracji

#### 1. Aplikacja eksportująca metryki

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-metrics
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-with-metrics
  template:
    metadata:
      labels:
        app: app-with-metrics
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        image: my-app:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

#### 2. ServiceMonitor (dla Prometheus Operator)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app-monitor
spec:
  selector:
    matchLabels:
      app: app-with-metrics
  endpoints:
  - port: metrics
    interval: 15s
```

#### 3. Prometheus Adapter Rule

```yaml
rules:
- seriesQuery: 'http_requests_total{app="app-with-metrics"}'
  seriesFilters: []
  resources:
    template: <<.Resource>>
  name:
    matches: "^(.*)_total$"
    as: "${1}_per_second"
  metricsQuery: 'sum(rate(<<.Series>>{<<.LabelMatchers>>}[2m])) by (<<.GroupBy>>)'
```

#### 4. HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-with-metrics
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "50"
```

### Kiedy używać HPA + Prometheus Adapter?

✅ **Używaj gdy:**
- Już masz Prometheus w klastrze
- Potrzebujesz tylko metryk z Prometheus
- Nie potrzebujesz skalowania do 0
- Zespół zna już HPA

❌ **Rozważ KEDA gdy:**
- Potrzebujesz skalowania do 0
- Chcesz używać wielu źródeł zdarzeń (Kafka, RabbitMQ, etc.)
- Chcesz prostszą konfigurację
- Potrzebujesz event-driven architecture

### Troubleshooting

#### Problem: Custom metrics nie są widoczne

```bash
# Sprawdź logi Prometheus Adapter
kubectl logs -n monitoring -l app=prometheus-adapter

# Sprawdź konfigurację
kubectl get configmap -n monitoring prometheus-adapter -o yaml

# Test connectivity do Prometheus
kubectl exec -n monitoring -it <prometheus-adapter-pod> -- wget -qO- http://prometheus:9090/api/v1/query?query=up
```

#### Problem: HPA pokazuje "unknown" dla custom metric

```bash
# Sprawdź czy metryka istnieje w Custom Metrics API
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/your_metric_name" | jq .

# Sprawdź czy aplikacja eksportuje metryki
kubectl port-forward pod/<your-pod> 8080:8080
curl http://localhost:8080/metrics | grep your_metric

# Sprawdź czy Prometheus zbiera metryki
# W Prometheus UI: your_metric_name{pod="your-pod"}
```

### Zasoby

- [Prometheus Adapter GitHub](https://github.com/kubernetes-sigs/prometheus-adapter)
- [Prometheus Adapter Configuration](https://github.com/kubernetes-sigs/prometheus-adapter/blob/master/docs/config.md)
- [Custom Metrics API](https://github.com/kubernetes/metrics)

---

## KEDA - Kubernetes Event-Driven Autoscaling

### Czym jest KEDA?

KEDA (Kubernetes Event-Driven Autoscaler) to lekka, open-source'owa warstwa skalowania, która rozszerza możliwości standardowego HPA o skalowanie oparte na zdarzeniach. KEDA działa jako rozszerzenie Kubernetes i integruje się z natywnym HPA.

### Różnice między HPA a KEDA

| Cecha | HPA | KEDA |
|-------|-----|------|
| **Źródła metryk** | CPU, pamięć, custom metrics | 60+ różnych źródeł zdarzeń (message queues, databases, HTTP, cloud services) |
| **Skalowanie do zera** | ❌ Nie | ✅ Tak - może skalować do 0 replik |
| **Integracje** | Wymaga Prometheus Adapter dla custom metrics | Wbudowane skalery dla popularnych systemów |
| **Złożoność konfiguracji** | Średnia | Prosta - deklaratywna konfiguracja |
| **Use case** | Skalowanie oparte na zasobach systemowych | Event-driven workloads, kolejki, bazy danych |

### Kiedy używać KEDA?

KEDA jest idealny dla:

1. **Message-driven aplikacji** - skalowanie na podstawie liczby wiadomości w kolejce (RabbitMQ, Kafka, Azure Service Bus, AWS SQS)
2. **Scheduled jobs** - uruchamianie zadań o określonych porach (CRON trigger)
3. **HTTP-based workloads** - skalowanie na podstawie ruchu HTTP
4. **Database-driven workloads** - skalowanie na podstawie liczby rekordów w bazie
5. **Cloud-native aplikacji** - integracja z AWS, Azure, GCP metrics
6. **Cost optimization** - możliwość skalowania do zera gdy brak pracy

### Główne komponenty KEDA

1. **Scaler** - agent monitorujący źródło zdarzeń i dostarczający metryki
2. **ScaledObject** - główny zasób Kubernetes definiujący reguły skalowania dla Deployment/StatefulSet
3. **ScaledJob** - zasób do skalowania Kubernetes Jobs
4. **Metrics Server** - adapter metryk dla HPA

### Przykładowe źródła zdarzeń (Scalers)

KEDA wspiera ponad 60 różnych scalerów, w tym:

- **Message Queues**: RabbitMQ, Kafka, Azure Service Bus, AWS SQS, NATS, Redis
- **Databases**: PostgreSQL, MySQL, MongoDB, Redis, Prometheus
- **Cloud Providers**: Azure (Storage Queue, Event Hub, Blob), AWS (CloudWatch, SQS, DynamoDB), GCP (Pub/Sub)
- **HTTP**: HTTP requests, Kubernetes Ingress
- **Scheduled**: CRON triggers
- **Custom**: External metrics, Prometheus queries

### Instalacja KEDA

```bash
# Używając Helm
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda --namespace keda --create-namespace

# Lub używając YAML
kubectl apply --server-side -f https://github.com/kedacore/keda/releases/download/v2.12.0/keda-2.12.0.yaml
```

### Weryfikacja instalacji

```bash
# Sprawdź czy KEDA jest zainstalowana
kubectl get pods -n keda

# Powinieneś zobaczyć:
# - keda-operator
# - keda-operator-metrics-apiserver
```

### Podstawowy przykład użycia

Więcej przykładów znajdziesz w katalogu `03-keda/`.

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: rabbitmq-scaledobject
spec:
  scaleTargetRef:
    name: rabbitmq-consumer
  minReplicaCount: 0   # Może skalować do zera
  maxReplicaCount: 30
  triggers:
  - type: rabbitmq
    metadata:
      queueName: test-queue
      queueLength: "5"
      host: amqp://guest:guest@rabbitmq.default.svc.cluster.local:5672
```

### Przydatne komendy KEDA

```bash
# Lista ScaledObjects
kubectl get scaledobjects
kubectl get so

# Szczegóły ScaledObject
kubectl describe scaledobject <name>

# Lista ScaledJobs
kubectl get scaledjobs
kubectl get sj

# Sprawdzenie HPA utworzonego przez KEDA
kubectl get hpa

# Logi KEDA operator
kubectl logs -n keda -l app=keda-operator
```

### Korzyści z używania KEDA

1. ✅ **Skalowanie do zera** - oszczędność zasobów gdy brak pracy
2. ✅ **Prostota** - deklaratywna konfiguracja bez potrzeby dodatkowych adapterów
3. ✅ **Bogaty ekosystem** - 60+ gotowych integracji
4. ✅ **Event-driven** - reaguje na rzeczywiste zdarzenia biznesowe
5. ✅ **Cloud-native** - native integracja z dostawcami chmury
6. ✅ **Open source** - wspierane przez CNCF (Cloud Native Computing Foundation)

### Linki i zasoby

- [Oficjalna dokumentacja KEDA](https://keda.sh)
- [Lista wszystkich scalerów](https://keda.sh/docs/scalers/)
- [GitHub KEDA](https://github.com/kedacore/keda)
- [Przykłady użycia](https://github.com/kedacore/samples)
