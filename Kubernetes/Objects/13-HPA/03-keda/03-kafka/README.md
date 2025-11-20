# KEDA z Kafka - Przykład skalowania konsumentów Kafka

Ten przykład pokazuje jak używać KEDA do automatycznego skalowania konsumentów Kafka na podstawie consumer lag.

## Opis scenariusza

- Aplikacja konsumująca wiadomości z topicu Kafka
- KEDA monitoruje consumer lag (opóźnienie w przetwarzaniu)
- Automatyczne skalowanie w górę gdy lag rośnie
- Skalowanie do 0 gdy brak wiadomości do przetworzenia

## Consumer Lag

**Consumer lag** to różnica między:
- Najnowszym offsetem w partycji (high water mark)
- Offsetem ostatnio przetworzonej wiadomości przez konsumenta

```
High Water Mark: 10000
Current Offset:   9500
Consumer Lag:     500 (wiadomości do przetworzenia)
```

## Zawartość przykładu

1. `kafka.yaml` - Kafka cluster (uproszczony, single node)
2. `consumer-deployment.yaml` - Aplikacja konsumująca z Kafka
3. `scaledobject-lag.yaml` - Skalowanie na podstawie consumer lag
4. `scaledobject-partition.yaml` - Skalowanie na podstawie partycji
5. `producer-job.yaml` - Job do generowania wiadomości testowych

## Wymagania

- Zainstalowana KEDA w klastrze
- kubectl skonfigurowany
- (Opcjonalnie) Strimzi Operator dla produkcyjnej instalacji Kafka

## Jak uruchomić przykład

### Krok 1: Wdróż Kafka

```bash
# Wdróż pojedynczy node Kafka (dla testu)
kubectl apply -f kafka.yaml

# Poczekaj aż Kafka będzie gotowa
kubectl wait --for=condition=ready pod -l app=kafka --timeout=300s
```

**Uwaga:** To jest uproszczona wersja Kafka dla celów demonstracyjnych. W produkcji użyj Strimzi lub Confluent Operator.

### Krok 2: Utwórz topic

```bash
# Exec do Kafka pod
kubectl exec -it deployment/kafka -- bash

# W kontenerze Kafka:
# Utwórz topic z 3 partycjami
kafka-topics.sh --create \
  --topic test-topic \
  --partitions 3 \
  --replication-factor 1 \
  --bootstrap-server localhost:9092

# Sprawdź topic
kafka-topics.sh --describe \
  --topic test-topic \
  --bootstrap-server localhost:9092

# Exit
exit
```

### Krok 3: Wdróż konsumenta

```bash
kubectl apply -f consumer-deployment.yaml
```

### Krok 4: Wdróż ScaledObject

```bash
# Skalowanie na podstawie lag
kubectl apply -f scaledobject-lag.yaml

# LUB skalowanie na podstawie partycji
# kubectl apply -f scaledobject-partition.yaml
```

### Krok 5: Sprawdź status

```bash
# ScaledObject
kubectl get scaledobject kafka-consumer-scaledobject

# HPA
kubectl get hpa

# Pody konsumenta (powinno być 0)
kubectl get pods -l app=kafka-consumer
```

## Testowanie skalowania

### Produkcja wiadomości

```bash
# Użyj producer job do wyprodukowania wiadomości
kubectl apply -f producer-job.yaml

# Monitoruj logi producer
kubectl logs -f job/kafka-producer

# Lub ręcznie przez Kafka console producer
kubectl exec -it deployment/kafka -- bash
# W kontenerze:
kafka-console-producer.sh \
  --topic test-topic \
  --bootstrap-server localhost:9092
# Wpisz kilka wiadomości i naciśnij Ctrl+D
```

### Obserwuj skalowanie

```bash
# Terminal 1: Obserwuj pody
kubectl get pods -l app=kafka-consumer -w

# Terminal 2: Obserwuj ScaledObject
kubectl describe scaledobject kafka-consumer-scaledobject

# Terminal 3: Sprawdź consumer lag
kubectl exec -it deployment/kafka -- \
  kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --group my-consumer-group \
    --describe
```

## Jak to działa - Lag-based scaling

### Konfiguracja

```yaml
triggers:
- type: kafka
  metadata:
    bootstrapServers: kafka.default.svc.cluster.local:9092
    consumerGroup: my-consumer-group
    topic: test-topic
    lagThreshold: "50"    # Jedna replika na 50 wiadomości lag
```

### Matematyka skalowania

```
Repliki = ceil(total_lag / lagThreshold)

Przykłady:
- Lag 0:      0 replik
- Lag 1-50:   1 replika
- Lag 51-100: 2 repliki
- Lag 150:    3 repliki
```

### Total Lag

KEDA sumuje lag ze wszystkich partycji:

```
Partition 0: lag 30
Partition 1: lag 40
Partition 2: lag 50
Total lag: 120 -> ceil(120/50) = 3 repliki
```

## Partition-based scaling

Alternatywna strategia: jedna replika na partycję.

```yaml
triggers:
- type: kafka
  metadata:
    bootstrapServers: kafka.default.svc.cluster.local:9092
    consumerGroup: my-consumer-group
    topic: test-topic
    lagThreshold: "10"
    activationLagThreshold: "5"
```

### Activation Threshold

- `activationLagThreshold` - minimalny lag do aktywacji skalowania
- Zapobiega skalowaniu dla kilku wiadomości
- Przykład: nie skaluj jeśli lag < 5

