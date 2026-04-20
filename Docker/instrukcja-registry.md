1. docker login {adres_registry}
2. docker build -t dawidsages.azurecr.io/todos-dama-api:latest Docker-compose/5-ToDos/backend
   docker build -t dawidsages.azurecr.io/todos-dama-web:latest Docker-compose/5-ToDos/frontend

   lub

   docker tag todos-api:latest dawidsages.azurecr.io/todos-dama-api:latest
   docker tag todos-web:latest dawidsages.azurecr.io/todos-dama-web:latest

3.
docker push dawidsages.azurecr.io/todos-dama-api:latest
docker push dawidsages.azurecr.io/todos-dama-web:latest