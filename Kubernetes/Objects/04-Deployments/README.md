## Deployment

Deployment w Kubernetes to obiekt, który zarządza wdrażaniem aplikacji na klastrze. Deployment umożliwia deklaratywne zarządzanie aplikacjami, co oznacza, że definiujesz pożądany stan aplikacji, a Kubernetes automatycznie dąży do osiągnięcia tego stanu. Deploymenty są używane do:

1. **Tworzenia i skalowania replik podów**: Deploymenty pozwalają na łatwe tworzenie i skalowanie liczby replik podów, co zapewnia wysoką dostępność i skalowalność aplikacji.
2. **Aktualizacji aplikacji**: Deploymenty umożliwiają bezpieczne i kontrolowane aktualizacje aplikacji, minimalizując przestoje i ryzyko błędów. Kubernetes wspiera różne strategie aktualizacji, takie jak RollingUpdate i Recreate.
3. **Zarządzania rollbackami**: Deploymenty przechowują historię wdrożeń, co pozwala na łatwe cofanie się do poprzednich wersji aplikacji w przypadku problemów.
4. **Monitorowania stanu aplikacji**: Deploymenty monitorują stan aplikacji i automatycznie podejmują działania naprawcze, takie jak ponowne uruchamianie podów w przypadku awarii.

Przykład definicji Deploymentu:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx-container
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

W powyższym przykładzie:

- `replicas: 3` określa liczbę replik podów, które powinny być uruchomione.
- `selector` definiuje selektor, który określa, które pody powinny być zarządzane przez ten Deployment.
- `template` definiuje szablon dla podów, które będą tworzone przez Deployment.
- `containers` definiuje kontenery, które będą uruchomione w podach.


### Strategie Deploymentu

W Kubernetes istnieją różne strategie deploymentu, które pozwalają na kontrolowanie sposobu wdrażania nowych wersji aplikacji. Oto najważniejsze z nich:

1. **RollingUpdate**:
   - Jest to domyślna strategia deploymentu w Kubernetes.
   - Polega na stopniowym zastępowaniu starych replik podów nowymi, co pozwala na zachowanie wysokiej dostępności aplikacji podczas aktualizacji.
   - Można kontrolować liczbę jednocześnie niedostępnych podów (`maxUnavailable`) oraz liczbę jednocześnie tworzonych nowych podów (`maxSurge`).
   - Przykład konfiguracji:
     ```yaml
     strategy:
       type: RollingUpdate
       rollingUpdate:
         maxUnavailable: 1
         maxSurge: 1
     ```

2. **Recreate**:
   - W tej strategii wszystkie stare repliki podów są najpierw usuwane, a następnie tworzone są nowe repliki.
   - Może to prowadzić do krótkiego przestoju aplikacji, ponieważ nie ma jednoczesnego uruchamiania starych i nowych podów.
   - Przykład konfiguracji:
     ```yaml
     strategy:
       type: Recreate
     ```

3. **Blue-Green Deployment**:
   - Ta strategia polega na uruchomieniu nowej wersji aplikacji (blue) równolegle z obecną wersją (green).
   - Po przetestowaniu nowej wersji, ruch sieciowy jest przekierowywany do nowej wersji.
   - Kubernetes nie wspiera bezpośrednio tej strategii, ale można ją zaimplementować za pomocą dodatkowych narzędzi i konfiguracji, takich jak Ingress lub Service.

4. **Canary Deployment**:
   - Polega na wdrażaniu nowej wersji aplikacji tylko dla części użytkowników, podczas gdy reszta nadal korzysta z obecnej wersji.
   - Pozwala to na przetestowanie nowej wersji w rzeczywistych warunkach przed pełnym wdrożeniem.
   - Podobnie jak Blue-Green Deployment, Kubernetes nie wspiera bezpośrednio tej strategii, ale można ją zaimplementować za pomocą dodatkowych narzędzi i konfiguracji, takich jak Ingress, Service lub narzędzia do zarządzania ruchem.

