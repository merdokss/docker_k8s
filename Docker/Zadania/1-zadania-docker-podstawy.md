# Zadania Docker - Podstawy

## Poziom 1: Pierwsze kroki z Docker

### Zadanie 1.1: Uruchamianie pierwszego kontenera
**Cel:** Zapoznanie się z podstawowymi komendami Docker CLI

1. Sprawdź wersję Docker zainstalowaną w systemie
2. Pobierz obraz `hello-world` z Docker Hub
3. Uruchom kontener z obrazem `hello-world`
4. Sprawdź listę wszystkich kontenerów (uruchomionych i zatrzymanych)
5. Usuń kontener `hello-world`

### Zadanie 1.2: Praca z obrazami
**Cel:** Nauka zarządzania obrazami Docker

1. Pobierz obraz `ubuntu:20.04` z Docker Hub
2. Sprawdź listę dostępnych obrazów
3. Uruchom kontener z obrazem Ubuntu w trybie interaktywnym
4. W kontenerze wykonaj polecenie `ls -la` i `whoami`
5. Wyjdź z kontenera i sprawdź jego status
6. Usuń zatrzymany kontener

### Zadanie 1.3: Uruchamianie serwera webowego
**Cel:** Konfiguracja i uruchamianie aplikacji webowej

1. Pobierz obraz `nginx:alpine`
2. Uruchom kontener nginx w trybie odłączonym (detached)
3. Nadaj kontenerowi nazwę `moj-nginx`
4. Mapuj port 8080 hosta na port 80 kontenera
5. Sprawdź czy strona jest dostępna pod adresem `http://localhost:8080`
6. Sprawdź logi kontenera
7. Zatrzymaj i usuń kontener

## Poziom 2: Zarządzanie kontenerami

### Zadanie 2.1: Praca z wolumenami
**Cel:** Zrozumienie koncepcji persystencji danych

1. Utwórz named volume o nazwie `moj-wolumen`
2. Uruchom kontener nginx z zamontowanym wolumenem do `/usr/share/nginx/html`
3. Wejdź do kontenera i utwórz plik `test.txt` w katalogu `/usr/share/nginx/html`
4. Zatrzymaj i usuń kontener
5. Uruchom nowy kontener z tym samym wolumenem
6. Sprawdź czy plik `test.txt` nadal istnieje

### Zadanie 2.2: Zmienne środowiskowe
**Cel:** Konfiguracja aplikacji za pomocą zmiennych środowiskowych

1. Uruchom kontener z obrazem `mysql:8.0` z następującymi zmiennymi:
   - `MYSQL_ROOT_PASSWORD=haslo123`
   - `MYSQL_DATABASE=testdb`
   - `MYSQL_USER=uzytkownik`
   - `MYSQL_PASSWORD=haslo456`
2. Sprawdź logi kontenera aby upewnić się, że MySQL uruchomił się poprawnie
3. Wejdź do kontenera i połącz się z bazą danych
4. Sprawdź czy baza `testdb` została utworzona
5. Zatrzymaj i usuń kontener

### Zadanie 2.3: Zarządzanie siecią
**Cel:** Tworzenie i konfiguracja sieci Docker

1. Utwórz nową sieć typu bridge o nazwie `moja-siec`
2. Sprawdź szczegóły utworzonej sieci
3. Uruchom dwa kontenery Ubuntu w tej sieci:
   - `ubuntu1` - z zainstalowanym `ping`
   - `ubuntu2` - z zainstalowanym `nginx`
4. Z kontenera `ubuntu1` sprawdź połączenie z `ubuntu2` używając `ping`
5. Z kontenera `ubuntu1` sprawdź połączenie z `ubuntu2` używając `curl` na porcie 80
6. Usuń wszystkie kontenery i sieć

## Poziom 3: Debugging i monitorowanie

### Zadanie 3.1: Analiza kontenerów
**Cel:** Nauka debugowania i monitorowania kontenerów

1. Uruchom kontener z obrazem `redis:alpine`
2. Sprawdź szczegółowe informacje o kontenerze używając `docker inspect`
3. Sprawdź wykorzystanie zasobów kontenera używając `docker stats`
4. Wejdź do kontenera i sprawdź procesy używając `ps aux`
5. Sprawdź logi kontenera w trybie follow
6. Zatrzymaj kontener

### Zadanie 3.2: Rozwiązywanie problemów
**Cel:** Diagnozowanie i rozwiązywanie typowych problemów

