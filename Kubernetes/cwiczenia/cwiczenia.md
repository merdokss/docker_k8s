## Kubernetes ćwiczenia

### Pod, ReplicaSet
- Utworzyć ReplicaSet dla aplikacji nginx z 4 replikami. Wykonać testy usunięcia podów i zweryfikować czas uruchomienia nowych podów.
- Utworzyć ReplicaSet dla aplikacji nginx z 4 replikami oraz obiekt Service typu ClusterIP (port 88) oraz zweryfikowac czy działa poprzez port-forward.
- Utworzyć dwa pody z nginx z etykietą app=nginx oraz dwa pody z httpd z etykietą app=nginx. Dodatkowo utworzyć Service typu LoadBalancer (z etykietą app=nginx) i sprawdzić, jak działa ruch sieciowy.

### Deployment, LivenessProbe, Resources 
- Przy użyciu obiektu Deployment uruchomić aplikację httpd i ustawić LivenessProbe - weryfikacja, czy prawidłowo działa httpd.
- Przy użyciu obiektu Deployment uruchomić bazę danych PostgreSQL - wystawić niezbędne porty, ustawić limity zasobów oraz ReadinessProbe.
- Utworzyć Deployment dla aplikacji Node.js z konfiguracją LivenessProbe, ReadinessProbe, Resource Limits.


### Troubleshooting
- Zaimplementować definicję pod-failed.yaml i zweryfikować poprawność uruchomienia zasobów. W razie potrzeby poprawić konfigurację.
- Zaimplementować definicję mysql-deploy.yaml i zweryfikować poprawność uruchomienia zasobów. W razie potrzeby poprawić konfigurację.


### Wordpress - uruchomic aplikacje wordpress + DB na Kubernetes

### App + DB
- Uruchomić aplikację ToDoS na Kubernetes - zgodnie z dostępnym docker-compose.yaml. 
1. FE i BE deploy
2. FE i BE Services
3. MongoDB jako Deploy bez PV
4. Określic i wdrozyc livessprobe oraz readinessprobe dla BE i FE
5. 
