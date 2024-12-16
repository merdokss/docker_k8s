## Kubernetes ćwiczenia

### Pod, ReplicaSet
- Utworzyć ReplicaSet dla aplikacji nginx z 4 replikami. Wykonać testy usunięcia podów i zweryfikować czas uruchomienia nowych podów.
- Utworzyć ReplicaSet dla aplikacji nginx z 4 replikami oraz obiekt Service typu ClusterIP (port 88) oraz zweryfikowac czy działa poprzez port-forward.
- Utworzyć dwa pody z nginx z etykietą app=nginx oraz dwa pody z httpd z etykietą app=nginx. Dodatkowo utworzyć Service typu LoadBalancer (z etykietą app=nginx) i sprawdzić, jak działa ruch sieciowy.

### Deployment, LivenessProbe, Resources 
- Przy użyciu obiektu Deployment uruchomić aplikację httpd i ustawić LivenessProbe - weryfikacja, czy prawidłowo działa httpd.
- Przy użyciu obiektu Deployment uruchomić bazę danych PostgreSQL - wystawić niezbędne porty, ustawić limity zasobów oraz ReadinessProbe.
- Utworzyć Deployment dla aplikacji Redis z konfiguracją PersistentVolumeClaim, aby zapewnić trwałość danych.
- Utworzyć Deployment dla aplikacji Node.js z konfiguracją LivenessProbe, ReadinessProbe, Resource Limits.

### Troubleshooting
- Zaimplementować definicję pod-failed.yaml i zweryfikować poprawność uruchomienia zasobów. W razie potrzeby poprawić konfigurację.
- Zaimplementować definicję mysql-deploy.yaml i zweryfikować poprawność uruchomienia zasobów. W razie potrzeby poprawić konfigurację.

### App + DB
- Uruchomić aplikację ToDoS na Kubernetes - zgodnie z dostępnym docker-compose.yaml. 

### Docker + Kubernetes
- Zbudowac aplikacje własną (lub .NET z przykładu), następnie zrobic push do zewnętrznego registry. Następnie przygotowac odpowiednie obiekty Kubernetes (Deployment, Service etc) i uruchomic aplikacje na Kubernetes.


adres: k8sdockerreg.azurecr.io
user: k8sdockerreg
pass: C/saKrjF9+vOK73mSs7Hg/vRGE6PtnzcdF5yoWgbTW+ACRDpmxGX

> docker login k8sdockerreg.azurecr.io
Username: k8sdockerreg
Password: 
Login Succeeded