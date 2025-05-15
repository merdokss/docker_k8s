# HPA z własnymi metrykami

Ten przykład pokazuje, jak skonfigurować Horizontal Pod Autoscaler do skalowania na podstawie własnych metryk aplikacji.

## Wymagania wstępne

Przed uruchomieniem tego przykładu, należy mieć zainstalowane:

1. Prometheus Operator
2. Custom Metrics API
3. Prometheus Adapter

## Zawartość przykładu

1. `deployment.yaml` - Deployment z aplikacją i eksporterem metryk
2. `service.yaml` - Service eksponujący aplikację i endpoint metryk
3. `hpa.yaml` - Konfiguracja HPA z własnymi metrykami

## Jak to działa?

1. Aplikacja eksponuje własne metryki w formacie Prometheus na endpoint `/metrics`
2. Prometheus zbiera metryki z aplikacji
3. Prometheus Adapter konwertuje metryki do formatu zrozumiałego przez Kubernetes
4. HPA używa tych metryk do skalowania:
   - `http_requests_per_second` - liczba żądań HTTP na sekundę
   - `requests_queue_length` - długość kolejki żądań

## Konfiguracja metryk

W tym przykładzie używamy dwóch typów metryk:

1. Metryki podów (Pods metrics):
```yaml
- type: Pods
  pods:
    metric:
      name: http_requests_per_second
    target:
      type: AverageValue
      averageValue: 100
```

2. Metryki obiektów (Object metrics):
```yaml
- type: Object
  object:
    metric:
      name: requests_queue_length
    describedObject:
      apiVersion: v1
      kind: Service
      name: example-app-custom
    target:
      type: Value
      value: 100
```

## Jak uruchomić przykład

```bash
# 1. Upewnij się, że masz zainstalowane wymagane komponenty
kubectl get prometheuses -n monitoring
kubectl get prometheusadapter -n monitoring
kubectl get apiservice v1beta1.custom.metrics.k8s.io

# 2. Zastosuj konfigurację
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

# 3. Sprawdź dostępne metryki
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1" | jq .

# 4. Sprawdź status HPA
kubectl get hpa example-app-custom-hpa
```

## Monitorowanie własnych metryk

```bash
# Sprawdź wartości metryk dla podów
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/http_requests_per_second" | jq .

# Sprawdź wartości metryk dla service
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/services/example-app-custom/requests_queue_length" | jq .
```

## Zachowanie skalowania

- Skalowanie w górę:
  - Dodaje maksymalnie 2 pody co 60 sekund
  - Następuje po przekroczeniu progów metryk
  - Ma 60-sekundowe okno stabilizacji

- Skalowanie w dół:
  - Usuwa maksymalnie 1 pod co 60 sekund
  - Następuje gdy metryki spadną poniżej progów
  - Ma 5-minutowe okno stabilizacji

## Uwagi

1. W rzeczywistym środowisku należy dostosować:
   - Progi skalowania
   - Okna stabilizacji
   - Polityki skalowania
2. Warto monitorować zachowanie HPA i dostrajać parametry
3. Należy upewnić się, że aplikacja prawidłowo eksponuje metryki 