5. **A/B Testing**:
   - Jest to strategia podobna do Canary Deployment, ale z większym naciskiem na testowanie różnych wariantów aplikacji w celu określenia, który z nich działa lepiej.
   - Wymaga zaawansowanego zarządzania ruchem i monitorowania wyników, aby porównać różne wersje aplikacji.

Każda z tych strategii ma swoje zalety i wady, a wybór odpowiedniej strategii zależy od specyfiki aplikacji, wymagań biznesowych oraz tolerancji na przestoje.

### LivenessProbe i ReadinessProbe

W Kubernetes, LivenessProbe i ReadinessProbe to mechanizmy, które pozwalają na monitorowanie stanu aplikacji uruchomionych w podach.

1. **LivenessProbe**:
   - Służy do sprawdzania, czy aplikacja działająca w podzie jest w stanie żywym (czyli czy działa poprawnie).
   - Jeśli LivenessProbe wykryje, że aplikacja nie działa poprawnie, Kubernetes automatycznie zrestartuje pod, aby spróbować przywrócić aplikację do stanu operacyjnego.
   - Przykład konfiguracji LivenessProbe:
     ```yaml
     livenessProbe:
       httpGet:
         path: /healthz
         port: 8080
       initialDelaySeconds: 3
       periodSeconds: 3
     ```

2. **ReadinessProbe**:
   - Służy do sprawdzania, czy aplikacja działająca w podzie jest gotowa do obsługi ruchu sieciowego.
   - Jeśli ReadinessProbe wykryje, że aplikacja nie jest gotowa, pod zostanie oznaczony jako "niedostępny" i nie będzie obsługiwał ruchu sieciowego do momentu, aż aplikacja będzie gotowa.
   - Przykład konfiguracji ReadinessProbe:
     ```yaml
     readinessProbe:
       httpGet:
         path: /ready
         port: 8080
       initialDelaySeconds: 3
       periodSeconds: 3
     ```



## Readiness Probe vs Liveness Probe - Tabele Porównawcze

### Tabela 1: Podstawowe Różnice

| Cecha | Readiness Probe | Liveness Probe |
|-------|-----------------|----------------|
| **Pytanie** | Czy jestem gotowy przyjmować ruch? | Czy jestem żywy i działam poprawnie? |
| **Gdy FAIL** | Pod **nie dostaje ruchu** (usunięty z Service) | Pod jest **restartowany** przez Kubernetes |
| **Status poda** | Pod działa, ale jest oznaczony jako NotReady | Pod jest killowany i tworzony na nowo |
| **Kiedy sprawdza** | Od razu po `initialDelaySeconds` | Od razu po `initialDelaySeconds` |
| **Częstotliwość** | Co `periodSeconds` (np. co 5s) | Co `periodSeconds` (np. co 10s) |
| **Wpływ na Rolling Update** | ✅ **Blokuje** deployment jeśli FAIL | ❌ **Nie blokuje** - pody się restartują |
| **Ochrona przed złym wdrożeniem** | ✅ **TAK** - zatrzymuje rollout | ❌ **NIE** - pozwala podom wystartować |
| **Wpływ na użytkowników** | Zero błędów - ruch idzie do zdrowych podów | Możliwe błędy podczas oczekiwania na restart |
| **Można wyłączyć po starcie** | ✅ TAK - pod może stać się NotReady | ✅ TAK - wymusza restart |
| **Typowy use case** | Aplikacja startuje, ładuje cache, czeka na DB | Wykrywanie deadlocków, wycieków pamięci |

### Tabela 2: Scenariusze Deployment (4 repliki)

