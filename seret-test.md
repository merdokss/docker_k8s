apiVersion: v1
kind: Secret
metadata:
  name: prometheus-auth
type: Opaque
stringData:
  username: admin
  password: secret