### Ćwiczenie 1: Uruchomienie WordPress z bazą danych MySQL

1. Utwórz nowy katalog o nazwie `wordpress-db` i przejdź do niego.

2. W katalogu `wordpress-db` utwórz plik `docker-compose.yml` z następującą zawartością:

   ```yaml
   version: '3'

   services:
     wordpress:
       image: wordpress:latest
       ports:
         - "8080:80"
       environment:
         WORDPRESS_DB_HOST: db
         WORDPRESS_DB_USER: wordpressuser
         WORDPRESS_DB_PASSWORD: wordpassword
         WORDPRESS_DB_NAME: wordpress
       volumes:
         - wordpress_data:/var/www/html
       depends_on:
         - db

     db:
       image: mysql:5.7
       environment:
         MYSQL_DATABASE: wordpress
         MYSQL_USER: wordpressuser
         MYSQL_PASSWORD: wordpassword
         MYSQL_RANDOM_ROOT_PASSWORD: '1'
       volumes:
         - db_data:/var/lib/mysql

   volumes:
     wordpress_data:
     db_data:
   ```

3. Uruchom kontenery za pomocą polecenia:
   ```
   docker-compose up -d
   ```

4. Otwórz przeglądarkę i przejdź pod adres `http://localhost:8080`, aby skonfigurować WordPress.

5. Po zakończeniu pracy, zatrzymaj i usuń kontenery poleceniem:
   ```
   docker-compose down
   ```

### Ćwiczenie 2: Uruchomienie aplikacji eShopOnWeb

1. Przejdź do katalogu `3-eshopweb`.

2. Upewnij się, że w katalogu znajduje się plik `docker-compose.yml`. Jeśli go nie ma, utwórz go z następującą zawartością:

   ```yaml
   version: '3.4'

   services:
     eshopwebmvc:
       image: ${DOCKER_REGISTRY-}eshopwebmvc
       build:
         context: .
         dockerfile: src/Web/Dockerfile
       environment:
         - ASPNETCORE_ENVIRONMENT=Development
         - ASPNETCORE_URLS=http://+:80
       ports:
         - "5106:80"
       depends_on:
         - sqldata

     sqldata:
       image: mcr.microsoft.com/mssql/server:2019-latest
       environment:
         - SA_PASSWORD=Pass@word
         - ACCEPT_EULA=Y
       ports:
         - "5433:1433"

   volumes:
     eshopwebmvc_data:
   ```

3. Uruchom aplikację za pomocą polecenia:
   ```
   docker-compose up -d
   ```

4. Otwórz przeglądarkę i przejdź pod adres `http://localhost:5106`, aby zobaczyć działającą aplikację eShopOnWeb.

5. Po zakończeniu pracy, zatrzymaj i usuń kontenery poleceniem:
   ```
   docker-compose down
   ```


