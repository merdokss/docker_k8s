# Kubernetes - Ćwiczenia Podstawowe

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć podstawowe zasoby Kubernetes. Każde ćwiczenie zawiera opis zadania, cel edukacyjny i komendy weryfikacyjne. Rozwiązania znajdują się w katalogu `rozwiazania/`, ale spróbuj najpierw wykonać ćwiczenia samodzielnie!

## 1. Pods (Pody)

**Co to jest Pod?** Pod to najmniejsza jednostka wdrożeniowa w Kubernetes. Zawiera jeden lub więcej kontenerów, które współdzielą zasoby sieciowe i storage. Większość Podów zawiera jeden kontener.

### Ćwiczenie 1.1: Utworzenie prostego Poda

**Zadanie:** Utwórz Pod z obrazem `nginx:latest` o nazwie `my-nginx-pod`. Pod powinien mieć etykietę `app: nginx` i wystawiać port 80.

**Wskazówki:**
- Utwórz plik YAML z definicją Poda
- Użyj `apiVersion: v1` i `kind: Pod`
- W sekcji `spec.containers` określ nazwę kontenera, obraz i port

**Cel:** Zrozumienie podstawowej struktury obiektu Pod i jego najważniejszych pól.

**Weryfikacja:**
```bash
# Sprawdź czy Pod został utworzony
kubectl get pods

# Zobacz szczegóły Poda
kubectl describe pod my-nginx-pod

# Sprawdź logi kontenera
kubectl logs my-nginx-pod
```

---

### Ćwiczenie 1.2: Pod z wieloma kontenerami

**Zadanie:** Utwórz Pod o nazwie `multi-container-pod` zawierający dwa kontenery:
- `nginx` - obraz `nginx:latest`, port 80
- `busybox` - obraz `busybox:latest` z komendą `sleep 3600`

**Wskazówki:**
- W sekcji `spec.containers` możesz zdefiniować wiele kontenerów
- Każdy kontener musi mieć unikalną nazwę (`name`)
- Kontenery w tym samym Podzie współdzielą IP i mogą komunikować się przez `localhost`

**Cel:** Zrozumienie koncepcji kontenerów współdzielących przestrzeń w jednym Podzie.

**Weryfikacja:**
```bash
# Sprawdź status Poda (powinien pokazać 2/2 kontenery gotowe)
kubectl get pod multi-container-pod

# Wejdź do kontenera nginx
kubectl exec -it multi-container-pod -c nginx -- /bin/sh

# Wejdź do kontenera busybox
kubectl exec -it multi-container-pod -c busybox -- /bin/sh
```

---

### Ćwiczenie 1.3: Pod z limitami zasobów

**Zadanie:** Utwórz Pod o nazwie `nginx-resources` z obrazem `nginx:latest` z następującymi limitami:
- CPU: request 100m, limit 200m
- Memory: request 128Mi, limit 256Mi

**Wskazówki:**
- `requests` - minimalne zasoby gwarantowane dla kontenera (scheduler używa tego do wyboru noda)
- `limits` - maksymalne zasoby, które kontener może użyć
- `100m` = 100 milicores (0.1 CPU)
- `128Mi` = 128 Mebibytes pamięci

**Cel:** Zrozumienie zarządzania zasobami w Podach i różnicy między request a limit.

**Weryfikacja:**
```bash
# Zobacz pełną definicję Poda
kubectl get pod nginx-resources -o yaml

# Sprawdź użycie zasobów (wymaga metrics-server)
kubectl top pod nginx-resources
```

---

### Ćwiczenie 1.4: Pod z zmiennymi środowiskowymi

**Zadanie:** Utwórz Pod o nazwie `nginx-env` z obrazem `nginx:latest` zawierający następujące zmienne środowiskowe:
- `ENV_NAME`: `production`
- `APP_VERSION`: `1.0.0`

**Wskazówki:**
- Zmienne środowiskowe definiuje się w sekcji `spec.containers[].env`
- Każda zmienna ma `name` i `value`
- Zmienne są dostępne wewnątrz kontenera

