# Zadania - Job w Kubernetes

## Zadanie 1: Podstawowy Job
1. Utwórz Job o nazwie `pi-calculator`, który będzie wykonywał obliczenia liczby Pi.
2. Skonfiguruj Job tak, aby używał obrazu `perl` i wykonywał skrypt obliczający Pi.
3. Zweryfikuj, czy Job został poprawnie wykonany i zakończył się sukcesem.

## Zadanie 2: Parallel Jobs
1. Utwórz Job, który będzie uruchamiał wiele równoległych zadań.
2. Skonfiguruj `parallelism` i `completions` dla Job.
3. Zweryfikuj, czy wszystkie zadania zostały poprawnie wykonane.

## Zadanie 3: Job z Backoff Limit
1. Utwórz Job, który będzie miał skonfigurowany `backoffLimit`.
2. Symuluj błędy w Job, aby sprawdzić zachowanie przy przekroczeniu limitu.
3. Zweryfikuj, czy Job został odpowiednio zakończony po przekroczeniu limitu.

## Zadanie 4: Job z Active Deadline
1. Skonfiguruj Job z `activeDeadlineSeconds`.
2. Utwórz Job, który będzie wykonywał się dłużej niż ustawiony deadline.
3. Zweryfikuj, czy Job został przerwany po przekroczeniu deadline.

## Zadanie 5: Job z TTL
1. Skonfiguruj Job z `ttlSecondsAfterFinished`.
2. Utwórz i wykonaj Job.
3. Zweryfikuj, czy Job został automatycznie usunięty po upływie TTL.

## Wymagania:
- Znajomość podstawowych konceptów Kubernetes
- Dostęp do klastra Kubernetes
- Narzędzia: kubectl

## Przydatne komendy:
```bash
kubectl get jobs
kubectl get pods
kubectl describe job <nazwa-job>
kubectl logs <nazwa-poda>
kubectl delete job <nazwa-job>
``` 