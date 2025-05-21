# Zadania - StatefulSet w Kubernetes

## Zadanie 1: Podstawowy StatefulSet
1. Utwórz StatefulSet o nazwie `web-app` z 3 replikami, wykorzystując obraz nginx.
2. Skonfiguruj headless service dla StatefulSet.
3. Zweryfikuj, czy wszystkie pody zostały utworzone z poprawnymi nazwami (web-app-0, web-app-1, web-app-2).

## Zadanie 2: Persistent Storage dla StatefulSet
1. Utwórz StorageClass dla StatefulSet (no-provisioner).
2. Utwórz odpowiednie PV
3. Skonfiguruj volumeClaimTemplates w StatefulSet, aby każdy pod miał własny PVC.
4. Zweryfikuj, czy PVC zostały poprawnie utworzone i przypisane do podów.

## Zadanie 3: Konfiguracja Pod Management Policy
1. Zmodyfikuj StatefulSet, aby używał `Parallel` jako Pod Management Policy.
2. Wykonaj rolling update StatefulSet.
3. Obserwuj, jak pody są aktualizowane równolegle.

## Zadanie 4: StatefulSet z Init Containers
1. Dodaj init container do StatefulSet, który będzie przygotowywał dane przed uruchomieniem głównego kontenera.
2. Skonfiguruj init container tak, aby korzystał z tego samego volume co główny kontener.
3. Zweryfikuj, czy init container poprawnie wykonuje swoje zadanie.

## Zadanie 5: StatefulSet z Readiness Probe
1. Dodaj readiness probe do kontenerów w StatefulSet.
2. Skonfiguruj probe tak, aby sprawdzała dostępność aplikacji na porcie 80.
3. Zweryfikuj, czy pody są poprawnie oznaczane jako gotowe do obsługi ruchu.

## Wymagania:
- Znajomość podstawowych konceptów Kubernetes
- Dostęp do klastra Kubernetes
- Narzędzia: kubectl

## Przydatne komendy:
```bash
kubectl get statefulset
kubectl get pods
kubectl describe statefulset <nazwa-statefulset>
kubectl get pvc
kubectl logs <nazwa-poda>
``` 