**Cel:** Zrozumienie konfiguracji zmiennych środowiskowych w Podach.

**Weryfikacja:**
```bash
# Sprawdź zmienne środowiskowe w kontenerze
kubectl exec nginx-env -- env | grep ENV

# Zobacz konfigurację Poda
kubectl describe pod nginx-env
```

---

## 2. ReplicaSets (RS)

**Co to jest ReplicaSet?** ReplicaSet zapewnia, że określona liczba identycznych Podów jest zawsze uruchomiona. Jeśli Pod się zepsuje lub zostanie usunięty, ReplicaSet automatycznie utworzy nowy.

### Ćwiczenie 2.1: Utworzenie ReplicaSet

**Zadanie:** Utwórz ReplicaSet o nazwie `nginx-rs` z 3 replikami, używając obrazu `nginx:latest`. Etykiety: `app: nginx`, `tier: frontend`.

**Wskazówki:**
- Użyj `apiVersion: apps/v1` i `kind: ReplicaSet`
- Określ `spec.replicas: 3` dla 3 replik
- `spec.selector.matchLabels` musi pasować do etykiet w `spec.template.metadata.labels`
- `spec.template` zawiera definicję Poda, który będzie replikowany

**Cel:** Zrozumienie mechanizmu replikacji i zarządzania wieloma Podami.

**Weryfikacja:**
```bash
# Sprawdź ReplicaSet
kubectl get rs nginx-rs

# Zobacz wszystkie Pody zarządzane przez ReplicaSet
kubectl get pods -l app=nginx,tier=frontend

# Usuń jeden z Podów i obserwuj automatyczne odtworzenie
kubectl delete pod <nazwa-poda>
# Poczekaj chwilę i sprawdź ponownie - powinien pojawić się nowy Pod
kubectl get pods -l app=nginx,tier=frontend
```

---

### Ćwiczenie 2.2: Skalowanie ReplicaSet

**Zadanie:** Utwórz ReplicaSet `httpd-rs` z 2 replikami (obraz `httpd:latest`), a następnie:
1. Zwiększ liczbę replik do 5
2. Zmniejsz liczbę replik do 1

**Wskazówki:**
- Możesz skalować ReplicaSet używając komendy `kubectl scale`
- Możesz też edytować plik YAML i zmienić `spec.replicas`, a następnie zastosować zmiany przez `kubectl apply`

**Cel:** Zrozumienie skalowania ReplicaSet - jak zwiększać i zmniejszać liczbę replik.

**Weryfikacja:**
```bash
# Zwiększ liczbę replik do 5
kubectl scale rs httpd-rs --replicas=5

# Sprawdź ile Podów jest teraz uruchomionych
kubectl get pods -l app=httpd

# Zmniejsz liczbę replik do 1
kubectl scale rs httpd-rs --replicas=1

# Sprawdź ponownie - powinien pozostać tylko 1 Pod
kubectl get pods -l app=httpd
```

---

### Ćwiczenie 2.3: ReplicaSet z selektorem

**Zadanie:** Utwórz ReplicaSet `app-rs` z 3 replikami (obraz `nginx:latest`) z etykietą `app: webapp`. Następnie utwórz Pod ręcznie z tą samą etykietą i sprawdź, czy ReplicaSet go zarządza.

**Wskazówki:**
- ReplicaSet zarządza wszystkimi Podami, które pasują do jego selektora
- Jeśli utworzysz Pod ręcznie z etykietą pasującą do selektora, ReplicaSet może go usunąć, aby utrzymać żądaną liczbę replik
- To pokazuje, że ReplicaSet kontroluje wszystkie Pody z pasującymi etykietami

**Cel:** Zrozumienie działania selektorów w ReplicaSet i jak ReplicaSet zarządza Podami.

