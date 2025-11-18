# Kubernetes Ingress i Cert-Manager - Kompletny Przewodnik

## 📚 Spis treści

- [Wprowadzenie](#wprowadzenie)
- [Czym jest Ingress?](#czym-jest-ingress)
- [Architektura Ingress](#architektura-ingress)
- [Instalacja Ingress Controller](#instalacja-ingress-controller)
- [Przykład z Self-Signed Certyfikatem](#przykład-z-self-signed-certyfikatem)
- [Czym jest Cert-Manager?](#czym-jest-cert-manager)
- [Instalacja Cert-Manager](#instalacja-cert-manager)
- [Automatyczne Certyfikaty z Let's Encrypt](#automatyczne-certyfikaty-z-lets-encrypt)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Wprowadzenie

Ten przewodnik wyjaśnia jak działa **Ingress** w Kubernetes oraz jak automatyzować zarządzanie certyfikatami SSL/TLS używając **Cert-Manager**.

### Czego się nauczysz?

- Jak działa routing w Kubernetes na poziomie L7
- Jak skonfigurować HTTPS z self-signed certyfikatami
- Jak zautomatyzować wystawianie certyfikatów z Let's Encrypt
- Best practices dla production

---

## Czym jest Ingress?

**Ingress** to zasób Kubernetes zarządzający zewnętrznym dostępem HTTP/HTTPS do usług w klastrze.

### Dlaczego Ingress?

❌ **Bez Ingress:**
- Osobny LoadBalancer dla każdej usługi = wysokie koszty
- NodePort = problemy z bezpieczeństwem i zarządzaniem portami
- Brak centralnego zarządzania SSL/TLS

✅ **Z Ingress:**
- Jeden punkt wejścia do klastra
- Routing oparty na domenach i ścieżkach
- Centralna terminacja SSL/TLS
- Oszczędność kosztów
- Łatwe zarządzanie

### Kiedy używać Ingress?

| Użyj Ingress gdy... | Użyj Service (LoadBalancer/NodePort) gdy... |
|---------------------|---------------------------------------------|
| Potrzebujesz HTTP/HTTPS routingu | Potrzebujesz protokołów TCP/UDP |
| Masz wiele aplikacji webowych | Masz pojedynczą usługę |
| Chcesz routing po nazwach domen | Nie potrzebujesz routing'u L7 |
| Potrzebujesz SSL termination | Prostota > funkcjonalność |

---

## Architektura Ingress

```
┌─────────────────────────────────────────────────┐
│                   Internet                      │
│            (https://app.example.com)            │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  Ingress Controller   │ ◄── Czyta konfigurację
         │    (NGINX/Traefik)    │
         │   ┌───────────────┐   │
         │   │  TLS Secrets  │   │
         │   └───────────────┘   │
         └───────────┬───────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   ┌─────────┐  ┌─────────┐  ┌─────────┐
   │Service A│  │Service B│  │Service C│
   └────┬────┘  └────┬────┘  └────┬────┘
        │            │            │
   ┌────┴────┐  ┌───┴────┐  ┌────┴────┐
   │ Pods A  │  │ Pods B │  │ Pods C  │
   └─────────┘  └────────┘  └─────────┘
                     ▲
                     │
              ┌──────┴──────┐
              │   Ingress   │
              │  Resource   │
              │ (reguły)    │
              └─────────────┘
```

### Kluczowe komponenty:

1. **Ingress Resource** - definicja YAML z regułami routingu
2. **Ingress Controller** - implementacja (NGINX, Traefik, HAProxy)
3. **Service** - backend aplikacji
4. **TLS Secret** - certyfikaty SSL/TLS

---

## Instalacja Ingress Controller

### NGINX Ingress Controller (najpopularniejszy)

```bash
# Instalacja przez Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

### Weryfikacja instalacji

```bash
# Sprawdź czy pody działają
kubectl get pods -n ingress-nginx

# Sprawdź Service i jego External IP
kubectl get svc -n ingress-nginx

# Poczekaj aż External IP się pojawi (może zająć minutę)
```

---

## Przykład z Self-Signed Certyfikatem

### Krok 1: Wygeneruj certyfikat

```bash
# Generowanie self-signed certyfikatu
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=myapp.example.com/O=myapp"

# Utworzenie Secret w Kubernetes
kubectl create secret tls myapp-tls-secret \
  --cert=tls.crt \
  --key=tls.key \
  --namespace=default
```

### Krok 2: Deployment aplikacji

Utwórz plik `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
  namespace: default
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
```

```bash
kubectl apply -f deployment.yaml
```

### Krok 3: Ingress z TLS

Utwórz plik `ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: default
  annotations:
    # Przekierowanie HTTP -> HTTPS
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    # Przepisywanie ścieżek
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls-secret
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

```bash
kubectl apply -f ingress.yaml
```

### Krok 4: Testowanie

```bash
# Sprawdź status Ingress
kubectl get ingress myapp-ingress

# Zobacz szczegóły
kubectl describe ingress myapp-ingress

# Pobierz IP Ingress Controller
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Ingress IP: $INGRESS_IP"

# Dodaj do /etc/hosts (Linux/Mac) lub C:\Windows\System32\drivers\etc\hosts (Windows)
echo "$INGRESS_IP myapp.example.com" | sudo tee -a /etc/hosts

# Test
curl -k https://myapp.example.com
```

### Przykład z wieloma ścieżkami

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-path-ingress
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls-secret
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
```

---

## Czym jest Cert-Manager?

**Cert-Manager** to natywny kontroler Kubernetes do automatycznego zarządzania certyfikatami SSL/TLS.

### Co robi Cert-Manager?

```
┌─────────────────────────────────────────────────────┐
│              Cert-Manager Workflow                  │
└─────────────────────────────────────────────────────┘

1. Tworzysz Ingress z annotacją cert-manager
                    │
                    ▼
2. Cert-Manager wykrywa nowy Ingress
                    │
                    ▼
3. Tworzy Challenge (weryfikacja domeny)
                    │
                    ▼
4. Komunikuje się z Let's Encrypt (lub innym CA)
                    │
                    ▼
5. Przechodzi ACME Challenge (HTTP-01 lub DNS-01)
                    │
                    ▼
6. Otrzymuje certyfikat SSL/TLS
                    │
                    ▼
7. Tworzy Kubernetes Secret z certyfikatem
                    │
                    ▼
8. Ingress automatycznie używa nowego certyfikatu
                    │
                    ▼
9. Auto-renewal 30 dni przed wygaśnięciem
```

### Dlaczego Cert-Manager?

| Bez Cert-Manager | Z Cert-Manager |
|------------------|----------------|
| ✋ Ręczne wystawianie certyfikatów | ✅ Automatyczne wystawianie |
| ✋ Ręczne odnawianie co 90 dni | ✅ Auto-renewal |
| ✋ Ryzyko wygaśnięcia certyfikatu | ✅ Monitoring i alerty |
| ✋ Skomplikowany proces | ✅ Deklaratywna konfiguracja |
| ✋ Trudne w skalowaniu | ✅ Skaluje się automatycznie |

### Komponenty Cert-Manager

1. **Issuer/ClusterIssuer** - definicja CA (Let's Encrypt, własny CA)
2. **Certificate** - zasób reprezentujący certyfikat
3. **CertificateRequest** - żądanie certyfikatu
4. **Order** - zamówienie w ACME (Let's Encrypt)
5. **Challenge** - weryfikacja własności domeny

---

## Instalacja Cert-Manager

### Metoda 1: Przez kubectl (szybka)

```bash
# Instalacja Cert-Manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Weryfikacja
kubectl get pods -n cert-manager

# Poczekaj aż wszystkie pody będą Running
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s
```

### Metoda 2: Przez Helm (zalecana dla production)

```bash
# Dodaj repozytorium Helm
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Instalacja
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.2 \
  --set installCRDs=true

# Weryfikacja
kubectl get pods -n cert-manager
```

---

## Automatyczne Certyfikaty z Let's Encrypt

### Metoda weryfikacji: HTTP-01 vs DNS-01

| HTTP-01 Challenge | DNS-01 Challenge |
|-------------------|------------------|
| ✅ Prostsza konfiguracja | ⚙️ Wymaga integracji z DNS |
| ✅ Nie wymaga credentials | ⚙️ Potrzebuje API key do DNS |
| ❌ Wymaga publicznego IP | ✅ Działa dla prywatnych klastrów |
| ❌ Nie wspiera wildcard | ✅ Wspiera wildcard (*.example.com) |
| Port 80 musi być dostępny | Nie wymaga otwartych portów |

### Krok 1: ClusterIssuer dla Let's Encrypt (Staging)

**⚠️ Używaj staging do testów! Production ma rate limity.**

Utwórz plik `letsencrypt-staging.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # Let's Encrypt Staging API
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email do powiadomień o wygasających certyfikatach
    email: twoj-email@example.com
    # Secret do przechowywania klucza prywatnego ACME
    privateKeySecretRef:
      name: letsencrypt-staging
    # HTTP-01 challenge (weryfikacja przez HTTP)
    solvers:
    - http01:
        ingress:
          class: nginx
```

```bash
kubectl apply -f letsencrypt-staging.yaml
```

### Krok 2: ClusterIssuer dla Let's Encrypt (Production)

**Używaj dopiero gdy staging działa!**

Utwórz plik `letsencrypt-production.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Let's Encrypt Production API
    server: https://acme-v02.api.letsencrypt.org/directory
    email: twoj-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

```bash
kubectl apply -f letsencrypt-production.yaml
```

### Krok 3: Ingress z automatycznym certyfikatem

Utwórz plik `ingress-with-certmanager.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: default
  annotations:
    # KLUCZOWA ADNOTACJA - włącza Cert-Manager
    cert-manager.io/cluster-issuer: "letsencrypt-staging"
    # Opcjonalnie: przekierowanie HTTP -> HTTPS
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    # Cert-Manager automatycznie utworzy ten Secret
    secretName: myapp-tls-auto
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

```bash
kubectl apply -f ingress-with-certmanager.yaml
```

### Krok 4: Monitorowanie procesu

```bash
# Sprawdź Certificate
kubectl get certificate
kubectl describe certificate myapp-tls-auto

# Sprawdź CertificateRequest
kubectl get certificaterequest
kubectl describe certificaterequest myapp-tls-auto-xxxxx

# Sprawdź Challenge (weryfikacja domeny)
kubectl get challenge
kubectl describe challenge myapp-tls-auto-xxxxx-xxxxx

# Sprawdź Order
kubectl get order

# Logi Cert-Manager
kubectl logs -n cert-manager deploy/cert-manager -f

# Sprawdź czy Secret został utworzony
kubectl get secret myapp-tls-auto
kubectl describe secret myapp-tls-auto
```

### Krok 5: Przejście na Production

Gdy staging działa, zmień adnotację:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"  # Zmiana z staging na prod
```

```bash
# Usuń stary certyfikat staging
kubectl delete secret myapp-tls-auto

# Zastosuj nową konfigurację
kubectl apply -f ingress-with-certmanager.yaml

# Monitoruj proces
kubectl get certificate -w
```

### Przykład z wildcard certyfikatem (DNS-01)

Dla wildcard (*.example.com) musisz użyć DNS-01 challenge.

Przykład z CloudFlare:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: twoj-email@example.com
    privateKeySecretRef:
      name: letsencrypt-dns
    solvers:
    - dns01:
        cloudflare:
          email: twoj-email@cloudflare.com
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
```

Utwórz Secret z API tokenem:

```bash
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=YOUR_CLOUDFLARE_API_TOKEN
```

Ingress z wildcard:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wildcard-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - "*.example.com"
    - example.com
    secretName: wildcard-tls
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

---

## Troubleshooting

### Problem 1: Ingress Address jest pusty

```bash
# Sprawdź Ingress Controller
kubectl get pods -n ingress-nginx

# Sprawdź Service
kubectl get svc -n ingress-nginx

# Sprawdź logi
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller
```

**Rozwiązanie:** Poczekaj na External IP lub użyj port-forward do testów.

### Problem 2: Certyfikat nie jest wystawiany

```bash
# Sprawdź Certificate
kubectl describe certificate myapp-tls-auto

# Sprawdź Challenge
kubectl get challenge
kubectl describe challenge <challenge-name>

# Logi Cert-Manager
kubectl logs -n cert-manager deploy/cert-manager
```

**Częste przyczyny:**
- Domena nie wskazuje na Ingress IP
- Port 80 jest zablokowany (HTTP-01 challenge)
- Błędny email w ClusterIssuer
- Rate limit Let's Encrypt (użyj staging!)

### Problem 3: "too many certificates already issued"

**Rozwiązanie:** Rate limit Let's Encrypt. Użyj staging lub poczekaj tydzień.

```bash
# Usuń certyfikat i użyj staging
kubectl delete certificate myapp-tls-auto
# Zmień ClusterIssuer na letsencrypt-staging
```

### Problem 4: 502 Bad Gateway

```bash
# Sprawdź czy Service działa
kubectl get svc myapp-service
kubectl get endpoints myapp-service

# Sprawdź czy Pody działają
kubectl get pods -l app=myapp

# Sprawdź logi aplikacji
kubectl logs -l app=myapp
```

### Problem 5: Certyfikat wygasł

Cert-Manager automatycznie odnawia 30 dni przed wygaśnięciem, ale możesz wymusić:

```bash
# Usuń Secret (Cert-Manager utworzy nowy)
kubectl delete secret myapp-tls-auto

# Lub usuń Certificate (wymusi ponowne wystawienie)
kubectl delete certificate myapp-tls-auto
```

### Debug Commands Cheat Sheet

```bash
# Wszystkie zasoby Ingress
kubectl get ingress --all-namespaces

# Szczegóły Ingress
kubectl describe ingress <name>

# Certyfikaty
kubectl get certificate --all-namespaces
kubectl describe certificate <name>

# Sprawdź Secret
kubectl get secret <tls-secret-name> -o yaml

# Cert-Manager logi
kubectl logs -n cert-manager -l app=cert-manager -f

# Ingress Controller logi
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f

# Testy connectivity
kubectl run test-pod --image=curlimages/curl -it --rm -- sh
# W podzie:
curl http://myapp-service
```

---

## Best Practices

### 1. Zawsze używaj TLS

```yaml
annotations:
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
  nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
```

### 2. Ustaw resource limits

```yaml
spec:
  containers:
  - name: app
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "500m"
```

### 3. Używaj staging dla testów

Zawsze testuj z `letsencrypt-staging` przed użyciem production.

### 4. Monitoruj certyfikaty

```bash
# Sprawdź daty wygaśnięcia
kubectl get certificate -o wide

# Ustaw alerty na certyfikaty wygasające
```

### 5. Backup ClusterIssuer

```bash
# Zapisz konfigurację
kubectl get clusterissuer -o yaml > clusterissuer-backup.yaml
```

### 6. Używaj Helm dla złożonych deploymentów

```bash
# Przykład: aplikacja + ingress + cert-manager w jednym
helm create myapp
# Edytuj values.yaml z konfiguracją ingress
```

### 7. Security Headers

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
```

### 8. Rate Limiting

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-connections: "5"
```

### 9. Path-based routing strategically

```yaml
# Dobre
/api/v1     -> api-v1-service
/api/v2     -> api-v2-service
/static     -> cdn-service

# Unikaj zbyt szczegółowych ścieżek
# /api/users/profile/settings/privacy <- za szczegółowe dla Ingress
```

### 10. Multi-environment setup

```bash
# Staging
myapp-staging.example.com -> staging namespace

# Production
myapp.example.com -> production namespace
```

---

## Podsumowanie

### Ingress

- ✅ Jeden LoadBalancer dla wielu aplikacji
- ✅ Routing L7 (domena + ścieżka)
- ✅ Centralna terminacja TLS
- ✅ Oszczędność kosztów

### Cert-Manager

- ✅ Automatyczne wystawianie certyfikatów
- ✅ Auto-renewal co 60 dni (30 dni przed wygaśnięciem)
- ✅ Integracja z Let's Encrypt (darmowe certyfikaty!)
- ✅ Deklaratywne zarządzanie

### Workflow w Production

1. Zainstaluj NGINX Ingress Controller
2. Zainstaluj Cert-Manager
3. Utwórz ClusterIssuer (staging i production)
4. Deployuj aplikację + Service
5. Utwórz Ingress z adnotacją cert-manager
6. Monitoruj Certificate
7. Profit! 🎉

---

## Dodatkowe Materiały

- [NGINX Ingress Docs](https://kubernetes.github.io/ingress-nginx/)
- [Cert-Manager Docs](https://cert-manager.io/docs/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [Kubernetes Ingress Docs](https://kubernetes.io/docs/concepts/services-networking/ingress/)

---

## Licencja

Ten materiał szkoleniowy jest dostępny do użytku edukacyjnego.

Autor: DevOps Training Team  
Data: 2025