## Zaawansowana konfiguracja

### Multiple topics

```yaml
triggers:
- type: kafka
  metadata:
    bootstrapServers: kafka:9092
    consumerGroup: my-group
    topic: topic1,topic2,topic3    # Wiele topicków
    lagThreshold: "50"
```

### Authentication (SASL/TLS)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: kafka-secrets
type: Opaque
stringData:
  sasl: "plaintext"
  username: "my-user"
  password: "my-password"
  tls: "enable"
  ca: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
---
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: kafka-auth
spec:
  secretTargetRef:
  - parameter: sasl
    name: kafka-secrets
    key: sasl
  - parameter: username
    name: kafka-secrets
    key: username
  - parameter: password
    name: kafka-secrets
    key: password
---
# W ScaledObject:
triggers:
- type: kafka
  authenticationRef:
    name: kafka-auth
  metadata:
    bootstrapServers: kafka:9092
    consumerGroup: my-group
    topic: my-topic
    lagThreshold: "50"
```

### Limit per partition

```yaml
triggers:
- type: kafka
  metadata:
    bootstrapServers: kafka:9092
    consumerGroup: my-group
    topic: my-topic
    lagThreshold: "50"
    offsetResetPolicy: latest    # earliest | latest
    allowIdleConsumers: "false"  # Scale down idle consumers
    scaleToZeroOnInvalidOffset: "true"
    limitToPartitionsWithLag: "true"  # Tylko partycje z lag
```

## Monitoring

### Sprawdź consumer lag

```bash
# Kafka native tool
kubectl exec -it deployment/kafka -- \
  kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --group my-consumer-group \
    --describe

# Output:
# GROUP           TOPIC      PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
# my-group        test-topic 0          100             150             50
# my-group        test-topic 1          200             200             0
# my-group        test-topic 2          50              100             50
```

### KEDA metrics

```bash
# External metrics API
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/kafka-consumer-scaledobject" | jq .

# Logi KEDA
kubectl logs -n keda -l app=keda-operator | grep kafka
```

### Grafana Dashboard

Jeśli masz Prometheus + Grafana, monitoruj:
- `kafka_consumer_group_lag`
- `keda_scaler_metrics_value{scalerName="kafka"}`
- Liczba replik aplikacji

## Best Practices

### 1. Odpowiedni lagThreshold

```yaml
# Zbyt niski (1-10): częste skalowanie, flapping
# Zbyt wysoki (1000+): wolna reakcja na wzrost ruchu
# Optymalnie: 50-200 w zależności od throughput
lagThreshold: "100"
```

### 2. Activation threshold

```yaml
# Unikaj skalowania dla kilku wiadomości
activationLagThreshold: "10"
```

### 3. CooldownPeriod

```yaml
spec:
  cooldownPeriod: 300  # 5 minut przed scale-to-zero
```

### 4. Partycje vs Repliki

```
Liczba partycji >= maxReplicaCount

Przykład:
- 10 partycji w topicu
- maxReplicaCount: 10
- Każda replika może konsumować z 1 partycji
```

### 5. Consumer group management

- Używaj unikalnej consumer group per aplikacja
- Nie mieszaj manual i KEDA consumers w tej samej grupie

### 6. Resource limits

```yaml
resources:
  requests:
    cpu: 200m      # Wystarczająco dla 1 partycji
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Troubleshooting

### Problem: KEDA nie skaluje mimo lag

```bash
# Sprawdź czy consumer group istnieje
kubectl exec -it deployment/kafka -- \
  kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --list

# Sprawdź logi KEDA
kubectl logs -n keda -l app=keda-operator | grep -i kafka

# Sprawdź connectivity
kubectl exec -it deployment/kafka-consumer -- \
  nc -zv kafka.default.svc.cluster.local 9092
```

### Problem: Consumer nie commituje offsetów

```bash
# Sprawdź logi konsumenta
kubectl logs -l app=kafka-consumer

# Sprawdź czy używa auto-commit lub manual commit
# Upewnij się, że auto.commit.enable=true lub committuj ręcznie
```

### Problem: Flapping (ciągłe skalowanie góra/dół)

```yaml
# Zwiększ lagThreshold
lagThreshold: "100"  # było 10

# Zwiększ activationLagThreshold
activationLagThreshold: "50"

# Zwiększ cooldownPeriod
cooldownPeriod: 600  # 10 minut

# Dodaj stabilization window
spec:
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 600
```

## Przykład produkcyjny z Strimzi

Dla produkcyjnego Kafka użyj Strimzi Operator:

```bash
# Zainstaluj Strimzi
kubectl create namespace kafka
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka

# Utwórz Kafka cluster
kubectl apply -f - <<EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
  namespace: kafka
spec:
  kafka:
    version: 3.6.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
    storage:
      type: ephemeral
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
EOF
```

## Cleanup

```bash
# Usuń wszystkie zasoby
kubectl delete -f .

# Usuń Kafka data (jeśli używasz PVC)
kubectl delete pvc -l app=kafka
```

## Dalsze zasoby

- [KEDA Kafka Scaler Docs](https://keda.sh/docs/2.12/scalers/apache-kafka/)
- [Strimzi Operator](https://strimzi.io/)
- [Kafka Consumer Groups](https://kafka.apache.org/documentation/#consumergroups)
- [Consumer Lag Monitoring](https://www.confluent.io/blog/kafka-consumer-lag-analysis/)

