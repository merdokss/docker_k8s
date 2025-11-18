# Rozwiązania ćwiczeń Kubernetes - Podstawy

Ten katalog zawiera rozwiązania wszystkich ćwiczeń z pliku `cwiczenia-podstawy.md`.

## Struktura katalogów

```
rozwiazania/
├── 01-pods/              # Rozwiązania dla Pods
├── 02-replicasets/        # Rozwiązania dla ReplicaSets
├── 03-services/           # Rozwiązania dla Services
└── 04-deployments/        # Rozwiązania dla Deployments
```

## Jak używać rozwiązań

### Podstawowe użycie

1. **Utworzenie zasobu:**
   ```bash
   kubectl apply -f <sciezka-do-pliku.yaml>
   ```

2. **Usunięcie zasobu:**
   ```bash
   kubectl delete -f <sciezka-do-pliku.yaml>
   ```

3. **Sprawdzenie statusu:**
   ```bash
   kubectl get <resource-type> <resource-name>
   kubectl describe <resource-type> <resource-name>
   ```

### Przykłady

#### Ćwiczenie 1.1: Prosty Pod
```bash
kubectl apply -f 01-pods/1.1-pod-simple.yaml
kubectl get pod my-nginx-pod
kubectl logs my-nginx-pod
```

#### Ćwiczenie 3.1: Service typu ClusterIP
```bash
kubectl apply -f 03-services/3.1-service-clusterip.yaml
kubectl get svc nginx-svc
kubectl get endpoints nginx-svc
kubectl port-forward svc/nginx-svc 8080:80
```

#### Ćwiczenie 4.2: Rolling Update
```bash
# Utworzenie Deployment
kubectl apply -f 04-deployments/4.2-deployment-rolling.yaml

# Aktualizacja obrazu
kubectl set image deployment/nginx-rolling nginx=nginx:1.21

# Sprawdzenie statusu aktualizacji
kubectl rollout status deployment/nginx-rolling

# Historia wersji
kubectl rollout history deployment/nginx-rolling
```

## Uwagi

### LoadBalancer Service
Service typu LoadBalancer (ćwiczenie 3.3) może pozostawać w stanie `pending` w środowiskach lokalnych (Kind, Minikube). W takich przypadkach użyj NodePort lub zainstaluj MetalLB.

## Czyszczenie zasobów

Aby usunąć wszystkie zasoby z ćwiczeń:

```bash
# Usuń wszystkie zasoby z katalogu
kubectl delete -f 01-pods/
kubectl delete -f 02-replicasets/
kubectl delete -f 03-services/
kubectl delete -f 04-deployments/
```

Lub usuń konkretne zasoby:
```bash
kubectl delete pod my-nginx-pod
kubectl delete deployment nginx-deployment
kubectl delete svc nginx-svc
```

## Lista plików

### 01-pods/
- `1.1-pod-simple.yaml` - Prosty Pod z nginx
- `1.2-pod-multi-container.yaml` - Pod z wieloma kontenerami
- `1.3-pod-resources.yaml` - Pod z limitami zasobów
- `1.4-pod-env.yaml` - Pod ze zmiennymi środowiskowymi

### 02-replicasets/
- `2.1-replicaset.yaml` - Podstawowy ReplicaSet
- `2.2-replicaset-httpd.yaml` - ReplicaSet do skalowania
- `2.3-replicaset-selector.yaml` - ReplicaSet z selektorem
- `2.4-replicaset-resources.yaml` - ReplicaSet z limitami zasobów

### 03-services/
- `3.1-service-clusterip.yaml` - Deployment + Service ClusterIP
- `3.2-service-nodeport.yaml` - Deployment + Service NodePort
- `3.3-service-loadbalancer.yaml` - Deployment + Service LoadBalancer
- `3.4-service-multi-port.yaml` - Deployment + Service z wieloma portami

### 04-deployments/
- `4.1-deployment.yaml` - Podstawowy Deployment
- `4.2-deployment-rolling.yaml` - Deployment do testowania Rolling Update
- `4.4-deployment-probes.yaml` - Deployment z Liveness i Readiness Probe

**Uwaga:** Ćwiczenie 4.3 (Rollback) używa tego samego Deployment co 4.2, więc użyj pliku `4.2-deployment-rolling.yaml`.

