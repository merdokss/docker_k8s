# Kubernetes Operators - Przewodnik

## Czym jest Operator Kubernetes?

**Operator** to rozszerzenie Kubernetes, które automatyzuje zarządzanie aplikacjami stanowymi (stateful applications) poprzez **kod aplikacyjny** działający w klastrze. Operator to w istocie **kontroler z wiedzą domenową** - rozumie specyfikę konkretnej aplikacji i potrafi zarządzać jej pełnym cyklem życia.

### Kluczowe różnice: Operator vs Helm

| Aspekt | Helm | Operator |
|--------|------|----------|
| **Podejście** | Szablony YAML + templating | Kontroler Go/Python z logiką biznesową |
| **Zarządzanie** | Statyczne manifesty | Dynamiczne, reaktywne zarządzanie |
| **Wiedza domenowa** | Brak - tylko templating | Pełna wiedza o aplikacji |
| **Automatyzacja** | Instalacja/upgrade/rollback | Pełny cykl życia + healing + backup |
| **Obserwacja** | Brak | Ciągłe monitorowanie i reakcje |
| **Przykłady** | Wszystkie aplikacje | Bazy danych, message queue, monitoring |

**Helm** = menedżer pakietów (jak apt/yum) - instaluje i konfiguruje  
**Operator** = ekspert domenowy - zarządza, monitoruje i naprawia

## Jak działa Operator?

```
1. Custom Resource Definition (CRD) - definiuje nowy typ zasobu
2. Controller - obserwuje CRD i reaguje na zmiany
3. Reconcile Loop - ciągła pętla porównująca stan pożądany z rzeczywistym
4. Automatyczne akcje - backup, restore, scaling, failover
```

## Przykład: CloudNativePG Operator dla PostgreSQL

CloudNativePG to nowoczesny operator PostgreSQL, który automatyzuje:
- Deployment i konfigurację
- Backup i restore
- Failover i high availability
- Upgrades
- Monitoring i health checks

### Instalacja Operatora

```bash
# 1. Zainstaluj operator w klastrze
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.23/releases/cnpg-1.23.0.yaml

# 2. Sprawdź instalację
kubectl get pods -n cnpg-system
kubectl get crd | grep postgresql

# 3. Utwórz namespace dla PostgreSQL
kubectl create namespace postgres
```

### Przykład: Prosta instancja PostgreSQL

**Tradycyjne podejście (Deployment + PVC):**
```yaml
# deployment-pvc.yaml - TRADYCYJNE
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_PASSWORD
          value: mypassword
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 10Gi
```

**Podejście z Operatorem (CloudNativePG):**
```yaml
# postgres-cluster.yaml - Z OPERATOREM
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-cluster
  namespace: postgres
spec:
  instances: 3  # Automatyczna replikacja!
  
  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"
  
  storage:
    size: 20Gi
    storageClass: standard
  
  backup:
    barmanObjectStore:
      destinationPath: s3://backup-bucket/postgres
      s3Credentials:
        accessKeyId:
          name: backup-credentials
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: backup-credentials
          key: SECRET_ACCESS_KEY
      wal:
        retention: "7d"
      data:
        retention: "30d"
  
  monitoring:
    enabled: true
    podMonitorEnabled: true
```

### Instalacja przykładu

```bash
# 1. Zastosuj konfigurację
kubectl apply -f postgres-cluster.yaml

# 2. Obserwuj tworzenie klastra
kubectl get cluster -n postgres
kubectl get pods -n postgres -w

# 3. Sprawdź szczegóły
kubectl describe cluster postgres-cluster -n postgres
```

### Różnice w zarządzaniu

#### Tradycyjne zarządzanie (Deployment)
```bash
# Backup - ręcznie
kubectl exec postgres-pod -- pg_dump > backup.sql

# Failover - ręcznie
kubectl delete pod postgres-pod  # i czekać na restart

# Scaling - ręcznie edytować replicas
kubectl scale deployment postgres --replicas=3

# Upgrade - ręcznie zmienić image
kubectl set image deployment/postgres postgres=postgres:14
```

#### Zarządzanie przez Operator
```bash
# Backup - automatyczny lub na żądanie
kubectl cnpg backup postgres-cluster -n postgres

# Failover - automatyczny
# Operator sam wykryje awarię i promuje replikę

# Scaling - deklaratywnie
kubectl patch cluster postgres-cluster -n postgres --type merge -p '{"spec":{"instances":5}}'

# Upgrade - deklaratywnie
kubectl patch cluster postgres-cluster -n postgres --type merge -p '{"spec":{"postgresql":{"image":"postgres:14"}}}'
```