**Weryfikacja:**
```bash
# Sprawdź ReplicaSet
kubectl get rs app-rs

# Utwórz Pod ręcznie z etykietą app: webapp
kubectl run manual-pod --image=nginx:latest --labels="app=webapp"

# Sprawdź wszystkie Pody z etykietą app=webapp
kubectl get pods -l app=webapp

# Obserwuj co się stanie - ReplicaSet może usunąć ręcznie utworzony Pod,
# aby utrzymać dokładnie 3 repliki (jeśli już ma 3)
```

---

### Ćwiczenie 2.4: ReplicaSet z limitami zasobów
Utwórz ReplicaSet `nginx-rs-resources` z 2 replikami, gdzie każdy Pod ma:
- CPU: request 50m, limit 100m
- Memory: request 64Mi, limit 128Mi

**Cel:** Zrozumienie zarządzania zasobami w ReplicaSet.

**Weryfikacja:**
```bash
kubectl get rs nginx-rs-resources
kubectl describe rs nginx-rs-resources
kubectl top pods -l app=nginx
```

---

## 3. Services (SVC)

**Co to jest Service?** Service to abstrakcja, która definiuje logiczny zestaw Podów i sposób dostępu do nich. Service zapewnia stabilny adres IP i DNS, nawet gdy Pody się zmieniają.

**Typy Services:**
- **ClusterIP** (domyślny) - dostępny tylko wewnątrz klastra
- **NodePort** - wystawia aplikację na porcie każdego noda
- **LoadBalancer** - tworzy zewnętrzny load balancer (w chmurze)

### Ćwiczenie 3.1: Service typu ClusterIP

**Zadanie:** Utwórz Deployment `nginx-deploy` z 3 replikami (obraz `nginx:latest`, etykieta `app: nginx`). Następnie utwórz Service typu ClusterIP o nazwie `nginx-svc`, który łączy się z Podami na porcie 80.

**Wskazówki:**
- Deployment zarządza Podami (będzie omówiony w następnej sekcji)
- Service używa `spec.selector` do znalezienia Podów
- `spec.ports[].port` - port Service
- `spec.ports[].targetPort` - port kontenera

**Cel:** Zrozumienie podstawowego Service i komunikacji wewnątrz klastra.

**Weryfikacja:**
```bash
# Sprawdź Service
kubectl get svc nginx-svc

# Zobacz endpointy (adresy IP Podów, które Service kieruje ruch)
kubectl get endpoints nginx-svc

# Port-forward do testowania (w osobnym terminalu)
kubectl port-forward svc/nginx-svc 8080:80
# Następnie w przeglądarce otwórz http://localhost:8080
```

---

### Ćwiczenie 3.2: Service typu NodePort

**Zadanie:** Utwórz Deployment `httpd-deploy` z 2 replikami (obraz `httpd:latest`, etykieta `app: httpd`). Utwórz Service typu NodePort o nazwie `httpd-nodeport`, który wystawia port 80 kontenera na port NodePort.

**Wskazówki:**
- NodePort automatycznie przypisze losowy port z zakresu 30000-32767
- Możesz też określić konkretny port używając `spec.ports[].nodePort`
- Aplikacja będzie dostępna na `<IP-NODA>:<NODEPORT>`

**Cel:** Zrozumienie dostępu do aplikacji z zewnątrz klastra przez NodePort.

**Weryfikacja:**
```bash
# Sprawdź Service (zobacz kolumnę PORT - będzie pokazywać 80:XXXXX/TCP)
kubectl get svc httpd-nodeport

# Zobacz adresy IP nodów
kubectl get nodes -o wide

# Przetestuj dostęp (zamień <IP-NODA> i <NODEPORT> na rzeczywiste wartości)
curl http://<IP-NODA>:<NODEPORT>
# Lub w przeglądarce: http://<IP-NODA>:<NODEPORT>
```

---

### Ćwiczenie 3.3: Service typu LoadBalancer

**Zadanie:** Utwórz Deployment `nginx-lb` z 3 replikami (obraz `nginx:latest`, etykieta `app: nginx-lb`). Utwórz Service typu LoadBalancer o nazwie `nginx-lb-svc`.

