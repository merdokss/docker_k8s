# Rozwiązania - Horizontal Pod Autoscaler w Kubernetes

## Zadanie 1: Podstawowa konfiguracja HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
```

Weryfikacja:
```bash
kubectl get hpa
kubectl describe hpa web-app-hpa
```

## Zadanie 2: Skalowanie na podstawie metryk niestandardowych

1. Instalacja Prometheus Adapter:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus-adapter prometheus-community/prometheus-adapter
```

2. Konfiguracja HPA z metryką niestandardową:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-custom-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Object
    object:
      metric:
        name: requests_per_second
      describedObject:
        apiVersion: v1
        kind: Service
        name: web-app
      target:
        type: Value
        value: 100
```

## Zadanie 3: Skalowanie na podstawie wielu metryk

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-multi-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
```

## Zadanie 4: Zaawansowana konfiguracja HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-advanced-hpa
  annotations:
    autoscaling.keda.sh/scaleTargetKind: Deployment
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

## Zadanie 5: Monitoring i debugowanie HPA

1. Instalacja Prometheus i Grafana:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```

2. Konfiguracja dashboardu w Grafana:
```json
{
  "dashboard": {
    "panels": [
      {
        "title": "HPA Scaling History",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "kube_horizontalpodautoscaler_status_current_replicas",
            "legendFormat": "{{namespace}}/{{horizontalpodautoscaler}}"
          }
        ]
      },
      {
        "title": "CPU Utilization",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total{container!=\"\"}[5m])) by (pod)",
            "legendFormat": "{{pod}}"
          }
        ]
      }
    ]
  }
}
```

## Przydatne komendy do monitorowania

```bash
# Sprawdzenie statusu HPA
kubectl get hpa
kubectl describe hpa <nazwa-hpa>

# Monitorowanie podów
kubectl get pods -w
kubectl top pods

# Sprawdzenie metryk
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods"
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/"

# Sprawdzenie logów
kubectl logs -n kube-system -l app=metrics-server
```

## Testowanie obciążenia

Użyj skryptu `load_test.py` do generowania obciążenia:
```bash
python load_test.py --url http://twoj-serwer-nginx --concurrency 200 --duration 300
```

Podczas testu monitoruj skalowanie:
```bash
# W jednym terminalu
kubectl get hpa -w

# W drugim terminalu
kubectl top pods -w
``` 