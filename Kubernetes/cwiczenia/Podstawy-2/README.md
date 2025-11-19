# Kubernetes - Ćwiczenia Zaawansowane (Podstawy-2)

Ten katalog zawiera ćwiczenia z zaawansowanych obiektów Kubernetes.

## Struktura

- **`ingress.md`** - Ćwiczenia z Ingress (3 ćwiczenia)
- **`statefulset.md`** - Ćwiczenia ze StatefulSet (3 ćwiczenia)
- **`daemonset.md`** - Ćwiczenia z DaemonSet (3 ćwiczenia)
- **`job.md`** - Ćwiczenia z Job (4 ćwiczenia)
- **`cronjob.md`** - Ćwiczenia z CronJob (4 ćwiczenia)
- **`storage.md`** - Ćwiczenia ze Storage (5 ćwiczeń)
- **`rozwiazania/`** - Katalog z rozwiązaniami wszystkich ćwiczeń

## Przygotowanie środowiska

### 1. Utworzenie namespace

```bash
kubectl create namespace cwiczenia
```

### 2. Sprawdzenie dostępnych zasobów

```bash
# Sprawdź dostępne StorageClass
kubectl get storageclass

# Sprawdź dostępne IngressClass (dla ćwiczeń z Ingress)
kubectl get ingressclass

# Sprawdź nody (dla ćwiczeń z DaemonSet)
kubectl get nodes
```

## Wymagania

### Ingress
- **Wymagany kontroler Ingress** (NGINX Ingress Controller lub Application Gateway Ingress Controller w AKS)
- Jeśli nie masz kontrolera, Ingress pozostanie w stanie Pending
- Sprawdź: `kubectl get ingressclass`

### Storage
- W AKS: dostępne StorageClass `default`, `azurefile`, `managed`
- W EKS: dostępne StorageClass specyficzne dla AWS
- W GKE: dostępne StorageClass specyficzne dla GCP
- W środowiskach lokalnych (Kind, Minikube): możesz użyć `hostPath` dla statycznego PV

### DaemonSet
- Ćwiczenie 3.2 wymaga oznaczenia noda etykietą
- Ćwiczenie 3.3 ma charakter edukacyjny (w zarządzanych klastrach zwykle nie ma nodów master dostępnych)

## Kolejność wykonywania ćwiczeń

Ćwiczenia można wykonywać w dowolnej kolejności, ale zalecana kolejność:

1. **Job** - najprostsze, nie wymaga dodatkowych komponentów
2. **CronJob** - rozszerzenie Job
3. **StatefulSet** - wymaga Headless Service
4. **DaemonSet** - wymaga zrozumienia nodów
5. **Storage** - wymaga zrozumienia PV/PVC/SC
6. **Ingress** - wymaga kontrolera Ingress

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
kubectl delete pvc --all -n cwiczenia
kubectl delete ingress --all -n cwiczenia
kubectl delete cronjob --all -n cwiczenia
kubectl delete job --all -n cwiczenia
kubectl delete statefulset --all -n cwiczenia
kubectl delete daemonset --all -n cwiczenia
kubectl delete svc --all -n cwiczenia

# Usuń namespace
kubectl delete namespace cwiczenia
```

## Przydatne komendy

```bash
# Sprawdzanie statusu
kubectl get all -n cwiczenia
kubectl get pvc -n cwiczenia
kubectl get ingress -n cwiczenia

# Logi i debugowanie
kubectl logs <pod-name> -n cwiczenia
kubectl describe <resource> <name> -n cwiczenia
kubectl exec -it <pod-name> -n cwiczenia -- /bin/sh

# Obserwowanie zmian
kubectl get pods -n cwiczenia -w
kubectl get jobs -n cwiczenia -w
```

