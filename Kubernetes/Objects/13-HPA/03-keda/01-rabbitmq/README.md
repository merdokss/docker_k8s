# KEDA z RabbitMQ - Przykład skalowania na podstawie kolejki

Ten przykład pokazuje jak używać KEDA do automatycznego skalowania konsumentów RabbitMQ na podstawie liczby wiadomości w kolejce.

## Opis scenariusza

- Worker aplikacja pobiera wiadomości z kolejki RabbitMQ
- KEDA monitoruje długość kolejki
- Gdy w kolejce jest więcej niż 5 wiadomości, KEDA tworzy dodatkowe pody
- Gdy kolejka jest pusta przez 5 minut, KEDA skaluje do 0 replik

## Zawartość przykładu

1. `rabbitmq.yaml` - Deployment i Service dla RabbitMQ
2. `consumer-deployment.yaml` - Worker konsumujący wiadomości
3. `scaledobject.yaml` - Konfiguracja KEDA ScaledObject
4. `trigger-auth.yaml` - Autentykacja dla RabbitMQ (opcjonalne)
5. `producer-job.yaml` - Job do generowania wiadomości testowych

## Wymagania

- Zainstalowana KEDA w klastrze
- kubectl skonfigurowany

## Jak uruchomić przykład

### Krok 1: Wdróż RabbitMQ

```bash
kubectl apply -f rabbitmq.yaml
```

Poczekaj aż RabbitMQ będzie gotowy:

```bash
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=300s
```

### Krok 2: Wdróż konsumenta

```bash
kubectl apply -f consumer-deployment.yaml
```

### Krok 3: Wdróż ScaledObject KEDA

```bash
kubectl apply -f scaledobject.yaml
```

### Krok 4: Sprawdź status

```bash
# Sprawdź ScaledObject
kubectl get scaledobjects

# Sprawdź HPA utworzony przez KEDA
kubectl get hpa

# Sprawdź liczbę podów konsumenta
kubectl get pods -l app=rabbitmq-consumer
```

Na początku powinieneś zobaczyć 0 podów konsumenta (KEDA skaluje do 0).

## Testowanie skalowania

### Metoda 1: Produkcja wiadomości ręcznie

```bash
# Port-forward do RabbitMQ Management UI
kubectl port-forward svc/rabbitmq 15672:15672

# Otwórz http://localhost:15672 w przeglądarce
# Login: guest / Password: guest

# Przejdź do zakładki "Queues" -> "test-queue" -> "Publish message"
# Opublikuj kilka wiadomości
```

### Metoda 2: Użyj Job do generowania wiadomości

```bash
# Uruchom producer job
kubectl apply -f producer-job.yaml

# Monitoruj logi
kubectl logs -f job/rabbitmq-producer
```

### Obserwuj skalowanie

```bash
# Terminal 1: Obserwuj ScaledObject
kubectl get scaledobject rabbitmq-consumer-scaledobject -w

# Terminal 2: Obserwuj pody
kubectl get pods -l app=rabbitmq-consumer -w

# Terminal 3: Obserwuj HPA
kubectl get hpa -w

# Terminal 4: Sprawdź długość kolejki
kubectl exec -it deployment/rabbitmq -- rabbitmqadmin list queues
```

## Jak to działa

### ScaledObject konfiguracja

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: rabbitmq-consumer-scaledobject
spec:
  scaleTargetRef:
    name: rabbitmq-consumer
  minReplicaCount: 0    # Skaluj do 0!
  maxReplicaCount: 10
  pollingInterval: 10   # Sprawdzaj co 10 sekund
  cooldownPeriod: 300   # Czekaj 5 minut przed skalowaniem do 0
  triggers:
  - type: rabbitmq
    metadata:
      protocol: auto
      queueName: test-queue
      mode: QueueLength
      value: "5"        # Jedna replika na 5 wiadomości
      host: amqp://guest:guest@rabbitmq.default.svc.cluster.local:5672
```

### Parametry RabbitMQ Scaler

- `queueName` - nazwa kolejki do monitorowania
- `value` - docelowa liczba wiadomości na replikę
- `mode` - `QueueLength` (długość kolejki) lub `MessageRate` (rate wiadomości)
- `protocol` - `auto`, `http` lub `amqp`
- `host` - connection string do RabbitMQ

### Matematyka skalowania

```
Liczba replik = ceil(liczba_wiadomości / value)