**Wskazówki:**
- LoadBalancer automatycznie tworzy zewnętrzny load balancer w chmurze (AKS, EKS, GKE)
- W środowiskach lokalnych (Kind, Minikube) może pozostać w stanie `pending`
- Po utworzeniu otrzymasz zewnętrzny adres IP w kolumnie `EXTERNAL-IP`

**Cel:** Zrozumienie LoadBalancer Service i jak działa w środowiskach chmurowych.

**Weryfikacja:**
```bash
# Sprawdź Service (poczekaj chwilę na przydzielenie EXTERNAL-IP)
kubectl get svc nginx-lb-svc

# W AKS/GKE/EKS powinieneś zobaczyć zewnętrzny adres IP
# W środowiskach lokalnych może pokazywać <pending>

# Jeśli masz EXTERNAL-IP, przetestuj:
curl http://<EXTERNAL-IP>
```

---

### Ćwiczenie 3.4: Service z wieloma portami

**Zadanie:** Utwórz Deployment `multi-port-app` z obrazem `nginx:latest` (etykieta `app: multi`). Utwórz Service `multi-port-svc` typu ClusterIP, który wystawia:
- Port 80 (http) -> targetPort 80
- Port 443 (https) -> targetPort 80 (dla przykładu)

**Wskazówki:**
- Service może wystawiać wiele portów jednocześnie
- Każdy port musi mieć unikalną nazwę (`name`)
- Różne porty Service mogą kierować do tego samego `targetPort` kontenera

**Cel:** Zrozumienie konfiguracji Service z wieloma portami.

**Weryfikacja:**
```bash
# Zobacz pełną konfigurację Service
kubectl get svc multi-port-svc -o yaml

# Zobacz szczegóły Service (sprawdź sekcję Port)
kubectl describe svc multi-port-svc

# Powinieneś zobaczyć dwa porty: 80/TCP i 443/TCP
```

---

## 4. Deployments (Deploy)

**Co to jest Deployment?** Deployment zarządza ReplicaSet i zapewnia deklaratywne aktualizacje Podów. Deployment automatycznie tworzy ReplicaSet, który zarządza Podami. Główna różnica: Deployment obsługuje aktualizacje i rollback, ReplicaSet tylko utrzymuje liczbę replik.

### Ćwiczenie 4.1: Utworzenie Deployment

**Zadanie:** Utwórz Deployment o nazwie `nginx-deployment` z 3 replikami, używając obrazu `nginx:1.20`. Etykiety: `app: nginx`, `version: v1`.

**Wskazówki:**
- Użyj `apiVersion: apps/v1` i `kind: Deployment`
- Struktura jest podobna do ReplicaSet, ale Deployment automatycznie zarządza ReplicaSet
- Deployment tworzy ReplicaSet w tle - możesz to zobaczyć przez `kubectl get rs`

**Cel:** Zrozumienie podstaw Deployment i różnicy względem ReplicaSet.

**Weryfikacja:**
```bash
# Sprawdź Deployment
kubectl get deployment nginx-deployment

# Zobacz automatycznie utworzony ReplicaSet
kubectl get rs

# Sprawdź Pody zarządzane przez Deployment
kubectl get pods -l app=nginx,version=v1
```

---

### Ćwiczenie 4.2: Aktualizacja Deployment (Rolling Update)

**Zadanie:** Utwórz Deployment `nginx-rolling` z obrazem `nginx:1.20` i 3 replikami. Następnie zaktualizuj obraz do `nginx:1.21` i obserwuj proces aktualizacji.

**Wskazówki:**
- Rolling Update oznacza, że nowe Pody są tworzone stopniowo, a stare są usuwane
- Dzięki temu aplikacja pozostaje dostępna podczas aktualizacji
- Możesz zaktualizować obraz używając `kubectl set image` lub edytując YAML i używając `kubectl apply`

**Cel:** Zrozumienie mechanizmu Rolling Update w Deployment - jak Kubernetes aktualizuje aplikacje bez przestoju.

