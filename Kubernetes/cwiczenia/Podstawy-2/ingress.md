# Kubernetes - Ćwiczenia: Ingress

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć konfigurację Ingress w Kubernetes. Ingress zarządza zewnętrznym dostępem HTTP/HTTPS do usług w klastrze, zapewniając routing oparty na ścieżkach URL i hostach, load balancing oraz terminację SSL/TLS.

> **⚠️ WAŻNE:** Ćwiczenia z Ingress wymagają zainstalowanego kontrolera Ingress (np. NGINX Ingress Controller lub Application Gateway Ingress Controller w AKS). Jeśli nie masz kontrolera, Ingress pozostanie w stanie Pending i nie będzie działał.

**Co to jest Ingress?** Ingress to obiekt API, który zarządza zewnętrznym dostępem HTTP/HTTPS do usług w klastrze. Ingress zapewnia routing oparty na ścieżkach URL i hostach, load balancing, terminację SSL/TLS i routing oparty na nazwach wirtualnych hostów.

## Ćwiczenie 1.1: Podstawowy Ingress

**Zadanie:** Utwórz Deployment `nginx-app` z 2 replikami (obraz `nginx:latest`, etykieta `app: nginx`) w namespace `cwiczenia`, Service typu ClusterIP `nginx-svc` oraz Ingress `nginx-ingress`, który kieruje ruch z hosta `nginx.local` do Service na porcie 80.

**Wskazówki:**
- **Wymagany jest kontroler Ingress** (np. NGINX Ingress Controller). Sprawdź czy jest zainstalowany: `kubectl get ingressclass`
- Użyj `apiVersion: networking.k8s.io/v1` i `kind: Ingress`
- W `spec.ingressClassName` określ klasę Ingress (np. `nginx`)
- W `spec.rules` określ `host` i `paths`
- W `spec.rules[].http.paths[].backend.service` określ nazwę Service i port
- **Kolejność tworzenia:** Najpierw Deployment, potem Service, na końcu Ingress

**Cel:** Zrozumienie podstawowej konfiguracji Ingress i routingu HTTP.

**Weryfikacja:**
```bash
# Sprawdź Ingress
kubectl get ingress nginx-ingress -n cwiczenia

# Zobacz szczegóły Ingress (sprawdź ADDRESS - powinien mieć adres IP)
kubectl describe ingress nginx-ingress -n cwiczenia

# Sprawdź czy kontroler Ingress jest zainstalowany
kubectl get pods -n ingress-nginx

# Przetestuj dostęp (dodaj wpis do /etc/hosts lub użyj curl z nagłówkiem Host)
# echo "<INGRESS-IP> nginx.local" | sudo tee -a /etc/hosts
# curl http://nginx.local
# Lub bezpośrednio:
curl -H "Host: nginx.local" http://<INGRESS-IP>
```

---

## Ćwiczenie 1.2: Ingress z wieloma ścieżkami

**Zadanie:** Utwórz dwa Deploymenty w namespace `cwiczenia`:
- `app1` z obrazem `nginx:latest` (etykieta `app: app1`)
- `app2` z obrazem `httpd:latest` (etykieta `app: app2`)

Utwórz odpowiednie Services i jeden Ingress `multi-path-ingress`, który:
- Kieruje `/app1` do Service `app1-svc`
- Kieruje `/app2` do Service `app2-svc`
- Wszystko na hoście `apps.local`

**Wskazówki:**
- W `spec.rules[].http.paths` możesz zdefiniować wiele ścieżek
- Każda ścieżka może kierować do innego Service
- Użyj `pathType: Prefix` dla prefiksów ścieżek

**Cel:** Zrozumienie routingu opartego na ścieżkach URL w Ingress.

**Weryfikacja:**
```bash
# Sprawdź Ingress
kubectl get ingress multi-path-ingress -n cwiczenia

# Przetestuj różne ścieżki
curl -H "Host: apps.local" http://<INGRESS-IP>/app1
curl -H "Host: apps.local" http://<INGRESS-IP>/app2

# Sprawdź logi Podów, aby zobaczyć, że ruch trafia do odpowiednich aplikacji
kubectl logs -l app=app1 -n cwiczenia
kubectl logs -l app=app2 -n cwiczenia
```

---

## Ćwiczenie 1.3: Ingress z TLS/HTTPS

**Zadanie:** Utwórz Deployment `secure-app` z obrazem `nginx:latest` i Service `secure-svc` w namespace `cwiczenia`. Utwórz Secret z certyfikatem TLS o nazwie `tls-secret` (możesz użyć self-signed) oraz Ingress `secure-ingress` z:
- Hostem `secure.local`
- Terminacją TLS używającą Secret `tls-secret`

**Wskazówki:**
- Utwórz Secret typu `kubernetes.io/tls` z kluczami `tls.crt` i `tls.key`
- W Ingress w sekcji `spec.tls` określ `hosts` i `secretName`
- Możesz wygenerować self-signed certyfikat używając `openssl`

**Cel:** Zrozumienie konfiguracji HTTPS/TLS w Ingress.

**Weryfikacja:**
```bash
# Utwórz self-signed certyfikat (przykład)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=secure.local"

# Utwórz Secret
kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key -n cwiczenia

# Sprawdź Ingress
kubectl get ingress secure-ingress -n cwiczenia

# Przetestuj HTTPS (może wymagać --insecure dla self-signed)
curl -k https://secure.local
# Lub z nagłówkiem Host:
curl -k -H "Host: secure.local" https://<INGRESS-IP>
```

---

## Podsumowanie

Po wykonaniu ćwiczeń z Ingress powinieneś:
- ✅ Rozumieć podstawową konfigurację Ingress
- ✅ Umieć konfigurować routing oparty na hostach i ścieżkach
- ✅ Umieć konfigurować terminację TLS/HTTPS

## Przydatne komendy

```bash
# Ingress
kubectl get ingress
kubectl describe ingress <name>
kubectl get ingressclass

# Sprawdzanie kontrolera Ingress
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Testowanie
curl -H "Host: <hostname>" http://<INGRESS-IP>
curl -k -H "Host: <hostname>" https://<INGRESS-IP>
```

