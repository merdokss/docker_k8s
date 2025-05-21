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
3. `03-multiple-metrics/` - Przykład skalowania na podstawie wielu metryk jednocześnie

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
