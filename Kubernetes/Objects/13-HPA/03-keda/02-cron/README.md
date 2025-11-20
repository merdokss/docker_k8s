# KEDA z CRON - Przykład skalowania według harmonogramu

Ten przykład pokazuje jak używać KEDA do automatycznego skalowania aplikacji według harmonogramu CRON.

## Opis scenariusza

- Aplikacja wykonuje scheduled tasks (np. przetwarzanie raportów, backupy)
- KEDA skaluje aplikację zgodnie z harmonogramem CRON
- Poza godzinami pracy (wieczorem/w nocy) aplikacja skalowana do 0
- W godzinach szczytu (np. rano) aplikacja skalowana do większej liczby replik

## Przypadki użycia

- **Batch processing** - przetwarzanie danych o określonych porach
- **Scheduled reports** - generowanie raportów codziennie/co tydzień
- **Data synchronization** - synchronizacja danych między systemami
- **Cleanup jobs** - czyszczenie starych danych
- **Business hours scaling** - więcej replik w godzinach pracy

## Zawartość przykładu

1. `deployment.yaml` - Aplikacja do skalowania
2. `scaledobject-simple.yaml` - Prosty przykład z jednym harmonogramem
3. `scaledobject-business-hours.yaml` - Skalowanie w godzinach biznesowych
4. `scaledobject-multi-schedule.yaml` - Wiele harmonogramów jednocześnie

## Wymagania

- Zainstalowana KEDA w klastrze
- kubectl skonfigurowany

## Przykład 1: Prosty harmonogram CRON

### Wdrożenie

```bash
# Wdróż aplikację
kubectl apply -f deployment.yaml

# Wdróż ScaledObject z prostym harmonogramem
kubectl apply -f scaledobject-simple.yaml
```

### Harmonogram

```
08:00 - 18:00 (pon-pt) = 3 repliki
18:00 - 08:00 + weekendy = 0 replik
```

### Testowanie

```bash
# Sprawdź ScaledObject
kubectl get scaledobject cron-scaledobject

# Obserwuj zmiany liczby replik
kubectl get pods -l app=scheduled-app -w

# Sprawdź status HPA
kubectl get hpa
```

## Przykład 2: Business Hours Scaling

### Wdrożenie

```bash
kubectl apply -f deployment.yaml
kubectl apply -f scaledobject-business-hours.yaml
```

### Harmonogram

- **06:00-09:00 (pon-pt)**: 2 repliki - poranne uruchomienie
- **09:00-17:00 (pon-pt)**: 5 replik - godziny szczytu
- **17:00-22:00 (pon-pt)**: 2 repliki - wieczór
- **22:00-06:00 + weekendy**: 0 replik - noc i weekendy

### Monitoring

```bash
# Sprawdź aktualny desired replicas count
kubectl describe scaledobject business-hours-scaledobject

# Zobacz szczegóły HPA
kubectl describe hpa keda-hpa-business-hours-scaledobject
```

## Przykład 3: Multiple Schedules

Możesz mieć wiele triggers CRON jednocześnie - KEDA wybierze największą wartość.

```bash
kubectl apply -f deployment.yaml
kubectl apply -f scaledobject-multi-schedule.yaml
```

## Jak działają wyrażenia CRON w KEDA

### Format

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
│ │ │ │ │
* * * * *
```

### Przykłady wyrażeń CRON

```bash
# Co dzień o 8:00
0 8 * * *

# Co godzinę
0 * * * *

# Poniedziałek-Piątek o 9:00
0 9 * * 1-5

# Każdego 1. dnia miesiąca o północy
0 0 1 * *

# Co 15 minut w godzinach 9-17
*/15 9-17 * * *

# Weekendy
0 0 * * 0,6
```

### Strefy czasowe

KEDA domyślnie używa UTC. Możesz określić strefę czasową:

```yaml
triggers:
- type: cron
  metadata:
    timezone: Europe/Warsaw
    start: 0 9 * * 1-5
    end: 0 17 * * 1-5
    desiredReplicas: "5"
```

## Konfiguracja CRON Scaler

### Podstawowa konfiguracja

```yaml
triggers:
- type: cron
  metadata:
    timezone: Europe/Warsaw
    start: 0 9 * * 1-5      # Start o 9:00 pon-pt
    end: 0 17 * * 1-5       # End o 17:00 pon-pt
    desiredReplicas: "5"    # 5 replik w tym czasie
