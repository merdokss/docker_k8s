# Kompletny Zestaw Zadań i Rozwiązań Docker

## Przegląd

Ten katalog zawiera kompleksowy zestaw zadań i rozwiązań dla nauki Docker, podzielony na różne poziomy trudności i tematy. Każdy plik zawiera szczegółowe instrukcje, przykłady kodu i wyjaśnienia.

## Struktura Zadań

### 1. Podstawy Docker
**Plik:** `zadania-docker-podstawy.md`  
**Rozwiązania:** `rozwiazania-docker-podstawy.md`

**Zawartość:**
- Pierwsze kroki z Docker CLI
- Zarządzanie kontenerami i obrazami
- Praca z wolumenami i zmiennymi środowiskowymi
- Zarządzanie siecią Docker
- Debugging i monitorowanie kontenerów
- Optymalizacja i najlepsze praktyki
- Zaawansowane scenariusze (multi-container aplikacje, backup/restore)

**Poziomy trudności:** 5 poziomów (od podstaw do zaawansowanych)

### 2. Dockerfile i Budowanie Obrazów
**Plik:** `zadania-dockerfile.md`  
**Rozwiązania:** `rozwiazania-dockerfile.md`

**Zawartość:**
- Podstawy tworzenia Dockerfile
- Aplikacje webowe (nginx, Node.js)
- Optymalizacja warstw i rozmiaru obrazu
- Multi-stage builds
- Zmienne środowiskowe i ARG
- Healthcheck i monitoring
- Użytkownicy nieprivilegowani
- Praktyczne scenariusze (baza danych, reverse proxy)
- Debugging i optymalizacja

**Poziomy trudności:** 5 poziomów (od prostych Dockerfile do zaawansowanych technik)

### 3. Sieci i Wolumeny
**Plik:** `zadania-sieci-wolumeny.md`  
**Rozwiązania:** `rozwiazania-sieci-wolumeny.md`

**Zawartość:**
- Podstawy sieci Docker (bridge, host, custom)
- Komunikacja między kontenerami
- Izolacja sieci
- Zaawansowane sieci (load balancing, port forwarding)
- Named volumes i bind mounts
- Tmpfs mounts
- Volume drivers
- Backup i restore wolumenów
- Praktyczne scenariusze (aplikacje z bazą danych, mikroserwisy, monitoring)

**Poziomy trudności:** 5 poziomów (od podstaw do zaawansowanych)

### 4. Zaawansowane Tematy
**Plik:** `zadania-zaawansowane.md`  
**Rozwiązania:** `rozwiazania-zaawansowane.md`

**Zawartość:**
- Docker Compose (podstawy, aplikacje z bazą danych, reverse proxy)
- Docker Swarm (inicjalizacja, deployowanie, skalowanie)
- Bezpieczeństwo (nieprivilegowani użytkownicy, secrets, skanowanie luk)
- Monitoring i logowanie (ELK Stack, aplikacje z logowaniem)
- Optymalizacja i wydajność (rozmiar obrazu, load testing, monitoring zasobów)

**Poziomy trudności:** 5 poziomów (od Docker Compose do zaawansowanej optymalizacji)

## Jak korzystać z zadań

### 1. Wybierz poziom trudności
Zacznij od podstaw i stopniowo przechodź do bardziej zaawansowanych tematów.

### 2. Przeczytaj zadanie
Każde zadanie zawiera:
- Cel zadania
- Szczegółowe instrukcje krok po kroku
- Wskazówki i wyjaśnienia

### 3. Wykonaj zadanie
Postępuj zgodnie z instrukcjami i sprawdź czy wszystko działa poprawnie.

### 4. Sprawdź rozwiązanie
Jeśli masz problemy, sprawdź plik z rozwiązaniami, który zawiera:
- Kompletne rozwiązanie krok po kroku
- Wyjaśnienia każdego kroku
- Wskazówki do rozwiązywania problemów

## Wymagania

### Podstawowe
- Docker zainstalowany w systemie
- Podstawowa znajomość linii poleceń
- Podstawowa znajomość systemów Linux/Unix

### Zaawansowane
- Znajomość programowania (Python, Node.js, Go)
- Znajomość sieci komputerowych
- Znajomość baz danych
- Znajomość narzędzi monitorujących

## Struktura każdego zadania

