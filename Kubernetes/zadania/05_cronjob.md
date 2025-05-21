# Zadania - CronJob w Kubernetes

## Zadanie 1: Podstawowy CronJob
1. Utwórz CronJob o nazwie `backup-db`, który będzie wykonywał się co godzinę.
2. Skonfiguruj CronJob tak, aby używał obrazu z narzędziami do backupu bazy danych.
3. Zweryfikuj, czy CronJob został poprawnie utworzony i czy generuje Jobs zgodnie z harmonogramem.

## Zadanie 2: CronJob z Concurrency Policy
1. Skonfiguruj CronJob z różnymi politykami współbieżności (`Allow`, `Forbid`, `Replace`).
2. Symuluj sytuację, w której nowy Job jest uruchamiany, gdy poprzedni jeszcze się nie zakończył.
3. Zweryfikuj zachowanie CronJob dla każdej z polityk współbieżności.

## Zadanie 3: CronJob z Starting Deadline
1. Skonfiguruj CronJob z `startingDeadlineSeconds`.
2. Symuluj sytuację, w której węzeł jest niedostępny w momencie planowanego uruchomienia.
3. Zweryfikuj, czy Jobs są uruchamiane po powrocie węzła do działania.

## Zadanie 4: CronJob z Successful Jobs History Limit
1. Skonfiguruj CronJob z limitem historii udanych Jobs.
2. Pozwól na wykonanie kilku Jobs.
3. Zweryfikuj, czy historia Jobs jest poprawnie zarządzana zgodnie z limitem.

## Zadanie 5: CronJob z Failed Jobs History Limit
1. Skonfiguruj CronJob z limitem historii nieudanych Jobs.
2. Symuluj sytuacje, w których Jobs kończą się niepowodzeniem.
3. Zweryfikuj, czy historia nieudanych Jobs jest poprawnie zarządzana.

## Wymagania:
- Znajomość podstawowych konceptów Kubernetes
- Dostęp do klastra Kubernetes
- Narzędzia: kubectl

## Przydatne komendy:
```bash
kubectl get cronjobs
kubectl get jobs
kubectl describe cronjob <nazwa-cronjob>
kubectl logs <nazwa-poda>
kubectl delete cronjob <nazwa-cronjob>
```

## Dodatkowe wskazówki:
- Używaj `kubectl get jobs` do monitorowania utworzonych Jobs
- Sprawdzaj logi podów, aby zweryfikować poprawność wykonania zadań
- Używaj `kubectl describe cronjob` do sprawdzenia szczegółów konfiguracji
- Pamiętaj o czyszczeniu historii Jobs, aby nie zaśmiecać klastra 