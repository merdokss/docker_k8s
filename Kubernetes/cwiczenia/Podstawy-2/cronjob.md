# Kubernetes - Ćwiczenia: CronJob

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć CronJob w Kubernetes. CronJob tworzy Joby okresowo zgodnie z harmonogramem wyrażonym w formacie Cron.

**Co to jest CronJob?** CronJob tworzy Joby okresowo zgodnie z harmonogramem wyrażonym w formacie Cron. CronJob jest przydatny do zadań okresowych, takich jak backup, raporty, czyszczenie.

## Ćwiczenie 5.1: Podstawowy CronJob

**Zadanie:** Utwórz CronJob `hello-cronjob` w namespace `cwiczenia`, który uruchamia się co minutę i wykonuje komendę `echo "Scheduled task executed at $(date)"`.

> **Uwaga:** Harmonogram `* * * * *` oznacza co minutę. Dla testów możesz użyć częstszego harmonogramu, ale pamiętaj, że w środowisku produkcyjnym lepiej używać rozsądnych harmonogramów.

**Wskazówki:**
- Użyj `apiVersion: batch/v1` i `kind: CronJob`
- W `spec.schedule` użyj formatu Cron: `"* * * * *"` (co minutę)
- Format Cron: `minuta godzina dzień miesiąc dzień-tygodnia`
- W `spec.jobTemplate` zdefiniuj szablon Job

**Cel:** Zrozumienie podstawowej konfiguracji CronJob i formatu Cron.

**Weryfikacja:**
```bash
# Sprawdź CronJob
kubectl get cronjob hello-cronjob

# Zobacz szczegóły
kubectl describe cronjob hello-cronjob

# Poczekaj 1-2 minuty i sprawdź utworzone Joby
kubectl get jobs

# Zobacz Pody utworzone przez Joby
kubectl get pods

# Sprawdź logi
kubectl logs -l job-name=<nazwa-joba> --tail=20
```

---

## Ćwiczenie 5.2: CronJob z różnymi harmonogramami

**Zadanie:** Utwórz trzy CronJoby w namespace `cwiczenia` z różnymi harmonogramami:
1. `daily-backup` - uruchamia się codziennie o 2:00 w nocy
2. `hourly-report` - uruchamia się co godzinę
3. `weekly-cleanup` - uruchamia się w każdy poniedziałek o 3:00

**Wskazówki:**
- Format Cron: `minuta godzina dzień miesiąc dzień-tygodnia`
- `0 2 * * *` - codziennie o 2:00
- `0 * * * *` - co godzinę
- `0 3 * * 1` - w poniedziałki o 3:00 (1 = poniedziałek, 0 = niedziela)

**Cel:** Zrozumienie różnych harmonogramów w CronJob.

**Weryfikacja:**
```bash
# Sprawdź wszystkie CronJoby
kubectl get cronjobs

# Zobacz szczegóły każdego
kubectl describe cronjob daily-backup
kubectl describe cronjob hourly-report
kubectl describe cronjob weekly-cleanup

# Sprawdź ostatnie wykonania (LAST SCHEDULE)
kubectl get cronjobs
```

---

## Ćwiczenie 5.3: CronJob z limitem historii

**Zadanie:** Utwórz CronJob `limited-history` w namespace `cwiczenia` z harmonogramem `*/2 * * * *` (co 2 minuty), który:
- Przechowuje tylko 3 ostatnie udane Joby (`successfulJobsHistoryLimit: 3`)
- Przechowuje tylko 1 nieudany Job (`failedJobsHistoryLimit: 1`)

**Wskazówki:**
- `successfulJobsHistoryLimit` - liczba udanych Jobów do przechowania
- `failedJobsHistoryLimit` - liczba nieudanych Jobów do przechowania
- Stare Joby są automatycznie usuwane

**Cel:** Zrozumienie zarządzania historią Jobów w CronJob.

**Weryfikacja:**
```bash
# Sprawdź CronJob
kubectl get cronjob limited-history

# Poczekaj kilka minut (aby utworzyło się kilka Jobów)
# Sprawdź liczbę Jobów
kubectl get jobs

# Powinno być maksymalnie 3 udane Joby i 1 nieudany
# Sprawdź szczegóły CronJob
kubectl describe cronjob limited-history
```

---

## Ćwiczenie 5.4: CronJob z konkurującymi wykonaniami

**Zadanie:** Utwórz CronJob `long-running` w namespace `cwiczenia` z harmonogramem `*/1 * * * *` (co minutę), który wykonuje zadanie trwające 90 sekund. Skonfiguruj CronJob tak, aby:
- Nie uruchamiał nowego Joba, jeśli poprzedni jeszcze działa (`concurrencyPolicy: Forbid`)

**Wskazówki:**
- `concurrencyPolicy` może być:
  - `Allow` (domyślnie) - pozwala na równoczesne wykonania
  - `Forbid` - zabrania nowego wykonania, jeśli poprzednie jeszcze działa
  - `Replace` - zastępuje poprzednie wykonanie nowym
- Użyj `sleep 90` jako komendy w Job

**Cel:** Zrozumienie kontroli równoległości w CronJob.

**Weryfikacja:**
```bash
# Sprawdź CronJob
kubectl get cronjob long-running

# Obserwuj Joby i Pody
kubectl get jobs -w
kubectl get pods -w

# Zauważ, że nowy Job nie zostanie utworzony, jeśli poprzedni jeszcze działa
# Sprawdź szczegóły
kubectl describe cronjob long-running
```

---

## Podsumowanie

Po wykonaniu ćwiczeń z CronJob powinieneś:
- ✅ Rozumieć podstawową konfigurację CronJob i format Cron
- ✅ Umieć konfigurować różne harmonogramy
- ✅ Rozumieć zarządzanie historią Jobów
- ✅ Umieć kontrolować równoległość wykonania

## Przydatne komendy

```bash
# CronJob
kubectl get cronjobs
kubectl get cronjob <name>
kubectl describe cronjob <name>

# Joby utworzone przez CronJob
kubectl get jobs
kubectl get jobs -l <label>

# Pody i logi
kubectl get pods
kubectl logs -l job-name=<name>
```

## Format Cron - szybka referencja

```
* * * * *
│ │ │ │ │
│ │ │ │ └─── dzień tygodnia (0-7, gdzie 0 i 7 = niedziela)
│ │ │ └───── miesiąc (1-12)
│ │ └─────── dzień miesiąca (1-31)
│ └───────── godzina (0-23)
└─────────── minuta (0-59)

Przykłady:
*/5 * * * *     - co 5 minut
0 * * * *       - co godzinę
0 0 * * *       - codziennie o północy
0 0 * * 1       - w każdy poniedziałek o północy
0 9-17 * * 1-5  - od 9:00 do 17:00 w dni robocze
```