### Zadania zawierają:
1. **Cel zadania** - co ma być osiągnięte
2. **Instrukcje krok po kroku** - szczegółowe polecenia
3. **Wskazówki** - dodatkowe informacje pomocne w wykonaniu
4. **Wymagania** - co jest potrzebne do wykonania zadania

### Rozwiązania zawierają:
1. **Kompletne rozwiązanie** - wszystkie polecenia i pliki
2. **Wyjaśnienia** - dlaczego każdy krok jest potrzebny
3. **Wskazówki do debugowania** - jak rozwiązać typowe problemy
4. **Najlepsze praktyki** - jak robić to lepiej

## Przykłady użycia

### Przykład 1: Pierwsze kroki
```bash
# Przejdź do katalogu z zadaniami
cd Docker

# Przeczytaj zadanie
cat zadania-docker-podstawy.md

# Wykonaj zadanie 1.1
docker --version
docker pull hello-world
docker run hello-world

# Sprawdź rozwiązanie jeśli masz problemy
cat rozwiazania-docker-podstawy.md
```

### Przykład 2: Dockerfile
```bash
# Utwórz katalog dla zadania
mkdir moja-aplikacja
cd moja-aplikacja

# Utwórz Dockerfile zgodnie z instrukcjami
cat > Dockerfile << 'EOF'
FROM alpine:latest
RUN echo "Witaj w moim kontenerze!" > /powitanie.txt
CMD cat /powitanie.txt
EOF

# Zbuduj obraz
docker build -t moja-aplikacja:v1.0 .

# Uruchom kontener
docker run moja-aplikacja:v1.0
```

## Wskazówki do nauki

### 1. Nie spiesz się
Każde zadanie ma na celu nauczenie konkretnej umiejętności. Przeanalizuj każdy krok.

### 2. Eksperymentuj
Po wykonaniu zadania, spróbuj zmodyfikować rozwiązanie i zobacz co się stanie.

### 3. Czytaj dokumentację
Docker ma doskonałą dokumentację. Używaj `docker --help` i `docker command --help`.

### 4. Używaj rozwiązań jako referencji
Rozwiązania nie są tylko do kopiowania - używaj ich do zrozumienia koncepcji.

### 5. Praktykuj regularnie
Docker to narzędzie praktyczne - im więcej ćwiczysz, tym lepiej rozumiesz.

## Rozwiązywanie problemów

### Typowe problemy:
1. **Kontener się nie uruchamia** - sprawdź logi: `docker logs [nazwa-kontenera]`
2. **Brak dostępu do aplikacji** - sprawdź mapowanie portów: `docker port [nazwa-kontenera]`
3. **Problemy z wolumenami** - sprawdź uprawnienia i ścieżki
4. **Problemy z siecią** - sprawdź konfigurację sieci: `docker network inspect [nazwa-sieci]`

### Przydatne komendy do debugowania:
```bash
# Sprawdzenie statusu kontenerów
docker ps -a

# Sprawdzenie logów
docker logs [nazwa-kontenera]

# Wejście do kontenera
docker exec -it [nazwa-kontenera] /bin/bash

# Sprawdzenie szczegółów
docker inspect [nazwa-kontenera]

# Sprawdzenie wykorzystania zasobów
docker stats [nazwa-kontenera]
```

## Dalsze kroki

Po ukończeniu wszystkich zadań, rozważ:

1. **Docker Compose** - do zarządzania wieloma kontenerami
2. **Docker Swarm** - do orkiestracji kontenerów
3. **Kubernetes** - do zaawansowanej orkiestracji
4. **CI/CD** - integracja Docker z procesami ciągłej integracji
5. **Monitoring** - zaawansowane monitorowanie kontenerów
6. **Bezpieczeństwo** - zaawansowane aspekty bezpieczeństwa

## Kontakt i wsparcie

Jeśli masz pytania lub problemy z zadaniami:

1. Sprawdź plik z rozwiązaniami
2. Przeczytaj dokumentację Docker
3. Sprawdź logi kontenerów
4. Użyj komend debugowania

## Licencja

Te zadania i rozwiązania są przeznaczone do celów edukacyjnych. Możesz je swobodnie używać, modyfikować i rozpowszechniać.

---

**Powodzenia w nauce Docker! 🐳**

