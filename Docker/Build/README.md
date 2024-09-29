# Pola używane w Dockerfile

Poniżej znajduje się lista najważniejszych pól używanych w pliku Dockerfile wraz z ich opisem:

1. FROM: Określa obraz bazowy, na którym będzie budowany nowy obraz.
   Przykład: `FROM ubuntu:20.04`

2. RUN: Wykonuje polecenia w nowej warstwie obrazu i zatwierdza zmiany.
   Przykład: `RUN apt-get update && apt-get install -y nginx`

3. CMD: Dostarcza domyślne polecenie i/lub parametry dla kontenera.
   Przykład: `CMD ["nginx", "-g", "daemon off;"]`

4. ENTRYPOINT: Konfiguruje kontener, który będzie działać jako wykonywalny.
   Przykład: `ENTRYPOINT ["nginx", "-g", "daemon off;"]`

5. WORKDIR: Ustawia katalog roboczy dla instrukcji RUN, CMD, ENTRYPOINT, COPY i ADD.
   Przykład: `WORKDIR /app`

6. COPY: Kopiuje nowe pliki lub katalogi z hosta do systemu plików kontenera.
   Przykład: `COPY . /app`

7. ADD: Podobne do COPY, ale może również pobierać pliki z URL i rozpakowywać archiwa.
   Przykład: `ADD https://example.com/big.tar.xz /usr/src/things/`

8. ENV: Ustawia zmienne środowiskowe.
   Przykład: `ENV NODE_ENV production`

9. EXPOSE: Informuje Docker, że kontener nasłuchuje na określonych portach w czasie wykonywania.
   Przykład: `EXPOSE 80`

10. VOLUME: Tworzy punkt montowania dla woluminów.
    Przykład: `VOLUME /data`

11. USER: Ustawia użytkownika (lub UID), którego należy użyć przy uruchamianiu obrazu.
    Przykład: `USER nginx`

12. ARG: Definiuje zmienną, którą użytkownicy mogą przekazać w czasie budowania.
    Przykład: `ARG VERSION=latest`

13. LABEL: Dodaje metadane do obrazu.
    Przykład: `LABEL version="1.0" description="To jest mój obraz"`

14. HEALTHCHECK: Informuje Docker, jak sprawdzić, czy kontener nadal działa.
    Przykład: `HEALTHCHECK CMD curl -f http://localhost/ || exit 1`

15. SHELL: Zmienia domyślną powłokę używaną do wykonywania poleceń.
    Przykład: `SHELL ["/bin/bash", "-c"]`

</br>

# Różnica między CMD a ENTRYPOINT

CMD i ENTRYPOINT to dwie instrukcje w Dockerfile, które służą do definiowania, co kontener ma wykonać po uruchomieniu. Oto ich główne zastosowania i różnice:

1. CMD:
   - Zastosowania:
     * Definiowanie domyślnego polecenia, które ma być wykonane przy uruchomieniu kontenera.
     * Dostarczanie domyślnych argumentów dla ENTRYPOINT.
     * Uruchamianie konkretnej aplikacji lub skryptu w kontenerze.
   - Cechy:
     * Łatwe do nadpisania przy uruchamianiu kontenera.
     * Dobre dla kontenerów, które mają być elastyczne w użyciu.
     * Może być używane jako parametry dla ENTRYPOINT.

2. ENTRYPOINT:
   - Zastosowania:
     * Konfigurowanie kontenera jako wykonywalnej aplikacji.
     * Definiowanie głównego procesu kontenera, który zawsze powinien być uruchomiony.
     * Tworzenie kontenerów, które działają jak pojedyncze polecenia lub narzędzia.
   - Cechy:
     * Trudniejsze do nadpisania (wymaga użycia flagi --entrypoint).
     * Dobre dla kontenerów, które mają zawsze uruchamiać tę samą aplikację.
     * Może przyjmować argumenty z CMD lub z linii poleceń.

Główne różnice:
1. Elastyczność: CMD jest bardziej elastyczne i łatwiejsze do nadpisania niż ENTRYPOINT.
2. Przeznaczenie: ENTRYPOINT jest lepsze do definiowania głównego procesu kontenera, podczas gdy CMD jest lepsze do dostarczania domyślnych argumentów.
3. Interakcja: ENTRYPOINT może współpracować z CMD, używając CMD jako źródła domyślnych argumentów.
4. Zachowanie przy nadpisywaniu: Argumenty podane przy uruchamianiu kontenera zastępują całe CMD, ale są dodawane do ENTRYPOINT.

Przykłady zastosowań:

1. Kontener jako narzędzie:
   ```
   FROM ubuntu
   ENTRYPOINT ["ping"]
   CMD ["localhost"]
   ```
   Ten kontener działa jak polecenie ping. Domyślnie pinguje localhost, ale można łatwo zmienić cel:
   `docker run image_name google.com`

2. Aplikacja z konfigurowalnymi argumentami:
   ```
   FROM python:3.8
   COPY app.py /
   ENTRYPOINT ["python", "app.py"]
   CMD ["--default-config"]
   ```
   Aplikacja zawsze uruchamia się z Python, ale można łatwo zmienić argumenty:
   `docker run image_name --custom-config`

Wybór między CMD a ENTRYPOINT zależy od konkretnego przypadku użycia i tego, jak elastyczny lub ściśle zdefiniowany ma być kontener.