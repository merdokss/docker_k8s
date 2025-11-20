# Kubernetes - Ćwiczenia: Taints i Tolerations

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć Taints i Tolerations w Kubernetes. Taints i Tolerations pozwalają oznaczać nody, aby odrzucały Pody, które nie mają odpowiednich Tolerations.

**Co to są Taints i Tolerations?** Taints i Tolerations pozwalają oznaczać nody, aby odrzucały Pody, które nie mają odpowiednich Tolerations. To mechanizm ochrony nodów przed uruchamianiem określonych Podów.

**Koncepcja:**
- **Taint** - oznacza noda (np. "ten nod nie akceptuje Podów bez toleracji")
- **Toleration** - oznacza Poda (np. "ten Pod może być uruchomiony na nodzie z taintem")

**Efekty Taints:**
- `NoSchedule` - Pody bez toleracji nie będą planowane na tym nodzie
- `PreferNoSchedule` - preferowane, aby unikać, ale nie blokuje
- `NoExecute` - usuwa istniejące Pody bez toleracji

## Przygotowanie środowiska

```bash
# Utwórz namespace (jeśli jeszcze nie istnieje)
kubectl create namespace cwiczenia

# Sprawdź dostępne nody
kubectl get nodes

# Sprawdź tainty na nodach
kubectl describe nodes | grep -i taint
```

---

## Ćwiczenie 4.1: Podstawowy Taint i Toleration

**Zadanie:** Oznacz jeden z nodów taintem `special-node=true:NoSchedule`. Następnie spróbuj utworzyć dwa Deploymenty:
1. `nginx-normal` z 2 replikami (obraz `nginx:latest`) - bez toleracji
2. `nginx-special` z 2 replikami (obraz `nginx:latest`) - z toleracją dla `special-node=true`

**Wskazówki:**
- Najpierw sprawdź dostępne nody: `kubectl get nodes`
- Oznacz jeden z nodów taintem: `kubectl taint nodes <node-name> special-node=true:NoSchedule`
- Sprawdź czy taint został dodany: `kubectl describe node <node-name> | grep -i taint`
- `NoSchedule` - Pody bez toleracji nie będą planowane na tym nodzie
- `PreferNoSchedule` - preferowane, aby unikać, ale nie blokuje
- `NoExecute` - usuwa istniejące Pody bez toleracji

**Cel:** Zrozumienie podstawowego działania Taints i Tolerations.

**Weryfikacja:**
```bash
# Sprawdź tainty na nodach
kubectl describe nodes | grep -i taint

# Sprawdź Deployment bez toleracji (Pody powinny być w stanie Pending lub na innych nodach)
kubectl get pods -n cwiczenia -l app=nginx-normal -o wide

# Sprawdź Deployment z toleracją (Pody powinny być uruchomione na nodzie z taintem)
kubectl get pods -n cwiczenia -l app=nginx-special -o wide

# Sprawdź szczegóły Podów bez toleracji
kubectl describe pod <nazwa-poda> -n cwiczenia | grep -A 5 Events
```

---

## Ćwiczenie 4.2: Taint z efektem NoExecute

**Zadanie:** Utwórz Deployment `nginx-running` z 3 replikami (obraz `nginx:latest`) bez toleracji. Poczekaj, aż Pody się uruchomią, a następnie oznacz jeden z nodów (na którym są uruchomione Pody) taintem `maintenance=true:NoExecute` - obserwuj, co się stanie z Podami na tym nodzie.

**Wskazówki:**
- Najpierw utwórz Deployment i sprawdź na jakich nodach są uruchomione Pody: `kubectl get pods -n cwiczenia -l app=nginx-running -o wide`
- Sprawdź nazwę noda, na którym są Pody
- Oznacz ten nod taintem: `kubectl taint nodes <node-name> maintenance=true:NoExecute`
- `NoExecute` usuwa istniejące Pody bez toleracji z noda
- Pody zostaną automatycznie przeniesione na inne nody
- To przydatne do ewakuacji nodów przed konserwacją

**Cel:** Zrozumienie efektu NoExecute i automatycznej ewakuacji Podów.

**Weryfikacja:**
```bash
# Sprawdź Deployment (powinien mieć 3 uruchomione Pody)
kubectl get deployment nginx-running -n cwiczenia

# Sprawdź Pody przed dodaniem tainta
kubectl get pods -n cwiczenia -l app=nginx-running -o wide

# Dodaj taint z NoExecute
kubectl taint nodes <node-name> maintenance=true:NoExecute

# Obserwuj Pody (powinny być usunięte z noda z taintem i przeniesione na inne)
kubectl get pods -n cwiczenia -l app=nginx-running -o wide -w
```

---

## Ćwiczenie 4.3: Toleration z wartościami

**Zadanie:** Oznacz jeden z nodów taintem `node-type=gpu:NoSchedule` z wartością. Utwórz Deployment `gpu-app` z 2 replikami (obraz `nginx:latest`), który ma tolerację dopasowaną do tego tainta (również z wartością).

**Wskazówki:**
- Najpierw sprawdź dostępne nody: `kubectl get nodes`
- Oznacz noda taintem z wartością: `kubectl taint nodes <node-name> node-type=gpu:NoSchedule`
- Sprawdź taint: `kubectl describe node <node-name> | grep -i taint`
- W toleracji użyj `operator: Equal` i tej samej wartości `gpu`
- Toleration musi pasować do `key`, `value` i `effect`
- `operator: Equal` - dokładne dopasowanie wartości
- `operator: Exists` - akceptuje dowolną wartość dla klucza

**Cel:** Zrozumienie dopasowywania Tolerations do Taints z wartościami.

**Weryfikacja:**
```bash
# Sprawdź tainty na nodach
kubectl describe nodes <node-name> | grep -i taint

# Sprawdź Deployment (Pody powinny być uruchomione na nodzie z taintem)
kubectl get pods -n cwiczenia -l app=gpu-app -o wide

# Sprawdź tolerację w Podzie
kubectl get pod <nazwa-poda> -n cwiczenia -o yaml | grep -A 5 toleration
```

---

## Podsumowanie

Po wykonaniu ćwiczeń z Taints i Tolerations powinieneś:
- ✅ Rozumieć różne efekty Taints (NoSchedule, PreferNoSchedule, NoExecute)
- ✅ Umieć tworzyć Tolerations dopasowane do Taints
- ✅ Rozumieć zastosowanie Taints do ewakuacji nodów przed konserwacją

## Przydatne komendy

```bash
# Sprawdzanie i zarządzanie taintami
kubectl describe nodes | grep -i taint
kubectl taint nodes <node-name> <key>=<value>:<effect>
kubectl taint nodes <node-name> <key>:<effect>-  # Usuń taint

# Sprawdzanie Podów i toleracji
kubectl get pods -o wide -n <namespace>
kubectl get pod <pod-name> -n <namespace> -o yaml | grep -A 5 toleration
```

## Czyszczenie

Po zakończeniu ćwiczeń usuń tainty z nodów:

```bash
# Usuń tainty (zamień <node-name> na rzeczywistą nazwę noda)
kubectl taint nodes <node-name> special-node:NoSchedule-
kubectl taint nodes <node-name> maintenance:NoExecute-
kubectl taint nodes <node-name> node-type:NoSchedule-
```

