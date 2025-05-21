## Ingress

Ingress w Kubernetes to obiekt, który zarządza dostępem zewnętrznym do usług w klastrze. Umożliwia on definiowanie reguł routingu ruchu HTTP i HTTPS do usług na podstawie adresów URL i hostów.

### Instalacja Ingress Controller

Aby korzystać z Ingress, musisz zainstalować Ingress Controller. Przykładem popularnego Ingress Controller jest NGINX Ingress Controller. Poniżej znajdują się kroki instalacji:

1. Dodaj repozytorium Helm dla NGINX Ingress Controller:
   ```sh
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
   ```

2. Zainstaluj NGINX Ingress Controller:
   ```sh
   helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
   ```

### Konfiguracja Ingress

Przykład definicji Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
                service:
                    name: example-service
                    port:
                        number: 80
```

### Użycie Ingress

Po zainstalowaniu Ingress Controller i utworzeniu odpowiedniego Ingress, możesz przetestować dostęp do usługi za pomocą adresu IP lub nazwy hosta, które zostały przypisane do Ingress.

### Przydatne linki

- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

### Instalacja cert-manager

Aby zainstalować cert-manager, wykonaj poniższe kroki:

1. Dodaj repozytorium Helm dla cert-manager:
   ```sh
   helm repo add jetstack https://charts.jetstack.io
   helm repo update
   ```

2. Zainstaluj cert-manager:
   ```sh
   kubectl create namespace cert-manager
   helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.5.3 --set installCRDs=true
   ```

### Konfiguracja cert-manager

Po zainstalowaniu cert-manager, musisz skonfigurować ClusterIssuer, aby uzyskać certyfikaty od Let's Encrypt. Przykład definicji ClusterIssuer:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

### Użycie cert-manager

Po skonfigurowaniu cert-manager i ClusterIssuer, możesz utworzyć Ingress z certyfikatem:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: example-ingress
    annotations:
        cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
    tls:
        - hosts:
            - example.com
          secretName: example-tls
    rules:
        - host: example.com
          http:
            paths:
                - path: /
                    pathType: Prefix
                    backend:
                        service:
                            name: example-service
                            port:
                                number:
```