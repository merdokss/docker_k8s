# Kubernetes - Ćwiczenia: Job

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć Job w Kubernetes. Job tworzy jeden lub więcej Podów i zapewnia, że określona liczba z nich zakończy się pomyślnie.

**Co to jest Job?** Job tworzy jeden lub więcej Podów i zapewnia, że określona liczba z nich zakończy się pomyślnie. Gdy Pod zakończy się pomyślnie, Job jest uznawany za zakończony.

## Ćwiczenie 4.1: Podstawowy Job

**Zadanie:** Utwórz Job `hello-job` w namespace `cwiczenia`, który uruchamia kontener z obrazem `busybox:latest` wykonujący komendę `echo "Hello from Kubernetes Job!" && sleep 5`.

**Wskazówki:**
- Użyj `apiVersion: batch/v1` i `kind: Job`
- W `spec.template.spec.containers[].command` określ komendę do wykonania
- Job automatycznie usuwa Pod po pomyślnym zakończeniu (domyślnie)

**Cel:** Zrozumienie podstawowej koncepcji Job i wykonywania zadań jednorazowych.

**Weryfikacja:**
```bash
# Sprawdź Job
kubectl get job hello-job

# Zobacz Pody (powinien być jeden Pod)
kubectl get pods -l job-name=hello-job

# Sprawdź logi (zobaczysz output komendy)
kubectl logs -l job-name=hello-job

# Poczekaj chwilę i sprawdź status Job
kubectl get job hello-job
# Powinien pokazać COMPLETIONS: 1/1

# Sprawdź szczegóły
kubectl describe job hello-job
```

---

## Ćwiczenie 4.2: Job z wieloma kompletami

**Zadanie:** Utwórz Job `batch-job` w namespace `cwiczenia` z obrazem `busybox:latest`, który wykonuje komendę `echo "Processing item $ITEM"` dla 5 różnych elementów. Job powinien wykonać 5 zadań sekwencyjnie.

**Wskazówki:**
- Użyj `spec.completions: 5` aby określić liczbę pomyślnych ukończeń
- Użyj `spec.parallelism: 1` aby wykonywać zadania sekwencyjnie (jeden na raz)
- Każdy Pod może używać zmiennej środowiskowej do identyfikacji elementu
- Możesz użyć `fieldRef` aby uzyskać unikalną nazwę Poda: `valueFrom.fieldRef.fieldPath: metadata.name`

**Cel:** Zrozumienie Job z wieloma kompletami i kontroli równoległości.

**Weryfikacja:**
```bash
# Sprawdź Job
kubectl get job batch-job

# Obserwuj Pody (powinny być tworzone sekwencyjnie)
kubectl get pods -l job-name=batch-job -w

# Sprawdź logi wszystkich Podów
kubectl logs -l job-name=batch-job

# Sprawdź status Job (powinien pokazać COMPLETIONS: 5/5)
kubectl get job batch-job
```

---

## Ćwiczenie 4.3: Job równoległy

**Zadanie:** Utwórz Job `parallel-job` w namespace `cwiczenia` z obrazem `busybox:latest`, który wykonuje komendę `echo "Task $TASK_ID" && sleep 10` dla 10 zadań wykonywanych równolegle (3 jednocześnie).

**Wskazówki:**
- Użyj `spec.completions: 10` dla 10 zadań
- Użyj `spec.parallelism: 3` aby wykonywać 3 zadania jednocześnie
- Job automatycznie zarządza równoległością - gdy jeden Pod się zakończy, uruchomi się następny
- Obserwuj Pody: `kubectl get pods -l job-name=parallel-job -w` (powinno być maksymalnie 3 jednocześnie)

**Cel:** Zrozumienie równoległego wykonywania zadań w Job.

**Weryfikacja:**
```bash
# Sprawdź Job
kubectl get job parallel-job

# Obserwuj Pody (powinny być maksymalnie 3 jednocześnie)
kubectl get pods -l job-name=parallel-job -w

# Sprawdź status Job
kubectl get job parallel-job

# Zobacz wszystkie logi
kubectl logs -l job-name=parallel-job
```

---

## Ćwiczenie 4.4: Job z limitem czasu i ponownymi próbami

**Zadanie:** Utwórz Job `timeout-job` w namespace `cwiczenia` z obrazem `busybox:latest` wykonujący komendę `sleep 300` (5 minut) z:
- `activeDeadlineSeconds: 60` (limit czasu 60 sekund)
- `backoffLimit: 3` (maksymalnie 3 ponowne próby)

**Wskazówki:**
- `activeDeadlineSeconds` - maksymalny czas działania Job (w sekundach)
- `backoffLimit` - liczba ponownych prób przed uznaniem Job za nieudany
- Job zostanie przerwany po 60 sekundach

**Cel:** Zrozumienie limitów czasu i ponownych prób w Job.

**Weryfikacja:**
```bash
# Sprawdź Job
kubectl get job timeout-job

# Obserwuj Pody (Job powinien zostać przerwany po 60 sekundach)
kubectl get pods -l job-name=timeout-job -w

# Sprawdź status Job (powinien pokazać FAILED po przekroczeniu limitu)
kubectl get job timeout-job

# Zobacz szczegóły (sprawdź Events)
kubectl describe job timeout-job
```

---

## Podsumowanie

Po wykonaniu ćwiczeń z Job powinieneś:
- ✅ Rozumieć podstawową koncepcję Job i wykonywania zadań jednorazowych
- ✅ Umieć konfigurować Job z wieloma kompletami
- ✅ Rozumieć równoległe wykonywanie zadań w Job
- ✅ Umieć konfigurować limity czasu i ponowne próby

## Przydatne komendy

```bash
# Job
kubectl get jobs
kubectl get job <name>
kubectl describe job <name>
kubectl delete job <name>

# Pody Job
kubectl get pods -l job-name=<name>
kubectl logs -l job-name=<name>
kubectl describe pod <pod-name>

# Status i monitoring
kubectl get jobs -w
kubectl get pods -w
```

