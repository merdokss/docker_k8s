# Podstawowy przykład HPA - skalowanie na podstawie CPU i pamięci

Ten przykład pokazuje, jak skonfigurować Horizontal Pod Autoscaler do automatycznego skalowania aplikacji na podstawie wykorzystania CPU i pamięci.

## Zawartość przykładu

1. `deployment.yaml` - Podstawowy deployment z aplikacją nginx
2. `service.yaml` - Service eksponujący aplikację
3. `hpa.yaml` - Konfiguracja HPA

## Jak to działa?

1. Deployment tworzy pojedynczy pod z nginx
2. Pod ma zdefiniowane limity zasobów:
   - CPU: request 100m, limit 200m
   - Pamięć: request 128Mi, limit 256Mi
3. HPA monitoruje wykorzystanie zasobów i skaluje pody gdy:
   - Średnie wykorzystanie CPU przekroczy 50%
   - Średnie wykorzystanie pamięci przekroczy 50%
4. HPA będzie utrzymywać liczbę podów między 1 a 5

## Jak uruchomić przykład

```bash
# 1. Upewnij się, że metrics-server jest zainstalowany
kubectl get deployment metrics-server -n kube-system

# 2. Zastosuj konfigurację
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

# 3. Sprawdź status
kubectl get hpa
kubectl get deployment example-app
```

## Jak przetestować skalowanie

1. Generowanie obciążenia CPU:
```bash
# W osobnym terminalu uruchom port-forward
kubectl port-forward svc/example-app 8080:80

# W innym terminalu generuj obciążenie
while true; do curl http://localhost:8080; done
```

2. Monitorowanie skalowania:
```bash
# Obserwuj HPA
kubectl get hpa example-app-hpa -w

# Sprawdź liczbę podów
kubectl get pods -l app=example-app
```

## Zachowanie skalowania

- Skalowanie w górę nastąpi po 60 sekundach utrzymującego się wysokiego obciążenia
- Skalowanie w dół nastąpi po 5 minutach niskiego obciążenia
- Maksymalnie może być utworzonych 5 podów
- Minimalnie zawsze będzie działał 1 pod 


### Obciązenie serwara nginx zapytaniami

`python3 Kubernetes/zadania/load_test.py --url http://localhost:8080 --concurrency 500 --duration 300`