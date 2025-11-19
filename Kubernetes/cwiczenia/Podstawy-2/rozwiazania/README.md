# Rozwiązania ćwiczeń - Podstawy-2

Ten katalog zawiera rozwiązania wszystkich ćwiczeń z katalogu `Podstawy-2`.

## Struktura plików

Pliki są nazywane według wzorca: `<typ>-<numer-cwiczenia>-<nazwa>.yaml`

Przykłady:
- `job-4.1-hello-job.yaml` - Ćwiczenie 4.1 z Job
- `statefulset-2.1-web-sts.yaml` - Ćwiczenie 2.1 ze StatefulSet
- `ingress-1.1-nginx-deployment.yaml` - Deployment dla ćwiczenia 1.1 z Ingress

## Jak używać rozwiązań

### 1. Przygotowanie namespace

```bash
kubectl create namespace cwiczenia
```

### 2. Aplikowanie rozwiązań

Każde ćwiczenie może wymagać kilku plików YAML. Aplikuj je w odpowiedniej kolejności:

**Przykład - StatefulSet (ćwiczenie 2.1):**
```bash
# Najpierw Service (Headless)
kubectl apply -f statefulset-2.1-web-sts-service.yaml

# Potem StatefulSet
kubectl apply -f statefulset-2.1-web-sts.yaml
```

**Przykład - Ingress (ćwiczenie 1.1):**
```bash
# 1. Deployment
kubectl apply -f ingress-1.1-nginx-deployment.yaml

# 2. Service
kubectl apply -f ingress-1.1-nginx-svc.yaml

# 3. Ingress (wymaga kontrolera Ingress)
kubectl apply -f ingress-1.1-nginx-ingress.yaml
```

### 3. Weryfikacja

Użyj komend weryfikacyjnych z plików ćwiczeń w katalogu głównym.

## Uwagi dotyczące środowiska

### Ingress
- Ćwiczenia z Ingress wymagają zainstalowanego kontrolera Ingress (np. NGINX Ingress Controller)
- W AKS możesz użyć Application Gateway Ingress Controller (AGIC) lub NGINX Ingress Controller
- Jeśli nie masz kontrolera, Ingress pozostanie w stanie Pending

### Storage
- W AKS używane są StorageClass specyficzne dla Azure (`default`, `azurefile`, `managed`)
- Ćwiczenie 6.2 (PV statyczny) używa `hostPath`, który działa tylko w środowiskach lokalnych (Kind, Minikube)
- W AKS użyj dynamicznego provisioningu przez StorageClass

### DaemonSet
- Ćwiczenie 3.2 wymaga oznaczenia noda etykietą: `kubectl label nodes <node-name> monitoring=enabled`
- Ćwiczenie 3.3 wymaga nodów z taintami (w AKS zwykle nie ma nodów master z taintami)

### CronJob
- Harmonogramy są ustawione na rzeczywiste wartości (np. codziennie o 2:00)
- Dla testów możesz zmienić harmonogram na częstszy (np. `*/1 * * * *`)

## Czyszczenie

Aby usunąć wszystkie zasoby:

```bash
# Usuń wszystkie zasoby z namespace
kubectl delete all --all -n cwiczenia
kubectl delete pvc --all -n cwiczenia
kubectl delete ingress --all -n cwiczenia
kubectl delete cronjob --all -n cwiczenia
kubectl delete job --all -n cwiczenia
kubectl delete statefulset --all -n cwiczenia
kubectl delete daemonset --all -n cwiczenia

# Usuń namespace
kubectl delete namespace cwiczenia
```

## Lista wszystkich plików rozwiązań

### Job
- `job-4.1-hello-job.yaml`
- `job-4.2-batch-job.yaml`
- `job-4.3-parallel-job.yaml`
- `job-4.4-timeout-job.yaml`

### StatefulSet
- `statefulset-2.1-web-sts-service.yaml`
- `statefulset-2.1-web-sts.yaml`
- `statefulset-2.2-db-sts-service.yaml`
- `statefulset-2.2-db-sts.yaml`
- `statefulset-2.3-app-sts-service.yaml`
- `statefulset-2.3-app-sts.yaml`

### DaemonSet
- `daemonset-3.1-fluentd-logging.yaml`
- `daemonset-3.2-node-monitor.yaml`
- `daemonset-3.3-system-daemon.yaml`

### CronJob
- `cronjob-5.1-hello-cronjob.yaml`
- `cronjob-5.2-daily-backup.yaml`
- `cronjob-5.2-hourly-report.yaml`
- `cronjob-5.2-weekly-cleanup.yaml`
- `cronjob-5.3-limited-history.yaml`
- `cronjob-5.4-long-running.yaml`

### Storage
- `storage-6.1-app-data-pvc.yaml`
- `storage-6.1-app-pod.yaml`
- `storage-6.3-fast-ssd-sc.yaml`
- `storage-6.3-fast-pvc.yaml`
- `storage-6.4-pvc-rwo.yaml`
- `storage-6.4-pvc-rwm.yaml`
- `storage-6.4-pvc-rom.yaml`
- `storage-6.4-multi-pvc-deployment.yaml`

### Ingress
- `ingress-1.1-nginx-deployment.yaml`
- `ingress-1.1-nginx-svc.yaml`
- `ingress-1.1-nginx-ingress.yaml`
- `ingress-1.2-app1-deployment.yaml`
- `ingress-1.2-app2-deployment.yaml`
- `ingress-1.2-app1-svc.yaml`
- `ingress-1.2-app2-svc.yaml`
- `ingress-1.2-multi-path-ingress.yaml`
- `ingress-1.3-secure-app-deployment.yaml`
- `ingress-1.3-secure-svc.yaml`
- `ingress-1.3-secure-ingress.yaml`

## Tworzenie Secret dla TLS (ćwiczenie 1.3)

```bash
# Wygeneruj self-signed certyfikat
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=secure.local"

# Utwórz Secret
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key \
  -n cwiczenia

# Usuń pliki certyfikatów
rm tls.key tls.crt
```

