### Ćwiczenie 1: Budowanie prostego obrazu Docker

1. Utwórz plik o nazwie `Dockerfile` z następującą zawartością:
   ```
   FROM alpine:latest
   RUN echo "Witaj w moim kontenerze!" > /powitanie.txt
   CMD cat /powitanie.txt
   ```

2. Zbuduj obraz Docker używając polecenia:
   ```
   docker build -t moj-pierwszy-obraz .
   ```

3. Uruchom kontener z nowo utworzonego obrazu:
   ```
   docker run moj-pierwszy-obraz
   ```

4. Sprawdź, czy zobaczysz wiadomość "Witaj w moim kontenerze!".

### Ćwiczenie 2: Budowanie i uruchamianie aplikacji webowej

1. Utwórz plik `index.html` z prostą stroną internetową:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Moja strona Docker</title>
   </head>
   <body>
       <h1>Witaj w świecie Docker!</h1>
       <p>To jest prosta strona hostowana w kontenerze.</p>
   </body>
   </html>
   ```

2. Utwórz `Dockerfile` z następującą zawartością:
   ```
   FROM nginx:alpine
   COPY index.html /usr/share/nginx/html/index.html
   EXPOSE 80
   ```

3. Zbuduj obraz Docker:
   ```
   docker build -t moja-strona-web .
   ```

4. Uruchom kontener, mapując port 8080 hosta na port 80 kontenera:
   ```
   docker run -d -p 8080:80 moja-strona-web
   ```

5. Otwórz przeglądarkę i wejdź na adres `http://localhost:8080`, aby zobaczyć swoją stronę.


### Ćwiczenie 3: Uruchamianie kontenerów Ubuntu w sieci

1. Utwórz nową sieć Docker o nazwie `moja-siec`:
   ```
   docker network create moja-siec
   ```

2. Uruchom pierwszy kontener Ubuntu o nazwie `ubuntu1`:
   ```
   docker run -d --name ubuntu1 --network moja-siec ubuntu:latest sleep infinity
   ```

3. Uruchom drugi kontener Ubuntu o nazwie `ubuntu2`:
   ```
   docker run -d --name ubuntu2 --network moja-siec ubuntu:latest sleep infinity
   ```

4. Zainstaluj `curl` w obu kontenerach:
   ```
   docker exec ubuntu1 apt-get update && docker exec ubuntu1 apt-get install -y curl
   docker exec ubuntu2 apt-get update && docker exec ubuntu2 apt-get install -y curl
   ```

5. Sprawdź połączenie między kontenerami używając `curl`:
   ```
   docker exec ubuntu1 curl ubuntu2
   docker exec ubuntu2 curl ubuntu1
   ```

Wskazówki:
- Użyliśmy komendy `sleep infinity`, aby kontenery działały w tle.
- Pamiętaj, że kontenery w tej samej sieci Docker mogą komunikować się ze sobą używając nazw kontenerów jako hostów.
- Jeśli `curl` zwróci błąd, upewnij się, że w kontenerach działa jakiś serwer HTTP lub użyj polecenia `ping` zamiast `curl`.

