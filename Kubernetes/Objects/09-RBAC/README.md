# RBAC (Role-Based Access Control) w Kubernetes

## Wprowadzenie

RBAC to mechanizm kontroli dostępu w Kubernetes, który pozwala na szczegółowe zarządzanie uprawnieniami użytkowników i serwisów. System RBAC opiera się na czterech głównych komponentach: tożsamościach (Users, Groups, ServiceAccounts), rolach (Roles, ClusterRoles) oraz wiązaniach ról (RoleBindings, ClusterRoleBindings).

## Komponenty RBAC

### 1. Tożsamości (Identity)

#### Users
```yaml
# Users są zarządzani zewnętrznie (np. przez certyfikaty)
# Przykład certyfikatu użytkownika
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john
spec:
  request: <base64-encoded-csr>
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
```

#### Groups
Grupy są logicznym zbiorem użytkowników. W Kubernetes są obsługiwane poprzez certyfikaty lub zewnętrzne systemy autoryzacji.

#### ServiceAccount
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: development
---
# Automatycznie tworzony Secret dla ServiceAccount
apiVersion: v1
kind: Secret
metadata:
  name: app-service-account-token
  annotations:
    kubernetes.io/service-account.name: app-service-account
type: kubernetes.io/service-account-token
```

### 2. Role i ClusterRole

#### Role (zakres namespace)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
```

#### ClusterRole (zakres klastra)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-monitor
rules:
- apiGroups: [""]
  resources: ["nodes", "pods"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
```

### 3. RoleBinding i ClusterRoleBinding

#### RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: development
subjects:
- kind: User
  name: john
  apiGroup: rbac.authorization.k8s.io
- kind: ServiceAccount
  name: app-service-account
  namespace: development
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

#### ClusterRoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-monitoring
subjects:
- kind: Group
  name: monitoring-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-monitor
  apiGroup: rbac.authorization.k8s.io
```

## Praktyczne przykłady

### 1. Tworzenie konta dla dewelopera
```yaml
# 1. Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: developer
  namespace: development

# 2. Role z uprawnieniami
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: developer-role
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments", "services"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# 3. RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: development
subjects:
- kind: ServiceAccount
  name: developer
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
```

### 2. Konfiguracja monitoringu klastra
```yaml
# 1. ClusterRole dla monitoringu
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-role
rules:
- apiGroups: [""]
  resources: ["nodes", "pods", "services", "endpoints"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get"]

# 2. ServiceAccount dla Prometheus
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring

# 3. ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus-monitoring
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
roleRef:
  kind: ClusterRole
  name: monitoring-role
  apiGroup: rbac.authorization.k8s.io
```

## Dobre praktyki

### 1. Zasada najmniejszych uprawnień
Zawsze nadawaj minimalne uprawnienia potrzebne do wykonania zadania:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: minimal-pod-reader
  namespace: development
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]  # Tylko odczyt, bez modyfikacji
```

### 2. Używanie agregatów ról
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-endpoints
  labels:
    rbac.example.com/aggregate-to-monitoring: "true"
rules:
- apiGroups: [""]
  resources: ["endpoints"]
  verbs: ["get", "list", "watch"]
```

### 3. Dokumentowanie uprawnień
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: default
  annotations:
    description: "Role for application XYZ"
    team: "platform-team"
    purpose: "Allows managing application resources"
rules:
# ... rules ...
```

## Weryfikacja uprawnień

### Sprawdzanie uprawnień użytkownika
```bash
# Sprawdź czy użytkownik może listować pody
kubectl auth can-i list pods --namespace development --as john

# Sprawdź wszystkie uprawnienia
kubectl auth can-i --list --namespace development --as john
```

### Debugowanie RBAC
```bash
# Zobacz role w namespace
kubectl get roles -n development

# Zobacz bindingi
kubectl get rolebindings -n development

# Szczegóły roli
kubectl describe role pod-reader -n development
```

## Typowe problemy i rozwiązania

### 1. Problem z dostępem do zasobów
Sprawdź:
- Czy rola ma odpowiednie uprawnienia
- Czy binding jest w odpowiednim namespace
- Czy podmiot (subject) jest poprawnie skonfigurowany

### 2. Konflikt uprawnień
- Uprawnienia deny mają pierwszeństwo
- Sprawdź wszystkie role i bindingi dla użytkownika
- Użyj `kubectl auth can-i` do weryfikacji

## Bezpieczeństwo

### 1. Regularne audyty
```bash
# Lista wszystkich binding w klastrze
kubectl get clusterrolebindings,rolebindings --all-namespaces

# Eksport konfiguracji RBAC
kubectl get roles,rolebindings,clusterroles,clusterrolebindings -o yaml
```

### 2. Ograniczanie dostępu administracyjnego
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: restricted-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
  resourceNames: ["specific-resource"]  # Ograniczenie do konkretnych zasobów
```

### 3. Monitoring zmian RBAC
Użyj narzędzi audytowych Kubernetes i loguj zmiany w konfiguracji RBAC.

## Migracja i aktualizacja

### 1. Aktualizacja ról
```bash
# Eksport istniejącej roli
kubectl get role old-role -n development -o yaml > role.yaml

# Edycja i aplikacja nowej wersji
kubectl apply -f role.yaml
```

### 2. Migracja między namespace'ami
```bash
# Kopiowanie roli między namespace'ami
kubectl get role source-role -n source -o yaml | \
  sed 's/namespace: source/namespace: target/' | \
  kubectl apply -f -
```