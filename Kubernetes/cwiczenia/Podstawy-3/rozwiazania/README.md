# Rozwiązania ćwiczeń - Podstawy-3

Ten katalog zawiera rozwiązania wszystkich ćwiczeń z katalogu `Podstawy-3`.

## Struktura plików

Pliki są nazywane według wzorca: `<typ>-<numer-cwiczenia>-<nazwa>.yaml`

Przykłady:
- `rbac-1.1-role-pod-reader.yaml` - Ćwiczenie 1.1 z RBAC (Role)
- `rbac-1.1-rolebinding-read-pods.yaml` - Ćwiczenie 1.1 z RBAC (RoleBinding)
- `sa-2.1-my-service-account.yaml` - Ćwiczenie 2.1 z Service Account
- `affinity-3.1-nginx-ssd-deployment.yaml` - Ćwiczenie 3.1 z Affinity

## Jak używać rozwiązań

### 1. Przygotowanie namespace

```bash
kubectl create namespace cwiczenia
```

### 2. Aplikowanie rozwiązań

Każde ćwiczenie może wymagać kilku plików YAML. Aplikuj je w odpowiedniej kolejności:

**Przykład - RBAC (ćwiczenie 1.1):**
```bash
# 1. Utwórz Service Account
kubectl create serviceaccount pod-reader-sa -n cwiczenia

# 2. Utwórz Role
kubectl apply -f rbac-1.1-role-pod-reader.yaml

# 3. Utwórz RoleBinding
kubectl apply -f rbac-1.1-rolebinding-read-pods.yaml
```

**Przykład - Affinity (ćwiczenie 3.1):**
```bash
# 1. Oznacz noda etykietą
kubectl label nodes <node-name> disktype=ssd

# 2. Utwórz Deployment
kubectl apply -f affinity-3.1-nginx-ssd-deployment.yaml
```

**Przykład - Taints (ćwiczenie 4.1):**
```bash
# 1. Oznacz noda taintem
kubectl taint nodes <node-name> special-node=true:NoSchedule

# 2. Utwórz Deployment bez toleracji (nie uruchomi się na nodzie z taintem)
kubectl apply -f taints-4.1-nginx-normal-deployment.yaml

# 3. Utwórz Deployment z toleracją (uruchomi się na nodzie z taintem)
kubectl apply -f taints-4.1-nginx-special-deployment.yaml
```

### 3. Weryfikacja

Użyj komend weryfikacyjnych z pliku ćwiczeń w katalogu głównym.

## Uwagi dotyczące środowiska

### RBAC
- W większości klastrów RBAC jest domyślnie włączony
- Do tworzenia Role i RoleBinding potrzebne są uprawnienia administratora
- ClusterRole działa na poziomie całego klastra (nie ograniczona do namespace)

### Service Accounts
- Każdy Pod ma automatycznie przypisany Service Account (domyślnie `default`)
- Token Service Account jest automatycznie montowany w `/var/run/secrets/kubernetes.io/serviceaccount/`
- Możesz wyłączyć automatyczne montowanie tokenu

### Affinity/Taints
- Ćwiczenia wymagają dostępności wielu nodów w klastrze
- W środowisku z jednym nodem niektóre ćwiczenia mogą nie działać poprawnie
- Sprawdź dostępne nody: `kubectl get nodes`
- Sprawdź etykiety nodów: `kubectl get nodes --show-labels`
- Sprawdź tainty: `kubectl describe nodes | grep -i taint`

### ResourceQuota i LimitRange
- ResourceQuota sumuje wszystkie requests i limits w namespace
- Jeśli suma przekroczy limit, nowe Pody nie zostaną utworzone
- LimitRange automatycznie wstrzykuje domyślne wartości do kontenerów
- LimitRange waliduje wartości przed utworzeniem Poda

### Network Policy
- **WYMAGA Network Policy provider** (Calico, Weave Net itp.)
- W wielu klastrach domyślnie wszystkie Pody mogą komunikować się ze sobą
- W AKS możesz użyć Azure CNI z Network Policy
- W EKS wymaga CNI wspierającego Network Policy
- Bez provider Network Policy nie zadziała (Pody nadal będą mogły się komunikować)

## Czyszczenie

Aby usunąć wszystkie zasoby:

```bash
# Usuń wszystkie zasoby z namespace
kubectl delete all --all -n cwiczenia
kubectl delete role,rolebinding --all -n cwiczenia
kubectl delete sa --all -n cwiczenia
kubectl delete networkpolicy --all -n cwiczenia
kubectl delete resourcequota,limitrange --all -n cwiczenia

# Usuń ClusterRole i ClusterRoleBinding (jeśli utworzyłeś)
kubectl delete clusterrole node-viewer
kubectl delete clusterrolebinding view-nodes-global

# Usuń tainty z nodów (zamień <node-name> na rzeczywistą nazwę noda)
kubectl taint nodes <node-name> special-node:NoSchedule-
kubectl taint nodes <node-name> maintenance:NoExecute-
kubectl taint nodes <node-name> node-type:NoSchedule-

# Usuń etykiety z nodów
kubectl label nodes <node-name> disktype-
kubectl label nodes <node-name> environment-

# Usuń namespace
kubectl delete namespace cwiczenia
```

## Lista wszystkich plików rozwiązań

### RBAC
- `rbac-1.1-role-pod-reader.yaml`
- `rbac-1.1-rolebinding-read-pods.yaml`
- `rbac-1.2-role-deployment-manager.yaml`
- `rbac-1.2-rolebinding-deploy.yaml`
- `rbac-1.3-clusterrole-node-viewer.yaml`
- `rbac-1.3-clusterrolebinding-view-nodes-global.yaml`

### Service Accounts
- `sa-2.1-my-service-account.yaml`
- `sa-2.1-nginx-sa-pod.yaml`
- `sa-2.2-app-sa.yaml`
- `sa-2.2-app-deploy.yaml`
- `sa-2.3-image-puller-sa.yaml`
- `sa-2.3-private-image-pod.yaml`

### Affinity
- `affinity-3.1-nginx-ssd-deployment.yaml`
- `affinity-3.2-nginx-preferred-deployment.yaml`
- `affinity-3.3-nginx-distributed-deployment.yaml`

### Taints i Tolerations
- `taints-4.1-nginx-normal-deployment.yaml`
- `taints-4.1-nginx-special-deployment.yaml`
- `taints-4.2-nginx-running-deployment.yaml`
- `taints-4.3-gpu-app-deployment.yaml`

### ResourceQuota i LimitRange
- `quota-5.1-compute-quota.yaml`
- `quota-5.1-nginx-quota-deployment.yaml`
- `limitrange-5.3-default-limits.yaml`
- `limitrange-5.3-nginx-limitrange-pod.yaml`

### Network Policy
- `netpol-6.1-deny-all.yaml`
- `netpol-6.1-web-app-deployment.yaml`
- `netpol-6.2-backend-deployment.yaml`
- `netpol-6.2-frontend-deployment.yaml`
- `netpol-6.2-allow-frontend-to-backend.yaml`
- `netpol-6.3-allow-from-namespace.yaml`
- `netpol-6.3-monitored-app-deployment.yaml`
- `netpol-6.4-restrict-egress.yaml`
- `netpol-6.4-restricted-app-deployment.yaml`