| Scenariusz | Bez Readiness (tylko Liveness) | Z Readiness + Liveness |
|------------|--------------------------------|------------------------|
| **Nowa wersja aplikacji ma błąd 500** | ❌ Nowe pody dostają ruch przez 30s (initialDelay), użytkownicy dostają błędy, potem CrashLoopBackOff | ✅ Nowe pody NIE dostają ruchu, rollout zatrzymany, stare pody działają |
| **Nowa wersja ma błąd startowy** | ❌ Pod wystartuje, dostanie ruch, będzie sypać błędami, restart po 30s | ✅ Pod wystartuje, NIE dostanie ruchu, rollout zatrzymany |
| **Aplikacja zawiesza się po 5 minutach** | ✅ Liveness wykryje po 3x fail i zrestartuje | ✅ Readiness+Liveness: usunięty z Service + restart |
| **Aplikacja potrzebuje 60s na start (cache)** | ❌ Dostanie ruch za wcześnie (jeśli initialDelay < 60s) | ✅ Readiness czeka aż aplikacja potwierdzi gotowość |
| **Deployment nowej wersji** | ❌ Rolling update **kontynuowany** mimo błędów | ✅ Rolling update **zatrzymany** po pierwszym złym podzie |
| **Stan klastra po złym deploymencie** | Część podów w CrashLoopBackOff, część starych działa | Wszystkie stare pody działają, nowe pody czekają |

### Tabela 3: Timeline Złego Deploymentu

| Czas | Tylko Liveness | Readiness + Liveness |
|------|----------------|----------------------|
| **T=0s** | Nowy pod #5 startuje | Nowy pod #5 startuje |
| **T=1s** | ✅ Pod "Ready" (brak Readiness) | ⏳ Czeka na pierwszą Readiness probe |
| **T=1s** | ❌ Pod dodany do Service | ⏳ Pod NIE w Service |
| **T=1-30s** | 💥 **Users dostają 500 errors!** | ✅ Ruch idzie do starych podów |
| **T=5s** | - | ❌ Readiness: FAIL #1 |
| **T=10s** | - | ❌ Readiness: FAIL #2 |
| **T=15s** | - | ❌ Readiness: FAIL #3 → Pod NotReady |
| **T=30s** | ❌ Liveness: FAIL #1 | ❌ Liveness: FAIL #1 |
| **T=40s** | ❌ Liveness: FAIL #2 | ❌ Liveness: FAIL #2 |
| **T=50s** | ❌ Liveness: FAIL #3 → **RESTART** | ❌ Liveness: FAIL #3 → **RESTART** |
| **T=51s** | ✅ Po restarcie znowu "Ready" | ⏳ Po restarcie czeka na Readiness |
| **T=51-80s** | 💥 **Users znowu dostają błędy!** | ✅ Ruch dalej do starych podów |
| **T=80s+** | 🔁 CrashLoopBackOff (z opóźnieniem) | 🔁 CrashLoopBackOff (ale bez wpływu na users) |
| **Stan końcowy** | ⚠️ Deployment częściowo failed, users mieli downtime | ✅ Deployment zatrzymany, zero downtime |

### Tabela 4: Konfiguracja - Best Practices

| Parametr | Readiness Probe | Liveness Probe | Uzasadnienie |
|----------|-----------------|----------------|---------------|
| **initialDelaySeconds** | 5-10s | 30-60s | Readiness sprawdza wcześnie; Liveness daje czas na start |
| **periodSeconds** | 5s | 10s | Readiness częściej (szybka reakcja na problemy) |
| **timeoutSeconds** | 3s | 5s | Readiness szybsza; Liveness może czekać dłużej |
| **successThreshold** | 1 | 1 | Pojedyncze potwierdzenie wystarczy |
| **failureThreshold** | 3 | 3 | 3 nieudane próby = problem (15s dla Readiness, 30s dla Liveness) |
| **Endpoint** | `/ready` lub `/health/ready` | `/health` lub `/healthz` | Osobne endpointy dla różnych sprawdzeń |

### Tabela 5: Rodzaje Probe

