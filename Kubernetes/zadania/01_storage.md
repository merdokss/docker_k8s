# Zadania - Storage w Kubernetes

## Zadanie 1: PersistentVolume i PersistentVolumeClaim
1. Utwórz PersistentVolume o nazwie `pv-demo` o pojemności 1Gi, wykorzystując lokalny katalog `/mnt/data` jako miejsce przechowywania danych.
2. Utwórz PersistentVolumeClaim o nazwie `pvc-demo`, który będzie żądał 500Mi przestrzeni.
3. Zweryfikuj, czy PVC został poprawnie powiązany z PV.

## Zadanie 2: StorageClass
1. Utwórz StorageClass o nazwie `fast-storage` wykorzystując provisioner `kubernetes.io/no-provisioner`.
2. Zmodyfikuj PVC z poprzedniego zadania, aby korzystał z nowo utworzonej StorageClass.
3. Sprawdź, czy PV został automatycznie utworzony dla PVC.

## Zadanie 3: Dynamiczne Provisioning
1. Skonfiguruj StorageClass wykorzystując dynamiczny provisioning (np. Azure Disk).
2. Utwórz PVC, który będzie korzystał z dynamicznego provisioning.
3. Zweryfikuj, czy zasób storage został automatycznie utworzony w chmurze.

## Zadanie 4: Volume Mounts
1. Utwórz deployment, który będzie korzystał z PVC.
2. Skonfiguruj volume mounts w kontenerze, aby zamontować PVC w ścieżce `/data`.
3. Zweryfikuj, czy dane są poprawnie zapisywane i odczytywane z zamontowanego volume.


## Wymagania:
- Znajomość podstawowych konceptów Kubernetes
- Dostęp do klastra Kubernetes
- Narzędzia: kubectl, helm (opcjonalnie)

## Przydatne komendy:
```bash
kubectl get pv
kubectl get pvc
kubectl get sc
kubectl describe pv <nazwa-pv>
kubectl describe pvc <nazwa-pvc>
``` 