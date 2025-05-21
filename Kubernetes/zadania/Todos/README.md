## Tworzenie secret dla MongoDB Connections string

`kubectl create secret generic mongodb-secret \
  --from-literal=mongodb-uri='mongodb://root:password@mongo-service:27017/todos?authSource=admin'`

## Tworzenie secret dla docker-registry prywatnego

`kubectl create secret docker-registry external-registry --docker-server=.... --docker-username=... --docker-password=....`

kubectl create secret docker-registry external-registry --docker-server=dawid.azurecr.io --docker-username=dawid --docker-password=04c21MzpgJAHVHbstJw5R2n2YlmgdHYqZCFmROFfqD+ACRC4/ny4