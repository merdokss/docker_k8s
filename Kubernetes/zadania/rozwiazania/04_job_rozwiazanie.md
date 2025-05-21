# Rozwiązania - Job w Kubernetes

## Zadanie 1: Podstawowy Job

### 1. Utworzenie Job
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi-calculator
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

### 2. Weryfikacja
```bash
kubectl get jobs
kubectl get pods
kubectl logs <nazwa-poda>
```

## Zadanie 2: Parallel Jobs

### 1. Utworzenie Job z Parallelism
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-job
spec:
  parallelism: 3
  completions: 5
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ["sh", "-c", "echo 'Processing item $JOB_COMPLETION_INDEX' && sleep 5"]
      restartPolicy: Never
```

### 2. Weryfikacja
```bash
kubectl get jobs
kubectl get pods
kubectl logs <nazwa-poda>
```

## Zadanie 3: Job z Backoff Limit

### 1. Utworzenie Job z Backoff Limit
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: failing-job
spec:
  backoffLimit: 3
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
kubectl get jobs
kubectl get pods
kubectl describe job failing-job
```

## Zadanie 4: Job z Active Deadline

### 1. Utworzenie Job z Active Deadline
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: long-running-job
spec:
  activeDeadlineSeconds: 30
  template:
    spec:
      containers:
      - name: long-running
        image: busybox
        command: ["sh", "-c", "sleep 60"]
      restartPolicy: Never
```

### 2. Weryfikacja
```bash
kubectl get jobs
kubectl get pods
kubectl describe job long-running-job
```

## Zadanie 5: Job z TTL

### 1. Utworzenie Job z TTL
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ttl-job
spec:
  ttlSecondsAfterFinished: 100
  template:
    spec:
      containers:
      - name: ttl-container
        image: busybox
        command: ["sh", "-c", "echo 'Job completed' && sleep 5"]
      restartPolicy: Never
```

### 2. Weryfikacja
```bash
kubectl get jobs
kubectl get pods
# Poczekaj 100 sekund
kubectl get jobs
```

## Przydatne wskazówki:
1. Zawsze definiuj odpowiedni `restartPolicy` dla Job
2. Używaj `backoffLimit` do kontroli liczby ponownych prób
3. Monitoruj status Job i podów
4. Pamiętaj o czyszczeniu zakończonych Job
5. Używaj `activeDeadlineSeconds` dla zadań, które nie powinny działać zbyt długo

## Dodatkowe komendy:
```bash
# Usunięcie wszystkich zakończonych Job
kubectl delete jobs --field-selector status.successful=1

# Sprawdzenie szczegółów Job
kubectl describe job <nazwa-job>

# Sprawdzenie logów wszystkich podów Job
kubectl logs -l job-name=<nazwa-job>
``` 