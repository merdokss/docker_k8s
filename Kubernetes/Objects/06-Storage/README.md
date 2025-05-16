## PersistentVolume (PV), PersistentVolumeClaim (PVC) i StorageClass w Kubernetes

PersistentVolume (PV), PersistentVolumeClaim (PVC) i StorageClass to kluczowe obiekty w Kubernetes, które umożliwiają dynamiczne zarządzanie trwałym przechowywaniem danych dla aplikacji kontenerowych.

### PersistentVolume (PV)

PersistentVolume (PV) to fragment pamięci masowej w klastrze, który został zaalokowany przez administratora lub dynamicznie za pomocą StorageClass. Jest to zasób w klastrze, tak jak węzeł jest zasobem klastra. PV to wtyczki woluminów, takie jak Volumes, ale mają cykl życia niezależny od dowolnego indywidualnego poda, który używa PV. Ten obiekt API przechwytuje szczegóły implementacji pamięci masowej, czy to NFS, iSCSI, czy specyficzny dla dostawcy chmury system pamięci masowej.

**Kluczowe cechy PV:**

*   **Pojemność (Capacity):** Określa rozmiar dostępnej pamięci.
*   **Tryby dostępu (Access Modes):** Definiują, jak wolumin może być montowany przez węzły (np. `ReadWriteOnce`, `ReadOnlyMany`, `ReadWriteMany`).
*   **Polityka odzyskiwania (Reclaim Policy):** Określa, co dzieje się z PV po zwolnieniu go przez PVC (`Retain`, `Delete`, `Recycle`).
*   **Klasa przechowywania (Storage Class):** Opcjonalnie, PV może należeć do określonej klasy przechowywania, co pozwala na dynamiczne przydzielanie.

Przykład definicji PersistentVolume:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: moj-pv
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data" # Ścieżka na węźle - używane głównie w celach deweloperskich/testowych
```

### PersistentVolumeClaim (PVC)

PersistentVolumeClaim (PVC) to żądanie przechowywania danych przez użytkownika. Jest podobne do poda. Pody zużywają zasoby węzła, a PVC zużywają zasoby PV. Pody mogą żądać określonych poziomów zasobów (CPU i pamięć). Podobnie, PVC mogą żądać określonego rozmiaru i trybów dostępu.

Gdy użytkownik tworzy PVC, Kubernetes szuka PV, który spełnia kryteria zdefiniowane w PVC (rozmiar, tryby dostępu, opcjonalnie StorageClass). Jeśli pasujący PV zostanie znaleziony (lub dynamicznie utworzony przez StorageClass), PVC zostaje powiązane (bound) z tym PV.

Przykład definicji PersistentVolumeClaim:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: moja-pvc
spec:
  storageClassName: manual # Musi pasować do storageClassName w PV, jeśli PV jest pre-provisioned
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

### StorageClass

StorageClass dostarcza administratorom sposób na opisanie "klas" pamięci masowej, które oferują. Różne klasy mogą mapować się na różne poziomy jakości usług (QoS), polityki tworzenia kopii zapasowych lub dowolne inne zasady określone przez administratora klastra. Sam Kubernetes nie jest świadomy, co reprezentują te klasy. Ta koncepcja jest czasami nazywana "profilami" w innych systemach pamięci masowej.

Gdy PVC żąda określonej StorageClass, Kubernetes używa odpowiedniego dostawcy (provisioner) zdefiniowanego w tej StorageClass do dynamicznego utworzenia PV. Jeśli StorageClass nie zostanie określona w PVC, może zostać użyta domyślna StorageClass klastra (jeśli jest skonfigurowana).

**Kluczowe cechy StorageClass:**

*   **Dostawca (Provisioner):** Określa, jaki plugin woluminu jest używany do tworzenia PV (np. `kubernetes.io/aws-ebs`, `kubernetes.io/gce-pd`, `kubernetes.io/azure-disk`).
*   **Parametry (Parameters):** Specyficzne dla dostawcy parametry (np. typ dysku, strefa).
*   **Polityka odzyskiwania (Reclaim Policy):** Domyślna polityka odzyskiwania dla PV dynamicznie utworzonych przez tę klasę.
*   **Tryb wiązania woluminu (Volume Binding Mode):**
    *   `Immediate`: Dynamiczne tworzenie i wiązanie woluminu następuje natychmiast po utworzeniu PVC.
    *   `WaitForFirstConsumer`: Wiązanie i tworzenie woluminu jest opóźnione do momentu, gdy pod używający PVC zostanie zaplanowany. Jest to przydatne dla woluminów, które są ograniczone topologią węzła.

Przykład definicji StorageClass (dla lokalnego developmentu, bez dynamicznego provisioningu):

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/no-provisioner # Wskazuje, że PV będą tworzone ręcznie
volumeBindingMode: WaitForFirstConsumer
```

Dla dostawców chmurowych, `provisioner` będzie inny, np.:
*   AWS: `kubernetes.io/aws-ebs`
*   GCP: `kubernetes.io/gce-pd`
*   Azure: `kubernetes.io/azure-disk`

### Działający Przykład

Poniższy przykład demonstruje użycie `StorageClass` (do dynamicznego provisioningu, jeśli klaster to wspiera, lub ręcznego, jeśli użyjemy `no-provisioner`), `PersistentVolumeClaim` oraz `Pod`, który montuje ten wolumin.

