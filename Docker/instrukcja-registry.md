docker login {adres_registry}
docker build -t dawidsages.azurecr.io/test-api:latest Docker-compose/5-ToDos/backend
docker build -t dawidsages.azurecr.io/test-web:latest Docker-compose/5-ToDos/frontend
docker push dawidsages.azurecr.io/test-api:latest
docker push dawidsages.azurecr.io/test-web:latest