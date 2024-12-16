# Docker Compose

Docker Compose to narzędzie do definiowania i uruchamiania wielokontenerowych aplikacji Docker. Pozwala na konfigurację usług, sieci i wolumenów w jednym pliku YAML, co znacznie upraszcza proces zarządzania złożonymi aplikacjami.

## Do czego służy Docker Compose?

- Definiowanie środowiska aplikacji w jednym pliku
- Uruchamianie wielu kontenerów jednocześnie
- Zarządzanie zależnościami między usługami
- Łatwe skalowanie i aktualizacja usług
- Uproszczenie procesu testowania i wdrażania aplikacji

## Podstawowe komendy Docker Compose

1. Uruchamianie usług:
   ```
   docker-compose up
   ```
   Uruchamia wszystkie usługi zdefiniowane w pliku docker-compose.yml.

   Informacyjnie: Aby uruchomić usługi dla konkretnego projektu i z określoną definicją docker-compose, można użyć:
   ```
   docker-compose -f [definicja-dockercompose.yaml] -p [project_name] up
   ```

2. Uruchamianie usług w tle:
   ```
   docker-compose up -d
   ```
   Uruchamia usługi w trybie odłączonym (detached).

3. Zatrzymywanie usług:
   ```
   docker-compose down
   ```
   Zatrzymuje i usuwa wszystkie kontenery, sieci i wolumeny utworzone przez `up`.

4. Wyświetlanie statusu usług:
   ```
   docker-compose ps
   ```
   Pokazuje stan wszystkich usług zdefiniowanych w docker-compose.yml.

5. Wyświetlanie logów:
   ```
   docker-compose logs
   ```
   Wyświetla logi ze wszystkich usług.

6. Budowanie lub przebudowywanie usług:
   ```
   docker-compose build
   ```
   Buduje lub przebudowuje usługi zdefiniowane w docker-compose.yml.

7. Skalowanie usługi:
   ```
   docker-compose up -d --scale nazwa_uslugi=3
   ```
   Uruchamia 3 instancje określonej usługi.

8. Wykonywanie polecenia w działającym kontenerze:
   ```
   docker-compose exec nazwa_uslugi polecenie
   ```
   Uruchamia polecenie w określonym kontenerze.


## Restart 

Pole `restart` w pliku `docker-compose` określa, kiedy Docker powinien automatycznie restartować kontener. Oto szczegółowy opis każdej opcji wraz z przykładami:

- `no`: Kontener nie będzie restartowany automatycznie.
  Przykład: Kontener zakończy się z kodem wyjścia 0 lub innym, nie zostanie ponownie uruchomiony.
- `always`: Kontener będzie zawsze restartowany, niezależnie od kodu wyjścia.
  Przykład: Kontener zakończy się z kodem wyjścia 0 lub innym, Docker natychmiast go uruchomi ponownie.
- `on-failure`: Kontener będzie restartowany tylko wtedy, gdy zakończy się niepowodzeniem (z kodem wyjścia innym niż zero).
  Przykład: Kontener zakończy się z kodem wyjścia 1, Docker uruchomi go ponownie. Jeśli zakończy się z kodem 0, nie zostanie ponownie uruchomiony.
- `unless-stopped`: Kontener będzie restartowany zawsze, chyba że zostanie ręcznie zatrzymany.
  Przykład: Kontener zakończy się z kodem wyjścia 0 lub innym, Docker uruchomi go ponownie, chyba że został zatrzymany za pomocą docker stop.
