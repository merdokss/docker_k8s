### Ćwiczenie 1: Uruchamianie kontenera
1. docker run --name my_nginx -d nginx
2. docker ps
3. docker stop my_nginx

### Ćwiczenie 2: Praca z wolumenami
1. docker volume create my_volume
2. docker run -d --name my_nginx_volume -v my_volume:/usr/share/nginx/html nginx
3. docker volume ls
   docker volume inspect my_volume

### Ćwiczenie 3: Zarządzanie obrazami
1. docker pull alpine
2. docker run -it --name my_alpine alpine
   echo "Hello, Docker!" > /hello.txt
   exit
   docker commit my_alpine my_alpine_image
3. docker images

### Ćwiczenie 4: Zarządzanie siecią
1. docker network create -d bridge my_bridge_network
2. docker run -d --name my_nginx_network --network my_bridge_network nginx
3. docker network inspect my_bridge_network
