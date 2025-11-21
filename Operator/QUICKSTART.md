# Quick Start - CloudNativePG Operator

Szybki przewodnik instalacji i użycia operatora PostgreSQL.

## 1. Instalacja Operatora

```bash
# Opcja A: Użyj skryptu
chmod +x install-operator.sh
./install-operator.sh

# Opcja B: Ręczna instalacja
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.23/releases/cnpg-1.23.0.yaml

# Sprawdź instalację
kubectl get pods -n cnpg-system
kubectl get crd | grep postgresql
```

## 2. Utworzenie namespace

```bash
kubectl create namespace postgres
```

## 3. Deploy podstawowego klastra

```bash
# Podstawowy klaster (1 instancja)
kubectl apply -f postgres-cluster-basic.yaml

# Lub HA klaster (3 instancje)
kubectl apply -f postgres-cluster-ha.yaml

# Obserwuj tworzenie
kubectl get cluster -n postgres -w
kubectl get pods -n postgres -w
```

## 4. Sprawdź status

```bash
# Lista klastrów
kubectl get cluster -n postgres

# Szczegóły klastra
kubectl describe cluster postgres-basic -n postgres

# Pody
kubectl get pods -n postgres

# Logi
kubectl logs -n postgres <pod-name>
```

## 5. Połącz się z bazą

```bash
# Znajdź service
kubectl get svc -n postgres

# Port forward
kubectl port-forward -n postgres svc/postgres-basic-rw 5432:5432

# Połącz się (w innym terminalu)
psql -h localhost -U myapp -d myapp
# Hasło: myapp-password (z Secret)
```

## 6. Operacje zarządzania

### Backup
```bash
# Automatyczny backup (jeśli skonfigurowany w klastrze)
kubectl get backup -n postgres

# Ręczny backup
kubectl apply -f postgres-backup-manual.yaml
```

### Scaling
```bash
# Zwiększ liczbę instancji
kubectl patch cluster postgres-basic -n postgres \
  --type merge -p '{"spec":{"instances":3}}'

# Sprawdź
kubectl get pods -n postgres
```

### Upgrade
```bash
# Zmień wersję PostgreSQL
kubectl patch cluster postgres-basic -n postgres \
  --type merge -p '{"spec":{"imageName":"docker.io/postgres:16"}}'
```

## 7. Porównanie z tradycyjnym podejściem

```bash
# Deploy tradycyjnego PostgreSQL
kubectl apply -f traditional-postgres.yaml

# Porównaj:
# - Liczbę zasobów (Operator: 1 CRD vs Tradycyjne: 3+ zasoby)
# - Możliwości (backup, HA, failover)
# - Zarządzanie
```

## Przydatne komendy

```bash
# Status klastra
kubectl get cluster -A
kubectl describe cluster <name> -n <namespace>

# Backup
kubectl get backup -n postgres
kubectl describe backup <name> -n postgres

# Logi operatora
kubectl logs -n cnpg-system -l app.kubernetes.io/name=cloudnative-pg

# Events
kubectl get events -n postgres --sort-by='.lastTimestamp'
```

## Troubleshooting

```bash
# Jeśli pody nie startują
kubectl describe pod <pod-name> -n postgres
kubectl logs <pod-name> -n postgres

# Sprawdź PVC
kubectl get pvc -n postgres

# Sprawdź storage class
kubectl get storageclass

# Jeśli operator nie działa
kubectl get pods -n cnpg-system
kubectl logs -n cnpg-system -l app.kubernetes.io/name=cloudnative-pg
```

## Cleanup

```bash
# Usuń klaster
kubectl delete cluster postgres-basic -n postgres

# Usuń namespace (uwaga: usuwa wszystkie zasoby!)
kubectl delete namespace postgres

# Usuń operatora
kubectl delete -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.23/releases/cnpg-1.23.0.yaml
```

