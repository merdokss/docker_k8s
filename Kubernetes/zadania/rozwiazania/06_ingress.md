# Rozwiązania - Ingress w Kubernetes

## Zadanie 1: Podstawowa konfiguracja Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-ingress
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

Weryfikacja:
```bash
kubectl get ingress
kubectl describe ingress basic-ingress
```

## Zadanie 2: Routing oparty na hostach

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

Testowanie:
```bash
# Dodaj wpisy do /etc/hosts
echo "127.0.0.1 app1.example.com app2.example.com" | sudo tee -a /etc/hosts

# Test połączenia
curl -H "Host: app1.example.com" http://localhost
curl -H "Host: app2.example.com" http://localhost
```

## Zadanie 3: TLS/SSL

1. Utworzenie certyfikatu:
```bash
# Generowanie klucza prywatnego i certyfikatu
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=example.com"
```

2. Utworzenie sekretu:
```bash
kubectl create secret tls tls-secret \
  --key tls.key \
  --cert tls.crt
```

3. Konfiguracja Ingress z TLS:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  tls:
  - hosts:
    - example.com
    secretName: tls-secret
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

Weryfikacja:
```bash
curl -k https://example.com
```

## Zadanie 4: Annotacje i konfiguracja zaawansowana

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: advanced-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/limit-rps: "100"
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /web(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

## Zadanie 5: Ingress z wieloma backendami

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-backend-ingress
  annotations:
    nginx.ingress.kubernetes.io/load-balance: "round_robin"
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 80
      - path: /static
        pathType: Prefix
        backend:
          service:
            name: static-service
            port:
              number: 80
```

Weryfikacja:
```bash
# Test różnych ścieżek
curl http://example.com/api
curl http://example.com/admin
curl http://example.com/static
```

## Przydatne komendy do debugowania

```bash
# Sprawdzenie statusu Ingress
kubectl get ingress
kubectl describe ingress <nazwa-ingress>

# Sprawdzenie logów nginx-ingress-controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Sprawdzenie konfiguracji nginx
kubectl exec -n ingress-nginx -it <pod-name> -- nginx -T

# Test połączenia
curl -v http://example.com
``` 