# Kind – *Kubernetes IN Docker*

Kind to lekki, w 100 % open‑source’owy sposób na uruchomienie pełnoprawnego klastra Kubernetes **w kontenerach Dockera/Podmana**, bez VM‑ek czy chmury.

---

## 🗂️ Spis treści
1. [Wymagania](#wymagania)  
2. [Instalacja](#instalacja)  
3. [Szybki start](#szybki-start)  
4. [Konfiguracja klastra](#konfiguracja-klastra)  
5. [Ładowanie lokalnych obrazów](#ładowanie‑lokalnych‑obrazów)  
6. [Usuwanie i sprzątanie](#usuwanie‑i‑sprzątanie)  
7. [Rozwiązywanie problemów](#rozwiązywanie‑problemów)  

---

## Wymagania

| Składnik | Minimalna wersja | Uwaga |
| -------- | ---------------- | ----- |
| **Docker / Podman / nerdctl** | > 20.10 (Podman 4+) | Kind startuje kontenery‑węzły |
| **Go** (tylko przy `go install`) | ≥ 1.16 | Binarka nie jest wymagana, jeśli używasz gotowych release’ów |
| **kubectl** | dowolna kompatybilna | Do pracy z klastrem |

---

## Instalacja

### 1. Binarie z releases (zalecane w CI)

```bash
# Linux AMD64
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/
```

```bash
# Windows i PowerShell
curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.27.0/kind-windows-amd64
Move-Item .\kind-windows-amd64.exe c:\some-dir-in-your-PATH\kind.exe
```

Analogicznie dla **macOS** (`kind-darwin-arm64|amd64`) i **Windows** (`kind-windows-amd64.exe`).

### 2. `go install`

```bash
go install sigs.k8s.io/kind@v0.27.0
```

### 3. Menedżer pakietów

```bash
brew install kind      # macOS
choco install kind     # Windows / Chocolatey
winget install Kubernetes.kind #Windows
```

---

## Szybki start

```bash
kind create cluster
kubectl get nodes
```

Domyślny obraz węzła to **`kindest/node:v1.32.2`** (Kubernetes 1.32.2).  
Aby wybrać inną wersję K8s, podaj `--image kindest/node:v<wersja>`.

---

## Konfiguracja klastra

Przykład wielowęzłowego klastra z mapowaniem portu 80 → 8080, etykietą `ingress-ready`, wspólnym wolumenem i lokalnym registry:

```yaml
# kind-cluster.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

nodes:
- role: control-plane
  image: kindest/node:v1.32.2      # wersja K8s
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  extraMounts:
  - hostPath: ~/lab-data
    containerPath: /mnt/data
- role: worker
- role: worker

# (opcjonalnie) lokalny registry
# registry:
#   name: kind-registry
#   host: localhost
#   hostPort: "5000"
```

```bash
kind create cluster --name szkolenie --config kind-cluster.yaml
```

Pełny opis pól znajdziesz w dokumentacji Kind → *Configuration*.

---

## Ładowanie lokalnych obrazów

```bash
docker build -t myapp:latest .
kind load docker-image myapp:latest --name szkolenie
```

Możesz też skonfigurować **local registry** w pliku klastra.

---

## Usuwanie i sprzątanie

```bash
kind get clusters                # lista klastrów
kind delete cluster --name szkolenie
kind export logs ./logs.tgz      # diagnoza logów
```

---

## Rozwiązywanie problemów

| Symptom | Przyczyna | Szybka poprawka |
|---------|-----------|----------------|
| `kind create cluster` wisi na *Waiting for control-plane* | Stary Docker Desktop lub brak wolnych zasobów | Zaktualizuj Docker, zwolnij RAM/CPU |
| Pods w stanie `ImagePullBackOff` dla lokalnych obrazów | Obraz nie załadowany do klastra | `kind load docker-image <img>` lub skonfiguruj local registry |
| Brak `LoadBalancer` | Kind nie ma wbudowanego LB | Zainstaluj MetalLB lub korzystaj z Ingress‑NGINX |
| Błędy przy `kind load ...` po aktualizacji | Używasz Kind < v0.27 z node‑image dla containerd 2 | Uaktualnij Kind do ≥ 0.27.0 |

Więcej informacji w [Kind Docs – Known Issues](https://kind.sigs.k8s.io/docs/user/known-issues/).
