# Zadania - Horizontal Pod Autoscaler w Kubernetes

## Zadanie 1: Podstawowa konfiguracja HPA
1. Utwórz podstawowy HPA dla deploymentu o nazwie `web-app`.
2. Skonfiguruj skalowanie na podstawie wykorzystania CPU (target: 80%).
3. Ustaw minimalną liczbę podów na 2 i maksymalną na 5.
4. Zweryfikuj, czy HPA został poprawnie utworzony.

## Zadanie 2: Skalowanie na podstawie wielu metryk
1. Skonfiguruj HPA do skalowania na podstawie zarówno CPU jak i pamięci.
2. Ustaw różne progi dla każdej metryki.
3. Przetestuj skalowanie przy różnych obciążeniach.

## Zadanie 3: Zaawansowana konfiguracja HPA
1. Skonfiguruj zachowanie HPA podczas skalowania w górę i w dół.
2. Dodaj stabilizację okna skalowania.
3. Przetestuj zachowanie HPA przy gwałtownych zmianach obciążenia.
