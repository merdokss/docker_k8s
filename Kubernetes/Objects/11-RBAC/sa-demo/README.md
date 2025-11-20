# ServiceAccount i ClusterRoleBinding w Kubernetes

## ServiceAccount

ServiceAccount to mechanizm w Kubernetes, który zapewnia tożsamość dla procesów działających w podach. Każdy namespace ma domyślnie utworzony ServiceAccount o nazwie `default`.

### Tworzenie ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: moj-service-account
  namespace: moj-namespace
```

### Użycie ServiceAccount w podzie

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: moj-pod
spec:
  serviceAccountName: moj-service-account
  containers:
  - name: moj-kontener
    image: nginx
```

## ClusterRoleBinding

ClusterRoleBinding to zasób, który wiąże ClusterRole z użytkownikami, grupami lub ServiceAccountami na poziomie całego klastra.

### Tworzenie ClusterRoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: moje-cluster-role-binding
subjects:
- kind: ServiceAccount
  name: moj-service-account
  namespace: moj-namespace
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```

### Przykłady użycia

1. Nadanie uprawnień do odczytu wszystkich podów w klastrze:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pod-reader-binding
subjects:
- kind: ServiceAccount
  name: moj-service-account
  namespace: moj-namespace
roleRef:
  kind: ClusterRole
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

## Najważniejsze informacje

1. ServiceAccount jest używany do uwierzytelniania procesów w podach
2. ClusterRoleBinding działa na poziomie całego klastra
3. Można wiązać wiele podmiotów (subjects) z jedną rolą
4. Warto stosować zasadę najmniejszych uprawnień (principle of least privilege)

## Przydatne komendy

```bash
# Listowanie ServiceAccountów
kubectl get serviceaccounts

# Listowanie ClusterRoleBindingów
kubectl get clusterrolebindings

# Szczegóły konkretnego ClusterRoleBinding
kubectl describe clusterrolebinding nazwa-bindingu

# Usunięcie ClusterRoleBinding
kubectl delete clusterrolebinding nazwa-bindingu
```
