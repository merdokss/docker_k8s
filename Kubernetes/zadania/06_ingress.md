# Zadania - Ingress w Kubernetes

## Zadanie 1: Podstawowa konfiguracja Ingress
1. Utwórz podstawowy zasób Ingress, który będzie kierował ruch do serwisu o nazwie `web-service`.
2. Skonfiguruj regułę routingu dla ścieżki `/` do serwisu na porcie 80.
3. Zweryfikuj, czy Ingress poprawnie kieruje ruch do serwisu.

## Zadanie 2: Routing oparty na hostach
1. Skonfiguruj Ingress do obsługi wielu hostów (np. `app1.example.com` i `app2.example.com`).
2. Utwórz różne reguły routingu dla każdego hosta.
3. Przetestuj dostępność aplikacji przez różne hosty.

## Zadanie 3: TLS/SSL
1. Utwórz sekret zawierający certyfikat TLS.
2. Skonfiguruj Ingress do obsługi HTTPS.
3. Zweryfikuj, czy połączenia HTTPS działają poprawnie.

## Zadanie 4: Annotacje i konfiguracja zaawansowana
1. Dodaj annotacje do Ingress dla konfiguracji nginx-ingress-controller.
2. Skonfiguruj rewrite rules dla wybranych ścieżek.
3. Dodaj konfigurację rate limiting.

## Zadanie 5: Ingress z wieloma backendami
1. Skonfiguruj Ingress do obsługi wielu backendów w zależności od ścieżki URL.
2. Dodaj konfigurację load balancing między backendami.
3. Przetestuj różne ścieżki i zweryfikuj, czy ruch jest poprawnie kierowany.

## Wymagania:
- Znajomość podstawowych konceptów Kubernetes
- Dostęp do klastra Kubernetes z zainstalowanym Ingress Controller
- Narzędzia: kubectl, curl (do testowania)

## Przydatne komendy:
```bash
kubectl get ingress
kubectl describe ingress <nazwa-ingress>
kubectl get secrets
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
``` 