Przykłady:
- 0 wiadomości = 0 replik
- 1-5 wiadomości = 1 replika
- 6-10 wiadomości = 2 repliki
- 11-15 wiadomości = 3 repliki
- 46-50 wiadomości = 10 replik (max)
```

## Scenariusze testowe

### Test 1: Skalowanie w górę

```bash
# Wyprodukuj 50 wiadomości
kubectl apply -f producer-job.yaml

# Obserwuj jak KEDA skaluje do ~10 replik
kubectl get pods -l app=rabbitmq-consumer -w
```

### Test 2: Skalowanie w dół

```bash
# Poczekaj aż wszystkie wiadomości zostaną przetworzone
# Po ~5 minutach (cooldownPeriod) KEDA zeskaluje do 0
kubectl get pods -l app=rabbitmq-consumer -w
```

### Test 3: Burst traffic

```bash
# Wyprodukuj wiadomości w pętli
kubectl delete job rabbitmq-producer
kubectl apply -f producer-job.yaml

# Obserwuj szybką reakcję KEDA
```

## Monitoring

### Sprawdź metryki KEDA

```bash
# Metryki z scalera
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/rabbitmq-consumer-scaledobject" | jq .

# Status ScaledObject
kubectl describe scaledobject rabbitmq-consumer-scaledobject
```

### RabbitMQ Management

```bash
# Port-forward management UI
kubectl port-forward svc/rabbitmq 15672:15672

# Otwórz http://localhost:15672
# Login: guest / Password: guest
```

## Troubleshooting

### Problem: KEDA nie skaluje

```bash
# Sprawdź logi KEDA operator
kubectl logs -n keda -l app=keda-operator --tail=50

# Sprawdź czy ScaledObject jest aktywny
kubectl get scaledobject

# Sprawdź status HPA
kubectl get hpa
kubectl describe hpa keda-hpa-rabbitmq-consumer
```

### Problem: Brak połączenia z RabbitMQ

```bash
# Sprawdź czy RabbitMQ działa
kubectl get pods -l app=rabbitmq

# Sprawdź logi RabbitMQ
kubectl logs -l app=rabbitmq

# Test połączenia z poda
kubectl run test --rm -it --image=rabbitmq:3-management -- bash
# W kontenerze:
# rabbitmqadmin -H rabbitmq.default.svc.cluster.local -u guest -p guest list queues
```

### Problem: Konsument nie przetwarza wiadomości

```bash
# Sprawdź logi konsumenta
kubectl logs -l app=rabbitmq-consumer

# Sprawdź czy konsument ma dostęp do RabbitMQ
kubectl exec -it deployment/rabbitmq-consumer -- env | grep RABBIT
```

## Cleanup

```bash
# Usuń wszystkie zasoby
kubectl delete -f .

# Lub pojedynczo
kubectl delete scaledobject rabbitmq-consumer-scaledobject
kubectl delete deployment rabbitmq-consumer
kubectl delete deployment rabbitmq
kubectl delete service rabbitmq
kubectl delete job rabbitmq-producer
```

## Zaawansowane opcje

### TriggerAuthentication dla większego bezpieczeństwa

Zamiast hardcodować credentials w ScaledObject, użyj TriggerAuthentication:

```yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: rabbitmq-auth
spec:
  secretTargetRef:
  - parameter: host
    name: rabbitmq-secret
    key: connectionString
```

### Multiple queues

Możesz skalować na podstawie wielu kolejek:

```yaml
triggers:
- type: rabbitmq
  metadata:
    queueName: queue1
    value: "5"
- type: rabbitmq
  metadata:
    queueName: queue2
    value: "3"
```

### Advanced behavior

```yaml
spec:
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
          - type: Percent
            value: 50
            periodSeconds: 60
```

## Best Practices

1. **Ustaw odpowiedni `value`** - zależy od czasu przetwarzania wiadomości
2. **Monitoruj rate przetwarzania** - upewnij się, że konsumenty nadążają
3. **Użyj `cooldownPeriod`** aby uniknąć częstego skalowania w dół
4. **Testuj pod obciążeniem** przed wdrożeniem na produkcję
5. **Ustaw resource limits** na konsumentach
6. **Używaj TriggerAuthentication** dla credentials
7. **Monitoruj koszty** - więcej replik = wyższe koszty

## Dalsze zasoby

- [KEDA RabbitMQ Scaler Docs](https://keda.sh/docs/2.12/scalers/rabbitmq-queue/)
- [RabbitMQ Best Practices](https://www.rabbitmq.com/best-practices.html)

