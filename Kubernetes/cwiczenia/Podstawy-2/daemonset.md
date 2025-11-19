# Kubernetes - Ćwiczenia: DaemonSet

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć DaemonSet w Kubernetes. DaemonSet zapewnia, że kopia Poda działa na wszystkich (lub wybranych) nodach w klastrze.

**Co to jest DaemonSet?** DaemonSet zapewnia, że kopia Poda działa na wszystkich (lub wybranych) nodach w klastrze. Gdy dodasz nowy node do klastra, DaemonSet automatycznie utworzy na nim Pod.

## Ćwiczenie 3.1: Podstawowy DaemonSet

**Zadanie:** Utwórz DaemonSet `fluentd-logging` z obrazem `fluent/fluentd:latest` w namespace `cwiczenia`, który będzie działał na wszystkich nodach w klastrze. Etykieta: `app: logging`.

> **Uwaga:** DaemonSet automatycznie utworzy jeden Pod na każdym nodzie w klastrze (lub na nodach pasujących do selektora).

**Wskazówki:**
- Użyj `apiVersion: apps/v1` i `kind: DaemonSet`
- DaemonSet nie wymaga `spec.replicas` - automatycznie tworzy Pod na każdym nodzie
- DaemonSet jest idealny do agentów monitorowania, logowania, zbierania metryk

**Cel:** Zrozumienie koncepcji DaemonSet i jego zastosowania.

**Weryfikacja:**
```bash
# Sprawdź DaemonSet
kubectl get daemonset fluentd-logging

# Zobacz Pody (powinien być jeden Pod na każdym nodzie)
kubectl get pods -l app=logging -o wide

# Sprawdź liczbę nodów
kubectl get nodes

# Liczba Podów powinna odpowiadać liczbie nodów
# Sprawdź szczegóły
kubectl describe daemonset fluentd-logging
```

---

## Ćwiczenie 3.2: DaemonSet z selektorem nodów

**Zadanie:** Utwórz DaemonSet `node-monitor` z obrazem `nginx:latest` w namespace `cwiczenia`, który działa tylko na nodach z etykietą `monitoring=enabled`.

**Wskazówki:**
- **KROK 1:** Sprawdź dostępne nody: `kubectl get nodes`
- **KROK 2:** Oznacz wybrany node etykietą: `kubectl label nodes <node-name> monitoring=enabled`
- **KROK 3:** W `spec.template.spec.nodeSelector` określ selektor nodów:
  ```yaml
  nodeSelector:
    monitoring: enabled
  ```
- DaemonSet utworzy Pody tylko na nodach pasujących do selektora
- Możesz sprawdzić etykiety nodów: `kubectl get nodes --show-labels`

**Cel:** Zrozumienie ograniczania DaemonSet do wybranych nodów.

**Weryfikacja:**
```bash
# Zobacz dostępne nody
kubectl get nodes

# Oznacz wybrany node etykietą
kubectl label nodes <node-name> monitoring=enabled

# Sprawdź etykiety noda
kubectl get nodes --show-labels

# Utwórz DaemonSet z nodeSelector
# W spec.template.spec.nodeSelector dodaj:
# nodeSelector:
#   monitoring: enabled

# Sprawdź DaemonSet
kubectl get daemonset node-monitor

# Sprawdź Pody (powinien być tylko na oznaczonym nodzie)
kubectl get pods -l app=monitor -o wide
```

---

## Ćwiczenie 3.3: DaemonSet z toleracjami

> **⚠️ UWAGA:** W zarządzanych klastrach (AKS, EKS, GKE) zwykle nie ma nodów master z taintami dostępnych dla użytkowników. To ćwiczenie ma charakter edukacyjny.

**Zadanie:** Utwórz DaemonSet `system-daemon` z obrazem `nginx:latest` w namespace `cwiczenia`, który może działać na nodach z taintem `node-role.kubernetes.io/master:NoSchedule` (lub podobnym).

**Wskazówki:**
- **KROK 1:** Sprawdź tainty na nodach: `kubectl describe nodes | grep Taints`
- Tainty blokują planowanie Podów na nodach
- Tolerancje pozwalają Podom działać na nodach z taintami
- W `spec.template.spec.tolerations` dodaj odpowiednie tolerancje:
  ```yaml
  tolerations:
  - key: node-role.kubernetes.io/master
    operator: Exists
    effect: NoSchedule
  ```
- To jest przydatne dla systemowych DaemonSet (np. monitoring na nodach master)

**Cel:** Zrozumienie tolerancji i taintów w kontekście DaemonSet.

**Weryfikacja:**
```bash
# Sprawdź tainty na nodach
kubectl describe nodes | grep Taints

# Utwórz DaemonSet z toleracjami
# W spec.template.spec.tolerations dodaj:
# tolerations:
# - key: node-role.kubernetes.io/master
#   operator: Exists
#   effect: NoSchedule

# Sprawdź DaemonSet
kubectl get daemonset system-daemon

# Sprawdź Pody (powinny działać również na nodach z taintami)
kubectl get pods -l app=system -o wide
```

---

## Podsumowanie

Po wykonaniu ćwiczeń z DaemonSet powinieneś:
- ✅ Rozumieć zastosowanie DaemonSet dla agentów systemowych
- ✅ Umieć ograniczać DaemonSet do wybranych nodów używając nodeSelector
- ✅ Rozumieć koncepcję tolerancji i taintów w kontekście DaemonSet

## Przydatne komendy

```bash
# DaemonSet
kubectl get daemonset
kubectl get daemonset <name>
kubectl describe daemonset <name>

# Pody DaemonSet
kubectl get pods -l <label> -o wide
kubectl describe pod <pod-name>

# Nody
kubectl get nodes
kubectl get nodes --show-labels
kubectl label nodes <node-name> <key>=<value>
kubectl describe nodes | grep Taints

# Sprawdzanie rozkładu Podów
kubectl get pods -o wide | grep <daemonset-name>
```

