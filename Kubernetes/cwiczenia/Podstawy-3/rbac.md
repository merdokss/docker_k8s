# Kubernetes - Ćwiczenia: RBAC (Role-Based Access Control)

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć RBAC w Kubernetes. RBAC umożliwia kontrolę dostępu do zasobów Kubernetes.

**Co to jest RBAC?** RBAC umożliwia kontrolę dostępu do zasobów Kubernetes. Składa się z:
- **Role/ClusterRole** - definiują uprawnienia (co można robić)
- **RoleBinding/ClusterRoleBinding** - przypisują role do użytkowników/usług

## Przygotowanie środowiska

```bash
# Utwórz namespace (jeśli jeszcze nie istnieje)
kubectl create namespace cwiczenia

# Sprawdź aktualne uprawnienia
kubectl auth can-i --list
```

## Wymagania

- Wymagane uprawnienia administratora do tworzenia Role i RoleBinding
- W większości klastrów RBAC jest domyślnie włączony

---

## Ćwiczenie 1.1: Podstawowa Role i RoleBinding

**Zadanie:** Utwórz Role `pod-reader` w namespace `cwiczenia`, która pozwala na `get`, `list`, `watch` Podów. Następnie utwórz RoleBinding `read-pods`, który przypisuje tę rolę do Service Account `pod-reader-sa`.

**Wskazówki:**
- Role są ograniczone do namespace (nie mogą dotyczyć zasobów z innych namespace)
- `apiVersion: rbac.authorization.k8s.io/v1`
- `resources: ["pods"]` - typ zasobu
- `verbs: ["get", "list", "watch"]` - dozwolone operacje
- Service Account musi istnieć przed utworzeniem RoleBinding

**Cel:** Zrozumienie podstawowej konfiguracji Role i RoleBinding w ramach namespace.

**Weryfikacja:**
```bash
# Utwórz Service Account
kubectl create serviceaccount pod-reader-sa -n cwiczenia

# Sprawdź Role
kubectl get role pod-reader -n cwiczenia

# Sprawdź RoleBinding
kubectl get rolebinding read-pods -n cwiczenia

# Sprawdź uprawnienia Service Account
kubectl auth can-i get pods --as=system:serviceaccount:cwiczenia:pod-reader-sa -n cwiczenia
kubectl auth can-i delete pods --as=system:serviceaccount:cwiczenia:pod-reader-sa -n cwiczenia
```

---

## Ćwiczenie 1.2: Role z wieloma zasobami i uprawnieniami

**Zadanie:** Utwórz Role `deployment-manager` w namespace `cwiczenia`, która pozwala na pełne zarządzanie (create, get, list, update, delete, patch) Deploymentami i ReplicaSetami. Przypisz tę rolę do Service Account `deploy-sa`.

**Wskazówki:**
- Możesz zdefiniować wiele zasobów w jednej Role
- `verbs: ["*"]` lub pełna lista: `["create", "get", "list", "update", "delete", "patch"]`
- Role może dotyczyć wielu typów zasobów

**Cel:** Zrozumienie tworzenia ról z wieloma zasobami i uprawnieniami.

**Weryfikacja:**
```bash
# Sprawdź Role
kubectl get role deployment-manager -n cwiczenia -o yaml

# Sprawdź uprawnienia
kubectl auth can-i create deployments --as=system:serviceaccount:cwiczenia:deploy-sa -n cwiczenia
kubectl auth can-i delete deployments --as=system:serviceaccount:cwiczenia:deploy-sa -n cwiczenia
kubectl auth can-i get secrets --as=system:serviceaccount:cwiczenia:deploy-sa -n cwiczenia
# Ostatnia komenda powinna zwrócić "no" - secrets nie są w roli
```

---

## Ćwiczenie 1.3: ClusterRole i ClusterRoleBinding

**Zadanie:** Utwórz ClusterRole `node-viewer`, która pozwala na `get`, `list`, `watch` nodów (nodes). Następnie utwórz ClusterRoleBinding `view-nodes-global`, który przypisuje tę rolę do Service Account `node-viewer-sa` w namespace `cwiczenia`.

**Wskazówki:**
- ClusterRole działa na poziomie całego klastra (nie jest ograniczona do namespace)
- ClusterRoleBinding może przypisać ClusterRole do użytkowników/usług
- Nodes są zasobem na poziomie klastra, dlatego potrzebujesz ClusterRole
- Service Account jest w namespace, ale może mieć ClusterRoleBinding

**Cel:** Zrozumienie różnicy między Role a ClusterRole oraz zastosowania ClusterRoleBinding.

**Weryfikacja:**
```bash
# Sprawdź ClusterRole (nie wymaga namespace)
kubectl get clusterrole node-viewer

# Sprawdź ClusterRoleBinding
kubectl get clusterrolebinding view-nodes-global

# Sprawdź uprawnienia (ClusterRole działa we wszystkich namespace)
kubectl auth can-i get nodes --as=system:serviceaccount:cwiczenia:node-viewer-sa
kubectl auth can-i get pods --as=system:serviceaccount:cwiczenia:node-viewer-sa
# Druga komenda powinna zwrócić "no" - ClusterRole nie daje uprawnień do Podów
```

---

## Podsumowanie

Po wykonaniu ćwiczeń z RBAC powinieneś:
- ✅ Rozumieć podstawową konfigurację Role i RoleBinding
- ✅ Umieć tworzyć Role z wieloma zasobami i uprawnieniami
- ✅ Rozumieć różnicę między Role a ClusterRole
- ✅ Umieć używać ClusterRoleBinding do przypisania ról na poziomie klastra

## Przydatne komendy

```bash
# RBAC
kubectl get role,rolebinding -n <namespace>
kubectl get clusterrole,clusterrolebinding
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa> -n <ns>

# Szczegóły
kubectl describe role <name> -n <namespace>
kubectl describe rolebinding <name> -n <namespace>
kubectl describe clusterrole <name>
kubectl describe clusterrolebinding <name>
```