```

### Parametry

- `start` - CRON expression dla początku okna
- `end` - CRON expression dla końca okna
- `desiredReplicas` - liczba replik w oknie czasowym
- `timezone` - strefa czasowa (domyślnie UTC)

### Ważne uwagi

1. **desiredReplicas jest stringiem** - musi być w cudzysłowach: `"5"`
2. **Poza oknem** - KEDA skaluje do minReplicaCount (może być 0)
3. **Wiele okien** - możesz mieć wiele triggers, KEDA wybierze max
4. **Strefa czasowa** - sprawdź poprawność (użyj IANA timezone database)

## Scenariusze testowe

### Test 1: Manualne testowanie

Możesz zmienić time zone lub start/end aby szybko przetestować:

```yaml
# Dla testu ustaw start na "teraz + 2 minuty"
triggers:
- type: cron
  metadata:
    timezone: Europe/Warsaw
    start: 15 10 * * *     # Za 2 minuty od teraz (przykład)
    end: 20 10 * * *       # Za 7 minut
    desiredReplicas: "3"
```

```bash
# Obserwuj skalowanie
kubectl get pods -l app=scheduled-app -w
```

### Test 2: Sprawdź obliczenia KEDA

```bash
# KEDA loguje informacje o CRON w swoich logach
kubectl logs -n keda -l app=keda-operator | grep -i cron

# Sprawdź szczegóły ScaledObject
kubectl describe scaledobject <name>
```

## Best Practices

### 1. Używaj odpowiedniej strefy czasowej

```yaml
metadata:
  timezone: Europe/Warsaw  # Nie UTC jeśli obsługujesz lokalny biznes
```

### 2. Dodaj overlap dla graceful transitions

```yaml
# Schedule 1: Scale down o 17:00
- type: cron
  metadata:
    start: 0 9 * * 1-5
    end: 0 17 * * 1-5
    desiredReplicas: "5"

# Schedule 2: Minimum replicas 17:00-18:00 (overlap)
- type: cron
  metadata:
    start: 0 17 * * 1-5
    end: 0 18 * * 1-5
    desiredReplicas: "1"
```

### 3. Testuj harmonogramy

```bash
# Użyj online CRON expression tester
# https://crontab.guru/

# Sprawdź timezone
date
timedatectl  # Linux
```

### 4. Monitoruj zmiany

```bash
# Monitoruj events
kubectl get events --sort-by=.lastTimestamp | grep -i scale

# Sprawdź HPA metrics
kubectl get hpa -w
```

### 5. Kombinuj z innymi scalerami

Możesz łączyć CRON z innymi scalerami:

```yaml
triggers:
# CRON dla business hours
- type: cron
  metadata:
    start: 0 9 * * 1-5
    end: 0 17 * * 1-5
    desiredReplicas: "5"
# CPU dla auto-scaling w ramach business hours
- type: cpu
  metricType: Utilization
  metadata:
    value: "70"
```

## Przypadki użycia w praktyce

### 1. Przetwarzanie raportów nocnych

```yaml
# Wysoka moc obliczeniowa w nocy dla raportów
triggers:
- type: cron
  metadata:
    timezone: Europe/Warsaw
    start: 0 1 * * *      # 01:00 każdego dnia
    end: 0 6 * * *        # 06:00 każdego dnia
    desiredReplicas: "10"
```

### 2. Backup jobs

```yaml
# Backupy w weekendy
triggers:
- type: cron
  metadata:
    timezone: Europe/Warsaw
    start: 0 2 * * 0      # Niedziela 02:00
    end: 0 8 * * 0        # Niedziela 08:00
    desiredReplicas: "3"
```

### 3. E-commerce peak hours

```yaml
# Black Friday / Cyber Monday
triggers:
- type: cron
  metadata:
    timezone: Europe/Warsaw
    start: 0 0 26 11 *    # 26 listopada 00:00
    end: 0 0 27 11 *      # 27 listopada 00:00
    desiredReplicas: "20"
```

## Troubleshooting

### Problem: KEDA nie skaluje o oczekiwanej porze

```bash
# Sprawdź logi KEDA
kubectl logs -n keda -l app=keda-operator | grep cron

# Sprawdź timezone serwera
kubectl exec -n keda -it $(kubectl get pod -n keda -l app=keda-operator -o jsonpath='{.items[0].metadata.name}') -- date

# Sprawdź czy CRON expression jest poprawny
# Użyj https://crontab.guru/
```

### Problem: Nieprawidłowa strefa czasowa

```bash
# Lista dostępnych timezone
timedatectl list-timezones | grep Europe

# Sprawdź w ScaledObject
kubectl describe scaledobject <name> | grep -i timezone
```

### Problem: Replicas nie wracają do 0

```bash
# Sprawdź czy minReplicaCount jest ustawiony na 0
kubectl get scaledobject <name> -o yaml | grep minReplicaCount

# Sprawdź czy okno CRON się zakończyło
kubectl describe scaledobject <name>
```

## Cleanup

```bash
# Usuń wszystkie zasoby
kubectl delete -f .

# Lub pojedynczo
kubectl delete scaledobject --all
kubectl delete deployment scheduled-app
```

## Dalsze zasoby

- [KEDA CRON Scaler Docs](https://keda.sh/docs/2.12/scalers/cron/)
- [Cron Expression Generator](https://crontab.guru/)
- [IANA Timezone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