**Krok 1: Definicja StorageClass (`sc.yaml`)**

Jeśli twój klaster wspiera dynamiczne tworzenie woluminów (np. w chmurze), możesz użyć odpowiedniego `provisioner`. Dla celów demonstracyjnych, jeśli używasz Minikube lub podobnego lokalnego środowiska, możesz zacząć od `standard` StorageClass, która często jest prekonfigurowana, lub stworzyć własną z `kubernetes.io/no-provisioner` (co będzie wymagało ręcznego stworzenia PV) lub użyć wbudowanego provisionera Minikube (np. `k8s.io/minikube-hostpath`).

Załóżmy, że chcemy użyć standardowej, często domyślnie dostępnej klasy lub stworzyć prostą dla celów lokalnych (jeśli nie ma domyślnej).

```yaml
# sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard-local # Możesz nazwać ją inaczej
provisioner: k8s.io/minikube-hostpath # Przykład dla Minikube; zmień na odpowiedni dla Twojego klastra
# Dla ręcznego tworzenia PV, użyłbyś:
# provisioner: kubernetes.io/no-provisioner
# volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete # Co zrobić z PV po usunięciu PVC
allowVolumeExpansion: true # Czy wolno rozszerzać wolumin
```

**Uwaga:** Jeśli używasz `kubernetes.io/no-provisioner`, musisz ręcznie stworzyć `PersistentVolume`, który pasuje do żądania `PersistentVolumeClaim` i ma `storageClassName: standard-local`.

**Krok 2: Definicja PersistentVolumeClaim (`pvc.yaml`)**

PVC będzie żądać pamięci od `StorageClass` zdefiniowanej powyżej.

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: moj-dynamiczny-pvc
spec:
  storageClassName: standard-local # Musi pasować do nazwy StorageClass
  accessModes:
    - ReadWriteOnce # Ten tryb dostępu musi być wspierany przez PV/StorageClass
  resources:
    requests:
      storage: 1Gi # Żądany rozmiar pamięci
```

**Krok 3: Definicja Poda używającego PVC (`pod.yaml`)**

Ten pod będzie montował wolumin udostępniony przez `moj-dynamiczny-pvc`.

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: moj-pod-z-woluminem
spec:
  containers:
  - name: moj-kontener
    image: nginx
    ports:
    - containerPort: 80
      name: "http-server"
    volumeMounts:
    - mountPath: "/usr/share/nginx/html" # Ścieżka montowania wewnątrz kontenera
      name: moj-pd # Musi pasować do nazwy woluminu zdefiniowanej poniżej
  volumes:
  - name: moj-pd
    persistentVolumeClaim:
      claimName: moj-dynamiczny-pvc # Nazwa PVC, którego chcemy użyć
```

**Krok 4: Aplikowanie konfiguracji w klastrze**

Aby uruchomić powyższy przykład, zapisz każdą definicję YAML w osobnym pliku (`sc.yaml`, `pvc.yaml`, `pod.yaml`) w tym samym katalogu, a następnie zastosuj je używając `kubectl`:

```bash
# Jeśli stworzyłeś StorageClass:
kubectl apply -f sc.yaml

# Następnie PVC:
kubectl apply -f pvc.yaml

# Na koniec Pod:
kubectl apply -f pod.yaml
```

**Sprawdzanie statusu:**

*   Sprawdź StorageClass: `kubectl get sc`
*   Sprawdź PVC i jego status (powinien być `Bound`): `kubectl get pvc moj-dynamiczny-pvc`
*   Sprawdź PV (jeśli jest dynamicznie tworzony, jego nazwa będzie inna niż PVC): `kubectl get pv`
*   Sprawdź status Poda: `kubectl get pod moj-pod-z-woluminem`
*   Wejdź do kontenera i sprawdź zamontowany wolumin:
    ```bash
    kubectl exec -it moj-pod-z-woluminem -- /bin/bash
    # Wewnątrz kontenera:
    df -h /usr/share/nginx/html
    echo "Witaj na trwałym woluminie!" > /usr/share/nginx/html/index.html
    exit
    ```
*   Aby sprawdzić, czy dane są trwałe, usuń poda i stwórz go ponownie (lub stwórz innego poda używającego tego samego PVC). Dane w `index.html` powinny pozostać.

```bash
kubectl delete pod moj-pod-z-woluminem
# Poczekaj chwilę, aż pod zostanie usunięty
kubectl apply -f pod.yaml
kubectl exec -it moj-pod-z-woluminem -- cat /usr/share/nginx/html/index.html
# Powinieneś zobaczyć "Witaj na trwałym woluminie!"
```

**Czyszczenie:**

Aby usunąć zasoby stworzone w tym przykładzie:

```bash
kubectl delete pod moj-pod-z-woluminem
kubectl delete pvc moj-dynamiczny-pvc
# Jeśli stworzyłeś StorageClass i chcesz ją usunąć:
kubectl delete sc standard-local
# PV zostanie usunięty automatycznie, jeśli ReclaimPolicy to Delete,
# w przeciwnym razie może wymagać ręcznego usunięcia (jeśli Retain).
```
Ten przykład pokazuje podstawy działania PV, PVC i StorageClass. W rzeczywistych scenariuszach konfiguracje mogą być bardziej złożone, zależnie od wymagań aplikacji i używanego środowiska Kubernetes. 