**Weryfikacja:**
```bash
# Zaktualizuj obraz
kubectl set image deployment/nginx-rolling nginx=nginx:1.21

# Obserwuj status aktualizacji (w osobnym terminalu)
kubectl rollout status deployment/nginx-rolling

# Obserwuj Pody w czasie rzeczywistym (zobaczysz jak stare są zastępowane nowymi)
kubectl get pods -w

# Zobacz historię wersji Deployment
kubectl rollout history deployment/nginx-rolling
```

---

### Ćwiczenie 4.3: Rollback Deployment

**Zadanie:** Po wykonaniu ćwiczenia 4.2, wykonaj rollback do poprzedniej wersji Deployment.

**Wskazówki:**
- Rollback przywraca poprzednią wersję Deployment
- Kubernetes przechowuje historię wersji (domyślnie ostatnie 10)
- Rollback również używa mechanizmu Rolling Update

**Cel:** Zrozumienie mechanizmu rollback w Deployment - jak cofnąć nieudaną aktualizację.

**Weryfikacja:**
```bash
# Cofnij do poprzedniej wersji
kubectl rollout undo deployment/nginx-rolling

# Obserwuj status rollback
kubectl rollout status deployment/nginx-rolling

# Sprawdź Pody (powinny wrócić do poprzedniej wersji obrazu)
kubectl get pods

# Zobacz historię (rollback tworzy nowy wpis)
kubectl rollout history deployment/nginx-rolling
```

---

### Ćwiczenie 4.4: Deployment z Liveness i Readiness Probe

**Zadanie:** Utwórz Deployment `nginx-probes` z 2 replikami (obraz `nginx:latest`) z następującymi probe:
- **LivenessProbe:** HTTP GET na `/`, port 80, initialDelaySeconds: 30, periodSeconds: 10
- **ReadinessProbe:** HTTP GET na `/`, port 80, initialDelaySeconds: 5, periodSeconds: 5

**Wskazówki:**
- **LivenessProbe** - sprawdza czy kontener działa. Jeśli nie, Kubernetes restartuje kontener.
- **ReadinessProbe** - sprawdza czy kontener jest gotowy do przyjmowania ruchu. Jeśli nie, Service nie kieruje ruchu do tego Poda.
- `initialDelaySeconds` - czas oczekiwania przed pierwszym sprawdzeniem
- `periodSeconds` - jak często sprawdzać

**Cel:** Zrozumienie mechanizmów sprawdzania zdrowia aplikacji i różnicy między Liveness a Readiness Probe.

**Weryfikacja:**
```bash
# Sprawdź Deployment
kubectl get deployment nginx-probes

# Zobacz szczegóły Poda (znajdź sekcję z probe)
kubectl describe pod <nazwa-poda>

# Sprawdź sekcję Liveness i Readiness - powinny być widoczne w opisie
# Możesz też zobaczyć je w YAML:
kubectl get pod <nazwa-poda> -o yaml | grep -A 10 "livenessProbe\|readinessProbe"
```

---

## Podsumowanie

Po wykonaniu wszystkich ćwiczeń powinieneś:
- ✅ Rozumieć różnicę między Pod, ReplicaSet i Deployment
- ✅ Umieć tworzyć i zarządzać podstawowymi zasobami Kubernetes
- ✅ Rozumieć różne typy Services i ich zastosowanie
- ✅ Umieć skalować i aktualizować aplikacje
- ✅ Rozumieć koncepcję probe (Liveness/Readiness)

## Przydatne komendy

```bash
# Podstawowe operacje
kubectl get <resource>
kubectl describe <resource> <name>
kubectl create -f <file.yaml>
kubectl apply -f <file.yaml>
kubectl delete <resource> <name>

# Debugging
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/sh
kubectl port-forward <pod-name> <local-port>:<container-port>

# Skalowanie
kubectl scale <resource> <name> --replicas=<number>

# Deployment
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
```