### Zaawansowane funkcje Operatora

#### 1. Automatyczny Backup
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: backup-manual
  namespace: postgres
spec:
  cluster:
    name: postgres-cluster
  method: barmanObjectStore
```

#### 2. Restore z backupu
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-restored
spec:
  instances: 3
  bootstrap:
    recovery:
      source: postgres-cluster
      backup:
        name: backup-manual
```

#### 3. Monitoring i metryki
Operator automatycznie eksponuje metryki Prometheus:
```bash
kubectl get servicemonitor -n postgres
kubectl port-forward -n postgres svc/postgres-cluster-rw 5432:5432
```

### Porównanie: Tradycyjne vs Operator

| Zadanie | Tradycyjne (Deployment) | Operator (CloudNativePG) |
|---------|------------------------|--------------------------|
| **Deployment** | Ręczne YAML | Jeden CRD |
| **Replikacja** | StatefulSet + ręczna konfiguracja | Automatyczna z `instances: 3` |
| **Backup** | CronJob + skrypty | Wbudowane, deklaratywne |
| **Failover** | Ręczne promowanie repliki | Automatyczne wykrywanie i promowanie |
| **Upgrade** | Ręczna zmiana image | Rolling upgrade z walidacją |
| **Monitoring** | Ręczne setup Prometheus | Automatyczne ServiceMonitor |
| **Health checks** | Probes w Deployment | Zaawansowane sprawdzanie stanu DB |
| **Configuration** | ConfigMap + restart | Hot reload niektórych parametrów |
| **Maintenance** | Wysoki - wiele skryptów | Niski - operator zarządza |

### Kiedy używać Operatora?

**Używaj Operatora gdy:**
- ✅ Zarządzasz aplikacjami stanowymi (bazy danych, message queue)
- ✅ Potrzebujesz automatycznego backup/restore
- ✅ Wymagasz high availability i automatycznego failover
- ✅ Chcesz uprościć operacyjne zarządzanie
- ✅ Potrzebujesz zaawansowanych funkcji (point-in-time recovery, etc.)

**Używaj Helm gdy:**
- ✅ Wdrażasz stateless aplikacje
- ✅ Proste wdrożenia bez zaawansowanej logiki
- ✅ Wystarczy templating i podstawowa konfiguracja
- ✅ Nie potrzebujesz ciągłego zarządzania

### Popularne Operatory

- **PostgreSQL**: CloudNativePG, Zalando Postgres Operator
- **MySQL**: MySQL Operator (Oracle), Vitess
- **MongoDB**: MongoDB Community Operator
- **Redis**: Redis Operator, Spotahome Redis Operator
- **Kafka**: Strimzi, Confluent Operator
- **Elasticsearch**: Elastic Cloud on Kubernetes (ECK)
- **Prometheus**: Prometheus Operator
- **Certificates**: cert-manager

### Przydatne komendy

```bash
# Sprawdź zainstalowane operatory
kubectl get crd | grep operator

# Lista clusterów PostgreSQL (CloudNativePG)
kubectl get cluster -A

# Szczegóły klastra
kubectl describe cluster <nazwa> -n <namespace>

# Logi operatora
kubectl logs -n cnpg-system -l app.kubernetes.io/name=cloudnative-pg

# Backup na żądanie
kubectl cnpg backup <cluster-name> -n <namespace>

# Lista backupów
kubectl get backup -n <namespace>

# Restore
kubectl apply -f restore-cluster.yaml
```

### Podsumowanie

**Operator** to następny poziom automatyzacji w Kubernetes - nie tylko instaluje aplikacje, ale **inteligentnie nimi zarządza** przez cały cykl życia. Dla aplikacji stanowych jak bazy danych, operator jest często **niezbędny** do zapewnienia niezawodności, backupów i high availability w sposób, którego Helm sam nie może zapewnić.

## Szybki Start

Zobacz [QUICKSTART.md](QUICKSTART.md) dla szybkiego przewodnika instalacji i użycia.

### Dostępne przykłady

- `postgres-cluster-basic.yaml` - Podstawowy klaster PostgreSQL (1 instancja)
- `postgres-cluster-ha.yaml` - Wysokiej dostępności klaster z replikacją (3 instancje)
- `postgres-backup-manual.yaml` - Przykład ręcznego backupu
- `postgres-restore.yaml` - Przykład restore z backupu
- `traditional-postgres.yaml` - Tradycyjne podejście dla porównania
- `install-operator.sh` - Skrypt instalacji CloudNativePG Operator

