## Tworzenie secret dla MongoDB Connections string

`kubectl create secret generic mongodb-secret \
  --from-literal=mongodb-uri='mongodb://root:password@mongo-service:27017/todos?authSource=admin'`

## Tworzenie secret dla docker-registry prywatnego

`kubectl create secret docker-registry external-registry --docker-server=.... --docker-username=... --docker-password=....`

## Wazne!!!

Do przeprowadzenie cwiczenie i deployu przykładu konieczne będzie zbudowanie obrazów z aplikacji - Docker-compose/5-ToDos. Oraz wypchanie ich za zewnętrzne Registry Docker