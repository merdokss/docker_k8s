# Kubernetes Jobs i CronJobs

## Jobs

Jobs w Kubernetes są obiektami, które zarządzają wykonywaniem zadań wsadowych (batch). Ich głównym celem jest uruchomienie jednego lub więcej podów, które wykonają określone zadanie i zakończą działanie po jego ukończeniu.

### Charakterystyka Jobs

- Gwarantują, że zadanie zostanie pomyślnie wykonane
- Śledzą pomyślne zakończenie podów
- Można określić ile razy zadanie ma być wykonane
- Można ustawić limit czasu wykonania zadania
- Obsługują równoległe wykonywanie zadań

### Przykład użycia Job

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
        image: perl:5.34.0
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

W tym przykładzie:
- Job uruchamia pod, który oblicza wartość liczby PI
- `backoffLimit: 4` oznacza, że Kubernetes podejmie maksymalnie 4 próby ponownego uruchomienia w przypadku niepowodzenia
- `restartPolicy: Never` określa, że pod nie powinien być automatycznie restartowany

### Zaawansowane opcje Jobs

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-processing
spec:
  completions: 6        # całkowita liczba podów do ukończenia
  parallelism: 2        # ile podów może działać równolegle
  activeDeadlineSeconds: 100  # maksymalny czas wykonania
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ["sh", "-c", "echo Processing chunk $JOB_COMPLETION_INDEX; sleep 5"]
      restartPolicy: Never
```

## CronJobs

CronJob jest rozszerzeniem koncepcji Job, które pozwala na cykliczne wykonywanie zadań według harmonogramu, podobnie jak Unix Cron.

### Charakterystyka CronJobs

- Automatyczne tworzenie Jobs według zdefiniowanego harmonogramu
- Używa składni cron do definiowania harmonogramu
- Może zarządzać równoczesnymi lub nakładającymi się zadaniami
- Pozwala na określenie polityki zachowania historii wykonanych zadań

### Przykład użycia CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-database
spec:
  schedule: "0 3 * * *"        # Uruchomienie o 3:00 każdego dnia
  concurrencyPolicy: Forbid    # Nie pozwala na równoległe wykonywanie
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: database-backup:latest
            command: ["/bin/sh", "-c", "echo Wykonuję backup bazy danych"]
          restartPolicy: OnFailure
```

### Składnia harmonogramu CronJob

Format: `* * * * *`
- Minuta (0-59)
- Godzina (0-23)
- Dzień miesiąca (1-31)
- Miesiąc (1-12)
- Dzień tygodnia (0-6, 0=Niedziela)

Przykłady:
- `*/5 * * * *` - co 5 minut
- `0 3 * * *` - codziennie o 3:00
- `0 0 * * 0` - w każdą niedzielę o północy
- `0 0 1 * *` - pierwszego dnia każdego miesiąca

### Główne różnice między Job a CronJob

1. **Czas wykonania**:
   - Job: jednorazowe wykonanie lub określona liczba powtórzeń
   - CronJob: cykliczne wykonywanie według harmonogramu

2. **Zarządzanie**:
   - Job: wymaga ręcznego uruchomienia lub triggera
   - CronJob: automatyczne uruchamianie według harmonogramu

3. **Przypadki użycia**:
   - Job: jednorazowe zadania, przetwarzanie wsadowe, migracje
   - CronJob: backup-y, raporty okresowe, czyszczenie danych, monitoring

## Dobre praktyki

1. Zawsze ustawiaj `activeDeadlineSeconds` dla Jobs, aby uniknąć nieskończonego wykonywania
2. Używaj `concurrencyPolicy` w CronJobs do zarządzania nakładającymi się wykonaniami
3. Monitoruj historię wykonanych zadań i ustawiaj odpowiednie limity
4. Testuj harmonogramy CronJob przed wdrożeniem produkcyjnym
5. Używaj odpowiednich polityk restartowania (`restartPolicy`)