1. Uruchom kontener z obrazem `nginx` ale z nieprawidłową konfiguracją portu (np. mapowanie na port 80 zamiast 8080)
2. Sprawdź dlaczego kontener się nie uruchamia używając `docker logs`
3. Sprawdź status kontenera używając `docker ps -a`
4. Usuń problematyczny kontener
5. Uruchom kontener z poprawną konfiguracją

## Poziom 4: Optymalizacja i najlepsze praktyki

### Zadanie 4.1: Czyszczenie systemu
**Cel:** Zarządzanie zasobami Docker

1. Sprawdź wykorzystanie miejsca na dysku przez Docker
2. Usuń wszystkie zatrzymane kontenery
3. Usuń wszystkie nieużywane obrazy
4. Usuń wszystkie nieużywane wolumeny
5. Usuń wszystkie nieużywane sieci
6. Sprawdź ponownie wykorzystanie miejsca na dysku

### Zadanie 4.2: Tagowanie obrazów
**Cel:** Organizacja i wersjonowanie obrazów

1. Pobierz obraz `nginx:latest`
2. Utwórz tag `nginx:moja-wersja` dla tego obrazu
3. Utwórz tag `nginx:1.0` dla tego obrazu
4. Sprawdź listę obrazów i ich tagi
5. Usuń obraz `nginx:latest` ale zachowaj pozostałe tagi
6. Sprawdź czy obrazy z tagami nadal działają

## Poziom 5: Zaawansowane scenariusze

### Zadanie 5.1: Multi-container aplikacja
**Cel:** Uruchamianie aplikacji składającej się z wielu kontenerów

1. Utwórz sieć o nazwie `aplikacja-siec`
2. Uruchom kontener z bazą danych PostgreSQL w tej sieci:
   - Nazwa: `postgres-db`
   - Zmienne: `POSTGRES_DB=appdb`, `POSTGRES_USER=appuser`, `POSTGRES_PASSWORD=apppass`
3. Uruchom kontener z aplikacją webową (nginx) w tej samej sieci:
   - Nazwa: `web-app`
   - Port: 8080:80
4. Sprawdź czy oba kontenery działają i są połączone w sieci
5. Sprawdź logi obu kontenerów
6. Zatrzymaj i usuń wszystkie kontenery oraz sieć

### Zadanie 5.2: Backup i restore
**Cel:** Tworzenie kopii zapasowych i przywracanie danych

1. Utwórz wolumen o nazwie `backup-data`
2. Uruchom kontener z obrazem `alpine` z zamontowanym wolumenem
3. W kontenerze utwórz kilka plików testowych
4. Zatrzymaj kontener
5. Utwórz backup wolumenu używając `docker run` z obrazem `alpine` i `tar`
6. Usuń oryginalny wolumen
7. Przywróć dane z backupu do nowego wolumenu
8. Sprawdź czy dane zostały przywrócone poprawnie

## Wskazówki do rozwiązywania problemów

### Typowe problemy i rozwiązania:

1. **Kontener się nie uruchamia:**
   - Sprawdź logi: `docker logs [nazwa-kontenera]`
   - Sprawdź status: `docker ps -a`
   - Sprawdź konfigurację portów i sieci

2. **Brak dostępu do aplikacji:**
   - Sprawdź mapowanie portów: `docker port [nazwa-kontenera]`
   - Sprawdź czy kontener działa: `docker ps`
   - Sprawdź logi aplikacji

3. **Problemy z wolumenami:**
   - Sprawdź uprawnienia do katalogów
   - Sprawdź ścieżki montowania
   - Użyj `docker volume inspect [nazwa-wolumenu]`

4. **Problemy z siecią:**
   - Sprawdź konfigurację sieci: `docker network inspect [nazwa-sieci]`
   - Sprawdź czy kontenery są w tej samej sieci
   - Sprawdź DNS resolution między kontenerami

### Przydatne komendy do debugowania:

```bash
# Sprawdzenie szczegółów kontenera
docker inspect [nazwa-kontenera]

# Sprawdzenie logów w czasie rzeczywistym
docker logs -f [nazwa-kontenera]

# Wejście do działającego kontenera
docker exec -it [nazwa-kontenera] /bin/bash

# Sprawdzenie wykorzystania zasobów
docker stats [nazwa-kontenera]

# Sprawdzenie procesów w kontenerze
docker top [nazwa-kontenera]

# Sprawdzenie zmian w systemie plików
docker diff [nazwa-kontenera]
```