| Typ | Przykład | Kiedy używać |
|-----|----------|--------------|
| **httpGet** | `path: /ready`<br>`port: 8080` | ✅ REST API, web aplikacje (NAJCZĘŚCIEJ) |
| **tcpSocket** | `port: 3306` | ✅ Bazy danych, TCP services (MySQL, Redis) |
| **exec** | `command: ["cat", "/tmp/ready"]` | ✅ Niestandardowe sprawdzenia, legacy apps |
| **grpc** | `port: 9090`<br>`service: myservice` | ✅ gRPC services (K8s 1.24+) |

### Tabela 6: Statusy Poda

| Status | Readiness = PASS | Readiness = FAIL | Liveness = FAIL |
|--------|------------------|------------------|-----------------|
| **Pod Status** | Running | Running | Running → Restart |
| **Ready Condition** | True (1/1) | False (0/1) | - |
| **W Service** | ✅ TAK | ❌ NIE | ✅ TAK (do momentu restartu) |
| **Dostaje ruch** | ✅ TAK | ❌ NIE | ✅ TAK (do momentu restartu) |
| **kubectl get pods** | `myapp-xxx 1/1 Running` | `myapp-xxx 0/1 Running` | `myapp-xxx 0/1 CrashLoopBackOff` |
| **Rollout status** | Progressing | Stuck/Failed | Progressing (ale pody restartują) |

### Tabela 7: Co sprawdzać w każdej probe?

| Sprawdzenie | Readiness Probe | Liveness Probe |
|-------------|-----------------|----------------|
| **Podstawowe API działa** | ✅ TAK | ✅ TAK |
| **Połączenie z bazą danych** | ✅ TAK | ❌ NIE* |
| **Zależności zewnętrzne (API, cache)** | ✅ TAK | ❌ NIE* |
| **Pamięć dostępna** | ⚠️ Opcjonalnie | ✅ TAK |
| **Deadlock detection** | ❌ NIE | ✅ TAK |
| **Cache załadowany** | ✅ TAK | ❌ NIE |
| **Credentials ważne** | ✅ TAK | ⚠️ Opcjonalnie |

\* **Uwaga:** Liveness NIE powinien sprawdzać zależności zewnętrznych, bo jeśli DB padnie, wszystkie pody się zrestartują (co nie pomoże).

### Tabela 8: Błędy i Konsekwencje

| Błąd konfiguracji | Konsekwencja | Jak naprawić |
|-------------------|--------------|--------------|
| Brak Readiness Probe | Złe pody dostają ruch podczas deploymentu | Dodaj Readiness: httpGet /ready |
| Liveness = Readiness (ten sam endpoint) | Podczas przeciążenia pody się restartują | Użyj osobnych endpointów |
| Za krótki initialDelaySeconds | Pody failują przed startem aplikacji | Zwiększ do czasu startu +10s |
| Za długi initialDelaySeconds | Wolny rollout, opóźnione wykrycie problemów | Zmniejsz, użyj startupProbe |
| Zbyt agresywny failureThreshold=1 | Fałszywe alarmy, niepotrzebne restarty | Ustaw na 3 (lub więcej) |
| Liveness sprawdza DB | Jak DB padnie, wszystkie pody się restartują | Liveness = tylko stan aplikacji |
| Brak timeout | Pody wiszą w nieskończoność | Ustaw timeoutSeconds: 3-5s |

### Tabela 9: Komendy diagnostyczne

| Co sprawdzić | Komenda | Co pokazuje |
|--------------|---------|-------------|
| Status podów | `kubectl get pods` | Ready (1/1) vs NotReady (0/1) |
| Szczegóły probe | `kubectl describe pod <name>` | Historia Readiness/Liveness events |
| Dlaczego NotReady | `kubectl describe pod <name> \| grep -A 10 Conditions` | Readiness failed reason |
| Logi aplikacji | `kubectl logs <pod>` | Błędy aplikacji |
| Rollout status | `kubectl rollout status deployment/<name>` | Czy deployment progresuje |
| Events w czasie | `kubectl get events --sort-by=.metadata.creationTimestamp` | Timeline co się działo |
| Probes config | `kubectl get pod <name> -o yaml \| grep -A 15 Probe` | Aktualna konfiguracja probe |