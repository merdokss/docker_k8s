## Praca z Docker CLI

### Docker HUB
Oficjalne repozytorium obrazów docker-owych - [Docker Hub](https://hub.docker.com/)

### Podstawowe komendy

#### Lista uruchomionych kontenerów
- `docker ps` - wyświetla listę aktualnie uruchomionych kontenerów.

#### Lista dostępnych obrazów
- `docker images` - wyświetla listę dostępnych obrazów w lokalnym repozytorium.

#### Uruchamianie kontenera
- `docker run` - uruchamia kontener na podstawie konkretnego obrazu bazowego.
- `docker run --name nginx -d nginx` - uruchamia kontener z obrazem nginx w trybie odłączonym (detached) i nadaje mu nazwę "nginx".
- `docker run --name ubuntu-dawid --rm -it ubuntu` - uruchamia kontener z obrazem ubuntu w trybie interaktywnym, nadaje mu nazwę "ubuntu-dawid" i usuwa go po zakończeniu.
- `docker run --name nginx -p 8888:80 nginx` - uruchamia kontener z obrazem nginx i mapuje port 8888 na lokalnym hoście na port 80 w kontenerze.
- `docker run -it --entrypoint bash nginx` - uruchamia kontener z obrazem nginx i uruchamia w nim bash zamiast domyślnego entrypoint.
- `docker run --hostname server nginx` - uruchamia kontener z obrazem nginx i ustawia hostname na "server".
- `docker run -v ~/:/usr/share/nginx/html nginx` - uruchamia kontener z obrazem nginx i montuje lokalny katalog domowy do `/usr/share/nginx/html` w kontenerze.

#### Zarządzanie kontenerami
- `docker start [kontener_name]` - uruchamia zatrzymany kontener.
- `docker stop [kontener_name]` - zatrzymuje uruchomiony kontener.
- `docker logs [kontener_name]` - wyświetla logi kontenera.
- `docker logs -f [kontener_name]` - wyświetla logi kontenera w trybie "follow", czyli na bieżąco.
- `docker rm [kontener_name]` - usuwa zatrzymany kontener.
- `docker rmi [image_name]` - usuwa obraz z lokalnego repozytorium.
- `docker container prune` - usuwa wszystkie zatrzymane kontenery.
- `docker exec -it [kontener_name] [proces_name]` - uruchamia dodatkowy proces w działającym kontenerze, np. bash lub ls.
- `docker rename OLD_NAME NEW_NAME` - zmienia nazwę kontenera z OLD_NAME na NEW_NAME.

### Zarządzanie obrazami
- `docker images` - wyświetla listę dostępnych obrazów w lokalnym repozytorium.
- `docker tag [source_image] [target_image]` - tworzy nowy tag dla obrazu.
- `docker commit [kontener_name] [new_image_name]` - tworzy nowy obraz na podstawie stanu kontenera.
- `docker build -t [name-image] -f dockerfile .` - buduje obraz z wykorzystaniem Dockerfile i nadaje mu nazwę `name-image`.
- `docker pull [image_name]` - pobiera obraz z Docker Hub lub innego rejestru.
- `docker push [image_name]` - wysyła obraz do Docker Hub lub innego rejestru.
- `docker save -o [plik.tar] [image_name]` - zapisuje obraz do pliku tar.
- `docker load -i [plik.tar]` - ładuje obraz z pliku tar.
- `docker history [image_name]` - wyświetla historię warstw obrazu.
- `docker inspect [image_name]` - wyświetla szczegółowe informacje o obrazie.

### Zarządanie siecią
- `docker network` - zarządzanie sieciami Docker.
   - `docker network create -d bridge network-1` - tworzy nową sieć typu bridge o nazwie `network-1`.
   - `docker network ls` - wyświetla listę wszystkich sieci.
   - `docker network inspect [network_name]` - wyświetla szczegółowe informacje o sieci.
   - `docker network rm [network_name]` - usuwa sieć o nazwie `network_name`.
   - `docker network prune` - usuwa wszystkie nieużywane sieci.
   - `docker run --network [network_name] [image_name]` - uruchamia kontener z obrazem w określonej sieci.

#### Zarządzanie wolumenami
- `docker volume` - zarządzanie wolumenami (przechowywanie danych).
  - `docker volume create [volume_name]` - tworzy nowy wolumen o nazwie `volume_name`.
  - `docker volume ls` - wyświetla listę wszystkich wolumenów.
  - `docker volume inspect [volume_name]` - wyświetla szczegółowe informacje o wolumenie.
  - `docker volume rm [volume_name]` - usuwa wolumen o nazwie `volume_name`.
  - `docker volume prune` - usuwa wszystkie nieużywane wolumeny.
  - `docker run -v [volume_name]:/path/in/container [image_name]` - uruchamia kontener z zamontowanym wolumenem.






