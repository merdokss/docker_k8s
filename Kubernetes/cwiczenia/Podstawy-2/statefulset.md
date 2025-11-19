# Kubernetes - Ćwiczenia: StatefulSet

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć StatefulSet w Kubernetes. StatefulSet zarządza wdrożeniem i skalowaniem zestawu Podów oraz zapewnia gwarancje dotyczące kolejności i unikalności tych Podów.

**Co to jest StatefulSet?** StatefulSet zarządza wdrożeniem i skalowaniem zestawu Podów oraz zapewnia gwarancje dotyczące kolejności i unikalności tych Podów. W przeciwieństwie do Deployment, StatefulSet utrzymuje trwałą tożsamość dla każdego Poda.

## Ćwiczenie 2.1: Podstawowy StatefulSet

**Zadanie:** Utwórz StatefulSet `web-sts` z 3 replikami używając obrazu `nginx:latest` w namespace `cwiczenia`. Każdy Pod powinien mieć etykietę `app: web`.

> **Uwaga:** StatefulSet wymaga Headless Service. Utwórz najpierw Service, a potem StatefulSet.

**Wskazówki:**
- Użyj `apiVersion: apps/v1` i `kind: StatefulSet`
- StatefulSet wymaga `spec.serviceName` - nazwy Headless Service
- Pody będą nazywane: `web-sts-0`, `web-sts-1`, `web-sts-2`
- Utwórz Headless Service (ClusterIP z `clusterIP: None`)

**Cel:** Zrozumienie podstawowej struktury StatefulSet i różnicy względem Deployment.

**Weryfikacja:**
```bash
# Utwórz najpierw Headless Service
# apiVersion: v1
# kind: Service
# metadata:
#   name: web-sts
# spec:
#   clusterIP: None
#   selector:
#     app: web
#   ports:
#   - port: 80

# Sprawdź StatefulSet
kubectl get statefulset web-sts

# Zobacz Pody (zauważ uporządkowane nazwy)
kubectl get pods -l app=web

# Pody są tworzone sekwencyjnie (0, potem 1, potem 2)
# Sprawdź DNS - każdy Pod ma stabilną nazwę DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup web-sts-0.web-sts
```

---

## Ćwiczenie 2.2: StatefulSet z PersistentVolumeClaim

**Zadanie:** Utwórz StatefulSet `db-sts` z 2 replikami (obraz `nginx:latest`) w namespace `cwiczenia`, który używa PersistentVolumeClaim do przechowywania danych. Każdy Pod powinien mieć własny wolumen.

> **Uwaga:** StatefulSet automatycznie utworzy PVC dla każdego Poda używając `volumeClaimTemplates`.

**Wskazówki:**
- W `spec.volumeClaimTemplates` zdefiniuj szablon PVC
- Każdy Pod otrzyma własny PVC: `db-sts-0-pvc`, `db-sts-1-pvc`
- PVC są tworzone automatycznie dla każdego Poda
- Zamontuj wolumen w kontenerze używając `volumeMounts`

**Cel:** Zrozumienie trwałego przechowywania danych w StatefulSet.

**Weryfikacja:**
```bash
# Sprawdź StatefulSet
kubectl get statefulset db-sts

# Zobacz utworzone PVC (powinny być 2)
kubectl get pvc

# Sprawdź Pody i ich wolumeny
kubectl describe pod db-sts-0
kubectl describe pod db-sts-1

# Sprawdź, że każdy Pod ma własny wolumen
kubectl exec db-sts-0 -- df -h
kubectl exec db-sts-1 -- df -h
```

---

## Ćwiczenie 2.3: Skalowanie StatefulSet

**Zadanie:** Utwórz StatefulSet `app-sts` z 2 replikami (obraz `nginx:latest`) w namespace `cwiczenia`, a następnie:
1. Zwiększ liczbę replik do 4
2. Zmniejsz liczbę replik do 1
3. Obserwuj kolejność tworzenia i usuwania Podów

**Wskazówki:**
- StatefulSet skaluje się sekwencyjnie (jeden Pod na raz)
- Podczas skalowania w górę: tworzy Pody w kolejności (0, 1, 2, 3)
- Podczas skalowania w dół: usuwa Pody w odwrotnej kolejności (3, 2, 1, 0)
- Użyj `kubectl scale` lub edytuj `spec.replicas`

**Cel:** Zrozumienie sekwencyjnego skalowania StatefulSet.

**Weryfikacja:**
```bash
# Zwiększ do 4 replik
kubectl scale statefulset app-sts --replicas=4

# Obserwuj tworzenie Podów (w osobnym terminalu)
kubectl get pods -l app=app -w

# Sprawdź status
kubectl get statefulset app-sts

# Zmniejsz do 1 repliki
kubectl scale statefulset app-sts --replicas=1

# Obserwuj usuwanie Podów (zauważ odwrotną kolejność)
kubectl get pods -l app=app -w
```

---

## Podsumowanie

Po wykonaniu ćwiczeń ze StatefulSet powinieneś:
- ✅ Rozumieć różnicę między StatefulSet a Deployment
- ✅ Umieć tworzyć StatefulSet z Headless Service
- ✅ Rozumieć sekwencyjne skalowanie StatefulSet
- ✅ Umieć konfigurować trwałe przechowywanie danych w StatefulSet

## Przydatne komendy

```bash
# StatefulSet
kubectl get statefulset
kubectl get statefulset <name>
kubectl describe statefulset <name>
kubectl scale statefulset <name> --replicas=<number>

# Pody StatefulSet
kubectl get pods -l app=<label>
kubectl describe pod <pod-name>

# Headless Service
kubectl get svc
kubectl describe svc <service-name>

# DNS i komunikacja
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup <pod-name>.<service-name>
```

