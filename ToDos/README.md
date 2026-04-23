### Wazne dla AKS Ingress!!!

Działa! HTTP 200 OK — domena dawidapp.mooo.com odpowiada poprawnie.

Podsumowanie problemu i rozwiązania:

Problem był w Azure Load Balancer health probe. AKS automatycznie ustawił probe HTTP GET / na porcie 31082 (NodePort nginx), ale nginx zwracał 404 (brak pasującego Ingressa dla tego żądania bez Host headera). Azure LB uznawał backend za niezdrowy i blokował cały ruch.

Fix: helm upgrade z adnotacjami:

azure-load-balancer-health-probe-request-path: /healthz → nginx zwraca 200 dla tej ścieżki
azure-load-balancer-health-probe-port: "10254" → (dla pewności)
To klasyczny konflikt AKS + nginx ingress — health probe sprawdza HTTP, a nginx bez pasującego Ingressa zwraca 404.