# Load Test App

Generator obciążenia HTTP przeznaczony do testowania wydajności aplikacji i testowania autoskalowania (HPA) w Kubernetes.

## Opis

Aplikacja `load_test.py` to zaawansowane narzędzie do generowania obciążenia HTTP, które:
- Wysyła losowe zapytania GET i POST do wskazanego URL
- Obsługuje wiele równoległych wątków (symulacja wielu użytkowników)
- Automatycznie retry'uje nieudane zapytania
- Generuje losowe dane o różnych rozmiarach (1-10KB) w zapytaniach POST
- Wyświetla statystyki w czasie rzeczywistym
- Może być bezpiecznie przerywane (Ctrl+C)

## Wymagania

- Python 3.x
- Biblioteki Python:
  - `requests`
  - `urllib3`

## Instalacja

```bash
# Zainstaluj wymagane biblioteki
pip3 install requests urllib3

# Lub użyj requirements.txt (jeśli istnieje)
pip3 install -r requirements.txt
```

## Użycie

### Podstawowa składnia

```bash
python3 load_test.py --url <URL> [--concurrency <liczba>] [--duration <sekundy>]
```

### Parametry

| Parametr | Wymagany | Domyślna wartość | Opis |
|----------|----------|------------------|------|
| `--url` | ✅ Tak | - | URL aplikacji do testowania |
| `--concurrency` | ❌ Nie | 100 | Liczba równoległych wątków/połączeń |
| `--duration` | ❌ Nie | 300 | Czas trwania testu w sekundach |

## Przykłady użycia

### 1. Test z domyślnymi parametrami
```bash
python3 load_test.py --url http://localhost:8080
```
Uruchamia test z 100 wątkami przez 300 sekund (5 minut)

### 2. Test z niższą współbieżnością
```bash
python3 load_test.py --url http://localhost:8080 --concurrency 50
```
Uruchamia test z 50 wątkami przez 300 sekund

### 3. Krótki test
```bash
python3 load_test.py --url http://localhost:8080 --duration 60
```
Uruchamia test z 100 wątkami przez 60 sekund (1 minuta)

### 4. Intensywny test
```bash
python3 load_test.py --url http://10.96.0.100:8080 --concurrency 200 --duration 120
```
Uruchamia test z 200 wątkami przez 120 sekund (2 minuty)

### 5. Test dla Kubernetes Ingress
```bash
python3 load_test.py --url http://my-app.example.com --concurrency 150 --duration 180
```
Testuje aplikację dostępną przez Ingress

## Jak działa aplikacja

### Mechanizm działania

1. **Sesje HTTP z retry**
   - Automatyczne ponowienie nieudanych zapytań (3 próby)
   - Pool połączeń (100 połączeń)
   - Obsługa błędów 500, 502, 503, 504

2. **Typy zapytań**
   - **GET**: Losowe parametry URL (cache, timestamp)
   - **POST**: Losowe dane o rozmiarze 1-10KB

3. **Statystyki w czasie rzeczywistym**
   - Aktualizacja co 5 sekund
   - Liczba wykonanych zapytań
   - Udane/nieudane zapytania
   - RPS (Requests Per Second)

4. **Bezpieczne zakończenie**
   - Ctrl+C bezpiecznie przerywa test
   - Wyświetla podsumowanie po zakończeniu

### Przykładowy output

```
Rozpoczynam test obciążeniowy:
- URL: http://localhost:8080
- Liczba równoległych wątków: 100
- Czas trwania testu: 300 sekund

Postęp testu (5s):
- Wykonano zapytań: 523
- Udanych zapytań: 520
- Nieudanych zapytań: 3
- RPS: 104.60

Postęp testu (10s):
- Wykonano zapytań: 1048
- Udanych zapytań: 1045
- Nieudanych zapytań: 3
- RPS: 104.80

...

Podsumowanie testu:
- Całkowity czas: 300.45 sekund
- Całkowita liczba zapytań: 31450
- Udane zapytania: 31420
- Nieudane zapytania: 30
- Średni RPS: 104.67
```

## Zastosowania

### 1. Testowanie HPA (Horizontal Pod Autoscaler) w Kubernetes

Aplikacja idealnie nadaje się do testowania autoskalowania w Kubernetes:

```bash
# Utwórz HPA
kubectl autoscale deployment my-app --cpu-percent=50 --min=1 --max=10

# Uruchom test obciążenia
python3 load_test.py --url http://my-app-service:8080 --concurrency 150 --duration 600

# Obserwuj skalowanie
kubectl get hpa -w
```

### 2. Testowanie wydajności

Sprawdź, jak aplikacja radzi sobie pod obciążeniem:
- Znajdź maksymalny RPS
- Zidentyfikuj bottlenecki
- Przetestuj różne konfiguracje

### 3. Stress testing

Przetestuj stabilność aplikacji pod wysokim obciążeniem:
```bash
python3 load_test.py --url http://localhost:8080 --concurrency 500 --duration 3600
```

### 4. Testowanie load balancera

Sprawdź dystrybucję ruchu między podami:
```bash
# Skaluj aplikację
kubectl scale deployment my-app --replicas=5

# Uruchom test
python3 load_test.py --url http://my-app-service:8080 --concurrency 100 --duration 300
```

## Przerwanie testu

Test można przerwać w dowolnym momencie:
- Naciśnij `Ctrl+C`
- Aplikacja bezpiecznie zakończy wszystkie wątki
- Wyświetli podsumowanie wykonanych testów

## Wskazówki

1. **Rozpocznij od małych wartości**: Zacznij od niskiej współbieżności (np. 10-50) i stopniowo ją zwiększaj
2. **Monitoruj zasoby**: Sprawdzaj zużycie CPU/RAM zarówno aplikacji testowej, jak i testowanej
3. **Używaj w izolowanym środowisku**: Nie testuj aplikacji produkcyjnych bez zgody
4. **Dla testów HPA**: Zalecany czas testu to min. 5 minut (300s), aby HPA miał czas na reakcję
5. **Sieć**: Upewnij się, że jesteś w tej samej sieci co testowana aplikacja (szczególnie w Kubernetes)

## Rozwiązywanie problemów

### Błąd: "Connection refused"
```
✅ Sprawdź, czy aplikacja działa
✅ Sprawdź URL i port
✅ W Kubernetes: sprawdź, czy Service jest poprawnie skonfigurowany
```

### Wysoki odsetek błędów
```
✅ Zmniejsz współbieżność (--concurrency)
✅ Sprawdź limity zasobów aplikacji
✅ Sprawdź logi aplikacji: kubectl logs <pod-name>
```

### Niska wartość RPS
```
✅ Zwiększ współbieżność
✅ Sprawdź opóźnienia sieciowe
✅ Sprawdź, czy aplikacja nie jest bottleneckiem
```

## Licencja

Narzędzie szkoleniowe do nauki Docker i Kubernetes.

## Autor

Materiały szkoleniowe Altkom - Docker & Kubernetes

