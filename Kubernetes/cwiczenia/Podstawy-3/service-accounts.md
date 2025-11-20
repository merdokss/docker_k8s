# Kubernetes - Ćwiczenia: Service Accounts

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć Service Accounts w Kubernetes. Service Account to tożsamość używana przez Pody do komunikacji z API Kubernetes i innymi usługami.

**Co to jest Service Account?** Service Account to tożsamość używana przez Pody do komunikacji z API Kubernetes i innymi usługami. Każdy Pod ma przypisany Service Account (domyślnie `default`).

## Przygotowanie środowiska

```bash
# Utwórz namespace (jeśli jeszcze nie istnieje)
kubectl create namespace cwiczenia
```

---

## Ćwiczenie 2.1: Podstawowy Service Account

**Zadanie:** Utwórz Service Account `my-service-account` w namespace `cwiczenia`. Następnie utwórz Pod `nginx-sa`, który używa tego Service Account i wyświetla informacje o tokenie.

**Wskazówki:**
- Service Account można utworzyć przez `kubectl create serviceaccount` lub YAML
- W spec Poda określ `serviceAccountName`
- Token Service Account jest montowany w `/var/run/secrets/kubernetes.io/serviceaccount/token`

**Cel:** Zrozumienie podstawowej konfiguracji Service Account i jak Pod używa SA.

**Weryfikacja:**
```bash
# Sprawdź Service Account
kubectl get sa my-service-account -n cwiczenia

# Sprawdź Pod
kubectl get pod nginx-sa -n cwiczenia

# Wejdź do Poda i sprawdź token
kubectl exec -it nginx-sa -n cwiczenia -- cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Sprawdź nazwę Service Account wewnątrz Poda
kubectl exec -it nginx-sa -n cwiczenia -- cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
```

---

## Ćwiczenie 2.2: Service Account z automatycznym montowaniem tokenu

**Zadanie:** Utwórz Service Account `app-sa` w namespace `cwiczenia`. Utwórz Deployment `app-deploy` z 2 replikami (obraz `nginx:latest`), który używa tego Service Account i ma wyłączone automatyczne montowanie tokenu (`automountServiceAccountToken: false`).

**Wskazówki:**
- Domyślnie każdy Pod ma automatycznie montowany token Service Account
- Możesz wyłączyć to używając `automountServiceAccountToken: false`
- Można ustawić na poziomie Service Account lub Poda

**Cel:** Zrozumienie kontroli montowania tokenów Service Account w Podach.

**Weryfikacja:**
```bash
# Sprawdź Deployment
kubectl get deployment app-deploy -n cwiczenia

# Sprawdź Service Account używany przez Pody
kubectl get pod -n cwiczenia -l app=app -o jsonpath='{.items[0].spec.serviceAccountName}'

# Sprawdź czy token jest zmontowany (nie powinien być)
kubectl exec -it <nazwa-poda> -n cwiczenia -- ls /var/run/secrets/kubernetes.io/serviceaccount/ || echo "Katalog nie istnieje - token nie jest montowany"
```

---

## Ćwiczenie 2.3: Service Account z sekretami obrazów

**Zadanie:** Utwórz Service Account `image-puller` w namespace `cwiczenia`, który używa sekretu `registry-secret` do pobierania obrazów z prywatnego rejestru. Utwórz Pod `private-image-pod`, który używa tego Service Account i obrazu z prywatnego rejestru (użyj obrazu publicznego, jeśli nie masz prywatnego rejestru).

**Wskazówki:**
- Service Account może mieć listę `imagePullSecrets`
- Sekret musi być typu `kubernetes.io/dockerconfigjson` lub `kubernetes.io/dockercfg`
- **Najpierw utwórz sekret** (jeśli nie masz prywatnego rejestru, możesz użyć publicznego rejestru dla testów):
  ```bash
  kubectl create secret docker-registry registry-secret \
    --docker-server=<registry> \
    --docker-username=<user> \
    --docker-password=<pass> \
    -n cwiczenia
  ```
- Następnie utwórz Service Account z `imagePullSecrets`

**Cel:** Zrozumienie używania Service Account z prywatnymi rejestrami obrazów.

**Weryfikacja:**
```bash
# Sprawdź Service Account (powinien mieć imagePullSecrets)
kubectl get sa image-puller -n cwiczenia -o yaml

# Sprawdź Pod (powinien używać Service Account)
kubectl get pod private-image-pod -n cwiczenia -o yaml | grep serviceAccountName

# Sprawdź czy Pod używa imagePullSecret z Service Account
kubectl describe pod private-image-pod -n cwiczenia | grep ImagePullSecrets
```

---

## Podsumowanie

Po wykonaniu ćwiczeń z Service Accounts powinieneś:
- ✅ Rozumieć podstawową konfigurację Service Account
- ✅ Umieć kontrolować montowanie tokenów Service Account
- ✅ Umieć używać Service Account z prywatnymi rejestrami obrazów

## Przydatne komendy

```bash
# Service Accounts
kubectl get sa -n <namespace>
kubectl describe sa <name> -n <namespace>
kubectl create serviceaccount <name> -n <namespace>

# Sprawdzanie tokenów w Podach
kubectl exec -it <pod-name> -n <namespace> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

