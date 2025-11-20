# Kubernetes - Ćwiczenia Zaawansowane (Podstawy-3)

Ten katalog zawiera ćwiczenia z zaawansowanych mechanizmów Kubernetes.

## Struktura

- **`rbac.md`** - Ćwiczenia z RBAC (3 ćwiczenia)
- **`service-accounts.md`** - Ćwiczenia z Service Accounts (3 ćwiczenia)
- **`affinity.md`** - Ćwiczenia z Affinity i Anti-affinity (3 ćwiczenia)
- **`taints.md`** - Ćwiczenia z Taints i Tolerations (3 ćwiczenia)
- **`resourcequota-limitrange.md`** - Ćwiczenia z ResourceQuota i LimitRange (4 ćwiczenia)
- **`network-policy.md`** - Ćwiczenia z Network Policy (4 ćwiczenia)
- **`rozwiazania/`** - Katalog z rozwiązaniami wszystkich ćwiczeń

## Tematy ćwiczeń

1. **RBAC (Role-Based Access Control)** - 3 ćwiczenia (`rbac.md`)
   - Role i RoleBinding
   - ClusterRole i ClusterRoleBinding
   - Uprawnienia do wielu zasobów

2. **Service Accounts** - 3 ćwiczenia (`service-accounts.md`)
   - Podstawowe Service Accounts
   - Automatyczne montowanie tokenów
   - Image pull secrets

3. **Affinity i Anti-affinity** - 3 ćwiczenia (`affinity.md`)
   - Node Affinity (required)
   - Node Affinity (preferred)
   - Pod Anti-affinity

4. **Taints i Tolerations** - 3 ćwiczenia (`taints.md`)
   - Podstawowy Taint i Toleration
   - Taint z efektem NoExecute
   - Toleration z wartościami

5. **ResourceQuota i LimitRange** - 4 ćwiczenia (`resourcequota-limitrange.md`)
   - Podstawowe ResourceQuota
   - Przekroczenie limitów ResourceQuota
   - LimitRange - domyślne wartości
   - LimitRange - walidacja limitów

6. **Network Policy** - 4 ćwiczenia (`network-policy.md`)
   - Deny All
   - Zezwól na ruch z określonych Podów
   - Zezwól na ruch z namespace
   - Egress (ruch wychodzący)

## Przygotowanie środowiska

### 1. Utworzenie namespace

```bash
kubectl create namespace cwiczenia
```

### 2. Sprawdzenie konfiguracji klastra

```bash
# Sprawdź dostępne nody i ich etykiety
kubectl get nodes --show-labels

# Sprawdź tainty na nodach
kubectl describe nodes | grep -i taint

# Sprawdź aktualne uprawnienia
kubectl auth can-i --list
```

## Wymagania

### RBAC
- W większości klastrów RBAC jest domyślnie włączony
- Do tworzenia Role i RoleBinding potrzebne są uprawnienia administratora

### Service Accounts
- Każdy Pod ma automatycznie przypisany Service Account (domyślnie `default`)

### Affinity/Taints
- Ćwiczenia wymagają dostępności wielu nodów w klastrze
- W środowisku z jednym nodem niektóre ćwiczenia mogą nie działać poprawnie

### ResourceQuota i LimitRange
- Działa we wszystkich klastrach Kubernetes
- Nie wymaga dodatkowych komponentów

### Network Policy
- **WYMAGA Network Policy provider** (Calico, Weave Net itp.)
- W wielu klastrach domyślnie wszystkie Pody mogą komunikować się ze sobą
- W AKS możesz użyć Azure CNI z Network Policy
- W EKS wymaga CNI wspierającego Network Policy
- Bez provider Network Policy nie zadziała (Pody nadal będą mogły się komunikować)

## Kolejność wykonywania ćwiczeń

Ćwiczenia można wykonywać w dowolnej kolejności, ale zalecana kolejność:

1. **RBAC** - podstawowa kontrola dostępu
2. **Service Accounts** - tożsamość Podów
3. **Affinity/Anti-affinity** - umieszczanie Podów
4. **Taints i Tolerations** - kontrola planowania
5. **ResourceQuota i LimitRange** - zarządzanie zasobami
6. **Network Policy** - kontrola ruchu sieciowego (wymaga provider)

## Rozwiązania

Wszystkie rozwiązania znajdują się w katalogu `rozwiazania/`. Każde rozwiązanie zawiera:
- Pliki YAML gotowe do użycia
- Odpowiednią kolejność aplikowania
- Uwagi dotyczące środowiska

Zobacz: `rozwiazania/README.md` dla szczegółowych instrukcji.

## Czyszczenie

Po zakończeniu ćwiczeń możesz usunąć wszystkie zasoby:

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

## Przydatne komendy

```bash
# RBAC
kubectl get role,rolebinding -n <namespace>
kubectl get clusterrole,clusterrolebinding
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa> -n <ns>

# Service Accounts
kubectl get sa -n <namespace>
kubectl describe sa <name> -n <namespace>

# Affinity/Taints
kubectl get nodes --show-labels
kubectl describe nodes | grep -i taint
kubectl label nodes <node-name> <key>=<value>
kubectl taint nodes <node-name> <key>=<value>:<effect>

# ResourceQuota/LimitRange
kubectl get resourcequota,limitrange -n <namespace>
kubectl describe resourcequota <name> -n <namespace>
kubectl describe limitrange <name> -n <namespace>

# Network Policy
kubectl get networkpolicy -n <namespace>
kubectl describe networkpolicy <name> -n <namespace>

# Ogólne
kubectl get all -n cwiczenia
kubectl describe <resource> <name> -n cwiczenia
kubectl logs <pod-name> -n cwiczenia
kubectl exec -it <pod-name> -n cwiczenia -- /bin/sh
```

