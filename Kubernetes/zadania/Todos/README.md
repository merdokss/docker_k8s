### Tworzenie secret dla MongoDB Connections string

`kubectl create secret generic mongodb-secret \
  --from-literal=mongodb-uri='mongodb://root:password@mongo-service:27017/todos?authSource=admin'
`