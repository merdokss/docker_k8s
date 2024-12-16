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

### Różnice między LivenessProbe a ReadinessProbe

- **Cel**:
  - LivenessProbe: Sprawdza, czy aplikacja działa poprawnie. Jeśli nie, pod jest restartowany.
  - ReadinessProbe: Sprawdza, czy aplikacja jest gotowa do obsługi ruchu. Jeśli nie, pod jest oznaczony jako "niedostępny" i nie obsługuje ruchu.

- **Skutki**:
  - LivenessProbe: Niepowodzenie prowadzi do restartu poda.
  - ReadinessProbe: Niepowodzenie prowadzi do oznaczenia poda jako "niedostępny" bez restartu.

- **Zastosowanie**:
  - LivenessProbe: Używana do automatycznego naprawiania aplikacji, które przestały działać poprawnie.
  - ReadinessProbe: Używana do kontrolowania, kiedy pod może obsługiwać ruch, co jest szczególnie przydatne podczas startu aplikacji lub aktualizacji.

Oba mechanizmy są kluczowe dla zapewnienia wysokiej dostępności i niezawodności aplikacji uruchomionych w Kubernetes.
