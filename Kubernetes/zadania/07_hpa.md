# Zadania - Horizontal Pod Autoscaler w Kubernetes

## Zadanie 1: Podstawowa konfiguracja HPA
1. Utwórz podstawowy HPA dla deploymentu o nazwie `web-app`.
2. Skonfiguruj skalowanie na podstawie wykorzystania CPU (target: 80%).
3. Ustaw minimalną liczbę podów na 2 i maksymalną na 5.
4. Zweryfikuj, czy HPA został poprawnie utworzony.

## Zadanie 2: Skalowanie na podstawie metryk niestandardowych
1. Zainstaluj i skonfiguruj Prometheus Adapter.
2. Utwórz HPA, który będzie skalował na podstawie niestandardowej metryki (np. liczba requestów na sekundę).
3. Zweryfikuj, czy HPA reaguje na zmiany metryki niestandardowej.

## Zadanie 3: Skalowanie na podstawie wielu metryk
1. Skonfiguruj HPA do skalowania na podstawie zarówno CPU jak i pamięci.
2. Ustaw różne progi dla każdej metryki.
3. Przetestuj skalowanie przy różnych obciążeniach.

## Zadanie 4: Zaawansowana konfiguracja HPA
1. Skonfiguruj zachowanie HPA podczas skalowania w górę i w dół.
2. Dodaj stabilizację okna skalowania.
3. Przetestuj zachowanie HPA przy gwałtownych zmianach obciążenia.

## Zadanie 5: Monitoring i debugowanie HPA
1. Skonfiguruj monitoring dla HPA używając Prometheus i Grafana.
2. Utwórz dashboard pokazujący historię skalowania.
3. Przeanalizuj zachowanie HPA w różnych scenariuszach obciążenia.

## Wymagania:
- Znajomość podstawowych konceptów Kubernetes
- Dostęp do klastra Kubernetes z zainstalowanym metrics-server
- Narzędzia: kubectl, metrics-server, Prometheus (opcjonalnie)

## Przydatne komendy:
```bash
kubectl get hpa
kubectl describe hpa <nazwa-hpa>
kubectl top pods
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods"
``` 