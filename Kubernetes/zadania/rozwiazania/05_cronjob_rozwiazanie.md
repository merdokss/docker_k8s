# Rozwiązania - CronJob w Kubernetes

## Zadanie 1: Podstawowy CronJob

### 1. Utworzenie CronJob
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-db
spec:
  schedule: "0 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:13
            command:
            - /bin/sh
            - -c
            - |
              pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME > /backup/backup.sql
            env:
            - name: DB_HOST
              value: "postgres-service"
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: username
            - name: DB_NAME
              value: "mydb"
            volumeMounts:
            - name: backup-volume
              mountPath: /backup
          volumes:
          - name: backup-volume
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

### 2. Weryfikacja
```bash
kubectl get cronjobs
kubectl get jobs
kubectl get pods
```

## Zadanie 2: CronJob z Concurrency Policy

### 1. Utworzenie CronJob z różnymi politykami współbieżności
```yaml
# Polityka Allow
apiVersion: batch/v1
kind: CronJob
metadata:
  name: concurrent-job-allow
spec:
  schedule: "*/5 * * * *"
  concurrencyPolicy: Allow
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: long-running
            image: busybox
            command: ["sh", "-c", "sleep 300"]
          restartPolicy: OnFailure

---
# Polityka Forbid
apiVersion: batch/v1
kind: CronJob
metadata:
  name: concurrent-job-forbid
spec:
  schedule: "*/5 * * * *"
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: long-running
            image: busybox
            command: ["sh", "-c", "sleep 300"]
          restartPolicy: OnFailure

---
# Polityka Replace
apiVersion: batch/v1
kind: CronJob
metadata:
  name: concurrent-job-replace
spec:
  schedule: "*/5 * * * *"
  concurrencyPolicy: Replace
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: long-running
            image: busybox
            command: ["sh", "-c", "sleep 300"]
          restartPolicy: OnFailure
```

### 2. Weryfikacja
```bash
kubectl get cronjobs
kubectl get jobs
kubectl get pods
```

## Zadanie 3: CronJob z Starting Deadline

### 1. Utworzenie CronJob z Starting Deadline
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: deadline-job
spec:
  schedule: "*/5 * * * *"
  startingDeadlineSeconds: 100
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: deadline-container
            image: busybox
            command: ["sh", "-c", "echo 'Job started at $(date)' && sleep 10"]
          restartPolicy: OnFailure
```

### 2. Weryfikacja
```bash
kubectl get cronjobs
kubectl get jobs
kubectl describe cronjob deadline-job
```

## Zadanie 4: CronJob z Successful Jobs History Limit

### 1. Utworzenie CronJob z limitem historii
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: history-limit-job
spec:
  schedule: "*/5 * * * *"
  successfulJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: history-container
            image: busybox
            command: ["sh", "-c", "echo 'Job completed successfully'"]
          restartPolicy: OnFailure
```

### 2. Weryfikacja
```bash
kubectl get cronjobs
kubectl get jobs
# Poczekaj na wykonanie kilku zadań
kubectl get jobs
```

## Zadanie 5: CronJob z Failed Jobs History Limit

### 1. Utworzenie CronJob z limitem historii nieudanych zadań
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: failed-history-limit-job
spec:
  schedule: "*/5 * * * *"
  failedJobsHistoryLimit: 2
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: failing-container
            image: busybox
            command: ["sh", "-c", "exit 1"]
          restartPolicy: Never
```

### 2. Weryfikacja
```bash
kubectl get cronjobs
kubectl get jobs
# Poczekaj na wykonanie kilku zadań
kubectl get jobs
```

## Przydatne wskazówki:
1. Zawsze definiuj odpowiedni `restartPolicy` dla CronJob
2. Używaj `concurrencyPolicy` do kontroli równoległego wykonywania zadań
3. Monitoruj historię Job i podów
4. Pamiętaj o czyszczeniu starych Job
5. Używaj `startingDeadlineSeconds` dla zadań, które muszą być wykonane w określonym czasie

## Dodatkowe komendy:
```bash
# Sprawdzenie szczegółów CronJob
kubectl describe cronjob <nazwa-cronjob>

# Ręczne uruchomienie CronJob
kubectl create job --from=cronjob/<nazwa-cronjob> <nazwa-job>

# Sprawdzenie logów wszystkich podów CronJob
kubectl logs -l job-name=<nazwa-job>
``` 