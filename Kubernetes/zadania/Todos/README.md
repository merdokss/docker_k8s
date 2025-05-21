### Tworzenie secret dla MongoDB Connections string

`kubectl create secret generic mongo-uri-secret \
  --from-literal=mongo-uri='mongodb://root:password@mongo-service:27017/todos?authSource=admin'
`