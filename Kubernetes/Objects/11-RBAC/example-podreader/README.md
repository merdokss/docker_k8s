# Przykład RBAC - ServiceAccount z uprawnieniami tylko do odczytu Podów

Ten przykład demonstruje podstawową konfigurację RBAC (Role-Based Access Control) w Kubernetes, która przyznaje ServiceAccount uprawnienia tylko do odczytu (read-only) dla zasobów typu Pod.

## Zawartość

Plik `example.yaml` zawiera cztery zasoby Kubernetes:

### 1. ServiceAccount: `pod-reader`
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-reader
```
Tworzy konto serwisowe, które będzie używane przez Pod do uwierzytelniania się z API Kubernetes.

### 2. Role: `pod-reader-role`
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```
Definiuje rolę z ograniczonymi uprawnieniami:
- **apiGroups: [""]** - pusta grupa API (core API group)
- **resources: ["pods"]** - dotyczy tylko zasobów typu Pod
- **verbs: ["get", "list"]** - zezwala tylko na operacje odczytu (get pojedynczego Poda, list wszystkich Podów)

⚠️ **Uwaga:** Role działa tylko w obrębie namespace, w którym jest utworzona (namespace-scoped).

### 3. RoleBinding: `pod-reader-binding`
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
subjects:
- kind: ServiceAccount
  name: pod-reader
roleRef:
  kind: Role
  name: pod-reader-role
  apiGroup: rbac.authorization.k8s.io
```
Łączy ServiceAccount `pod-reader` z rolą `pod-reader-role`, nadając mu w ten sposób uprawnienia zdefiniowane w roli.

### 4. Pod testowy: `test-readonly-sa`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-readonly-sa
spec:
  serviceAccountName: pod-reader
  containers:
  - name: kubectl-container
    image: bitnami/kubectl:latest
    command: ['sh', '-c', 'sleep 3600']
```
Pod z narzędziem kubectl, który używa ServiceAccount `pod-reader`. Służy do testowania uprawnień.

## Instrukcja użycia

### 1. Zastosowanie konfiguracji
```bash
kubectl apply -f example.yaml
```

### 2. Weryfikacja utworzonych zasobów
```bash
# Sprawdź ServiceAccount
kubectl get serviceaccount pod-reader

# Sprawdź Role
kubectl get role pod-reader-role

# Sprawdź RoleBinding
kubectl get rolebinding pod-reader-binding

# Sprawdź Pod
kubectl get pod test-readonly-sa
```

### 3. Testowanie uprawnień

Wejdź do Poda testowego:
```bash
kubectl exec -it test-readonly-sa -- sh
```

#### Operacje, które POWINNY działać ✅
```bash
# Wylistowanie wszystkich Podów w namespace
kubectl get pods

# Pobranie szczegółów konkretnego Poda
kubectl get pod test-readonly-sa -o yaml
```

#### Operacje, które NIE POWINNY działać ❌
```bash
# Próba usunięcia Poda (brak uprawnień "delete")
kubectl delete pod test-readonly-sa
# Błąd: Error from server (Forbidden): pods "test-readonly-sa" is forbidden

# Próba utworzenia Poda (brak uprawnień "create")
kubectl run test-pod --image=nginx
# Błąd: Error from server (Forbidden): pods is forbidden

# Próba edycji Poda (brak uprawnień "update", "patch")
kubectl label pod test-readonly-sa test=label
# Błąd: Error from server (Forbidden): pods "test-readonly-sa" is forbidden

# Próba dostępu do innych zasobów (np. deployments, services)
kubectl get deployments
# Błąd: Error from server (Forbidden): deployments.apps is forbidden

kubectl get services
# Błąd: Error from server (Forbidden): services is forbidden
```

## Koncepcje RBAC

### Komponenty RBAC
1. **ServiceAccount** - tożsamość dla procesów działających w Podach
2. **Role/ClusterRole** - zestaw uprawnień (co można robić)
3. **RoleBinding/ClusterRoleBinding** - przypisanie uprawnień do tożsamości (kto może co robić)

### Różnice: Role vs ClusterRole
- **Role** - działa w obrębie konkretnego namespace
- **ClusterRole** - działa w całym klastrze

### Różnice: RoleBinding vs ClusterRoleBinding
- **RoleBinding** - przyznaje uprawnienia w obrębie namespace
- **ClusterRoleBinding** - przyznaje uprawnienia w całym klastrze

## Cleanup

Aby usunąć wszystkie zasoby:
```bash
kubectl delete -f example.yaml
```

Lub selektywnie:
```bash
kubectl delete pod test-readonly-sa
kubectl delete rolebinding pod-reader-binding
kubectl delete role pod-reader-role
kubectl delete serviceaccount pod-reader
```

## Przypadki użycia

Ten wzorzec jest przydatny gdy:
- Chcesz ograniczyć uprawnienia aplikacji do minimum (Principle of Least Privilege)
- Aplikacja potrzebuje tylko monitorować/obserwować inne Pody
- Testujesz system RBAC i chcesz zrozumieć podstawy
- Implementujesz operatory lub kontrolery, które potrzebują tylko dostępu do odczytu

## Dalsze kroki

Aby rozszerzyć ten przykład, możesz:
1. Dodać więcej verbów: `["get", "list", "watch", "create", "update", "delete"]`
2. Dodać więcej zasobów: `["pods", "services", "deployments"]`
3. Użyć ClusterRole zamiast Role dla uprawnień cluster-wide
4. Dodać ResourceNames do ograniczenia dostępu tylko do konkretnych Podów
5. Użyć agregacji ról (ClusterRole aggregation)

## Bezpieczeństwo

✅ **Dobre praktyki:**
- Zawsze stosuj zasadę najmniejszych uprawnień (Least Privilege)
- Używaj dedykowanych ServiceAccounts dla każdej aplikacji
- Regularnie przeglądaj i audytuj uprawnienia RBAC
- Unikaj przyznawania uprawnień `*` (wszystkie) w produkcji

❌ **Unikaj:**
- Używania domyślnego ServiceAccount z rozszerzonymi uprawnieniami
- Przyznawania uprawnień cluster-admin bez wyraźnej potrzeby
- Stosowania wildcard (`*`) dla resources i verbs bez głębokiego przemyślenia

