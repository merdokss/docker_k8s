# Uwierzytelnianie i Autoryzacja w Azure Kubernetes Service (AKS)

## Przegląd trzech modeli

W AKS masz do wyboru **3 główne modele** uwierzytelniania i autoryzacji. Każdy ma swoje zalety i jest odpowiedni dla różnych scenariuszy.

---

## Model 1: Local Accounts (Konta lokalne Kubernetes)

### Opis
Tradycyjny model Kubernetes używający certyfikatów klienckich i Service Accounts.

### Uwierzytelnianie (Authentication)
- **Certyfikaty X.509** wbudowane w plik `kubeconfig`
- **Service Account Tokens** dla aplikacji w klastrze
- Brak integracji z zewnętrznymi systemami tożsamości

### Autoryzacja (Authorization)
- **Kubernetes RBAC** (Role-Based Access Control)
- Obiekty: `Role`, `ClusterRole`, `RoleBinding`, `ClusterRoleBinding`
- Weryfikacja odbywa się w **Kubernetes API Server**

### Przepływ requestu
```
kubectl get pods
    ↓
kubeconfig (certyfikat) → Kubernetes API Server
    ↓
Kubernetes RBAC sprawdza Role/RoleBinding
    ↓
✅/❌ Decyzja
```

### Przykład konfiguracji

```yaml
# ClusterRole - definicja uprawnień
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

---
# ClusterRoleBinding - przypisanie do użytkownika
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods-global
subjects:
- kind: User
  name: "jan-kowalski"  # Nazwa z certyfikatu
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Pobieranie kubeconfig
```bash
# Pobierz credentials administratora
az aks get-credentials \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --admin
```

### Zalety ✅
- Prosty setup, brak zależności zewnętrznych
- Bardzo granularna kontrola uprawnień
- Działa offline (po pobraniu kubeconfig)
- Szybki - brak dodatkowych skoków do Azure API

### Wady ❌
- Trudne zarządzanie użytkownikami w dużych organizacjach
- Brak centralnego audytu (tylko logi Kubernetes)
- Rotacja certyfikatów wymaga aktualizacji kubeconfig u wszystkich
- Brak integracji z korporacyjnym systemem tożsamości
- Ryzyko wycieku certyfikatów

### Kiedy użyć?
- Małe zespoły (2-5 osób)
- Środowiska dev/test
- Automatyzacja CI/CD z Service Accounts
- Gdy nie potrzebujesz integracji z Azure AD

---

## Model 2: Microsoft Entra ID (Azure AD) + Kubernetes RBAC

### Opis
Uwierzytelnianie przez Azure AD, ale autoryzacja nadal w Kubernetes.

### Uwierzytelnianie (Authentication)
- **Microsoft Entra ID** (dawniej Azure AD)
- Użytkownicy logują się kontem firmowym
- Token OAuth 2.0 / OpenID Connect
- Możliwość MFA, Conditional Access

### Autoryzacja (Authorization)
- **Kubernetes RBAC** - jak w modelu 1
- Binding do Azure AD users/groups przez ich ID
- Weryfikacja w **Kubernetes API Server**

### Przepływ requestu
```
kubectl get pods
    ↓
Token Entra ID → Kubernetes API Server
    ↓
Kubernetes weryfikuje token z Entra ID
    ↓
Kubernetes RBAC sprawdza Role/RoleBinding
    ↓
✅/❌ Decyzja
```

### Przykład konfiguracji

```yaml
# RoleBinding z użytkownikiem Azure AD
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-team-pods
  namespace: development
subjects:
- kind: User
  name: "a1b2c3d4-1234-5678-9abc-def012345678"  # Object ID z Entra ID
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: "e5f6g7h8-5678-9012-3def-456789012345"  # Group ID z Entra ID
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
```

### Pobieranie kubeconfig
```bash
# Pobierz credentials z integracją Entra ID
az aks get-credentials \
  --resource-group myResourceGroup \
  --name myAKSCluster
  # Bez flagi --admin!

# Pierwsze kubectl wymusi logowanie
kubectl get pods
# Otworzy się przeglądarka do logowania przez Entra ID
```

### Znajdowanie Object ID użytkownika/grupy
```bash
# Object ID użytkownika
az ad user show --id jan.kowalski@firma.pl --query objectId -o tsv

# Object ID grupy
az ad group show --group "Kubernetes-Admins" --query objectId -o tsv
```

### Zalety ✅
- Centralne zarządzanie użytkownikami w Entra ID
- MFA i Conditional Access
- Nie trzeba zarządzać certyfikatami
- Automatyczna synchronizacja z HR (joiners/leavers)
- Lepsza kontrola dostępu niż lokalne konta

### Wady ❌
- Nadal musisz zarządzać RBAC w Kubernetes (YAML)
- Trzeba znać Object ID użytkowników/grup
- Wymaga połączenia z internetem do logowania
- Mniej granularna kontrola niż czysty Azure RBAC

### Kiedy użyć?
- Średnie i duże organizacje
- Gdy chcesz MFA ale zachować kontrolę w Kubernetes
- Zespoły, które już znają Kubernetes RBAC
- Hybrydowe środowiska (on-prem + Azure)

---

## Model 3: Microsoft Entra ID + Azure RBAC

### Opis
**Pełna integracja z Azure** - zarówno uwierzytelnianie jak i autoryzacja odbywa się w Azure.

### Uwierzytelnianie (Authentication)
- **Microsoft Entra ID** - identycznie jak Model 2

### Autoryzacja (Authorization)
- **Azure RBAC** zamiast Kubernetes RBAC
- Role przypisywane w Azure Portal/CLI
- Weryfikacja w **Azure API** PRZED dotarciem do Kubernetes

### Przepływ requestu
```
kubectl get pods
    ↓
Token Entra ID → Azure API (Resource Manager)
    ↓
Azure RBAC sprawdza role Azure
    ↓
✅ PASS → Request przekazany do Kubernetes API Server
    ↓
Kubernetes wykonuje akcję (pomija swój RBAC)
    
❌ FAIL → 403 Forbidden (nie dociera do Kubernetes)
```

### Wbudowane role Azure dla AKS

| Rola Azure | Zakres | Uprawnienia |
|------------|--------|-------------|
| **Azure Kubernetes Service RBAC Cluster Admin** | Cały klaster | Pełny dostęp do wszystkiego |
| **Azure Kubernetes Service RBAC Admin** | Namespace | Admin w wybranym namespace |
| **Azure Kubernetes Service RBAC Writer** | Namespace | Tworzenie i edycja zasobów |
| **Azure Kubernetes Service RBAC Reader** | Namespace/Klaster | Tylko odczyt |

### Przykład konfiguracji

```bash
# Przypisanie roli na poziomie klastra
az role assignment create \
  --role "Azure Kubernetes Service RBAC Reader" \
  --assignee jan.kowalski@firma.pl \
  --scope /subscriptions/SUBSCRIPTION_ID/resourceGroups/RG_NAME/providers/Microsoft.ContainerService/managedClusters/CLUSTER_NAME

# Przypisanie roli dla konkretnego namespace
az role assignment create \
  --role "Azure Kubernetes Service RBAC Writer" \
  --assignee DevTeam@firma.pl \
  --scope /subscriptions/SUBSCRIPTION_ID/resourceGroups/RG_NAME/providers/Microsoft.ContainerService/managedClusters/CLUSTER_NAME/namespaces/production

# Przypisanie roli dla grupy Azure AD
az role assignment create \
  --role "Azure Kubernetes Service RBAC Admin" \
  --assignee-object-id "a1b2c3d4-5678-90ab-cdef-1234567890ab" \
  --assignee-principal-type Group \
  --scope /subscriptions/SUBSCRIPTION_ID/resourceGroups/RG_NAME/providers/Microsoft.ContainerService/managedClusters/CLUSTER_NAME
```

### Włączanie Azure RBAC w AKS

```bash
# Przy tworzeniu klastra
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --enable-aad \
  --enable-azure-rbac

# Dla istniejącego klastra
az aks update \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --enable-azure-rbac
```

### Pobieranie kubeconfig
```bash
# Identycznie jak Model 2
az aks get-credentials \
  --resource-group myResourceGroup \
  --name myAKSCluster

# kubectl automatycznie używa Azure RBAC
kubectl get pods
```

### Zalety ✅
- **Wszystko w Azure Portal** - jedna konsola do zarządzania
- Nie musisz zarządzać YAML dla RBAC
- Unified auditing w Azure Activity Logs
- Łatwa integracja z Azure Policy
- Centralne zarządzanie compliance
- Lepsze dla zespołów znających Azure, nieznających Kubernetes

### Wady ❌
- Mniej granularna kontrola niż Kubernetes RBAC
- Każde kubectl idzie przez Azure (potencjalnie wolniejsze)
- Wymaga połączenia z Azure API
- Vendor lock-in (specificzne dla Azure)
- Trudniejsze debugowanie (dwie warstwy: Azure + K8s)

### Kiedy użyć?
- Duże korporacje z silnym Azure governance
- Gdy zarządzanie odbywa się przez Azure Portal
- Potrzeba compliance i audytu w Azure
- Zespoły z mniejszą wiedzą o Kubernetes
- Multi-cluster management z centralizacją w Azure

---

## Porównanie wszystkich trzech modeli

### Tabela porównawcza

| Aspekt | Local Accounts | Entra ID + K8s RBAC | Entra ID + Azure RBAC |
|--------|----------------|---------------------|----------------------|
| **Uwierzytelnianie** | Certyfikaty X.509 | Microsoft Entra ID | Microsoft Entra ID |
| **Autoryzacja** | Kubernetes RBAC | Kubernetes RBAC | Azure RBAC |
| **Gdzie weryfikacja?** | Kubernetes API | Kubernetes API | Azure API + K8s API |
| **Zarządzanie** | kubectl + YAML | kubectl + YAML | Azure Portal/CLI |
| **MFA** | ❌ Nie | ✅ Tak | ✅ Tak |
| **Audyt** | K8s audit logs | K8s audit logs | Azure Activity Logs |
| **Granulacja** | ⭐⭐⭐ Bardzo wysoka | ⭐⭐⭐ Bardzo wysoka | ⭐⭐ Średnia |
| **Prostota** | ⭐⭐ Średnia | ⭐ Skomplikowane | ⭐⭐⭐ Proste |
| **Wymaga internetu** | ❌ Nie (po setup) | ✅ Do logowania | ✅ Zawsze |
| **Vendor lock-in** | ❌ Przenośne | ❌ Przenośne | ✅ Azure-specific |
| **Szybkość** | Bardzo szybkie | Szybkie | Wolniejsze (extra hop) |

### Diagram przepływu requestów

```
┌─────────────────────────────────────────────────────────────────┐
│                    MODEL 1: LOCAL ACCOUNTS                      │
└─────────────────────────────────────────────────────────────────┘

kubectl get pods
     │
     │ kubeconfig (cert)
     ▼
┌────────────────────┐
│ Kubernetes API     │──► K8s RBAC ──► ✅/❌
└────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│              MODEL 2: ENTRA ID + KUBERNETES RBAC                │
└─────────────────────────────────────────────────────────────────┘

kubectl get pods
     │
     │ OAuth Token
     ▼
┌────────────────────┐      ┌────────────────────┐
│  Entra ID          │──►   │ Kubernetes API     │──► K8s RBAC ──► ✅/❌
│  (weryfikacja ID)  │      │                    │
└────────────────────┘      └────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                MODEL 3: ENTRA ID + AZURE RBAC                   │
└─────────────────────────────────────────────────────────────────┘

kubectl get pods
     │
     │ OAuth Token
     ▼
┌────────────────────┐      ┌────────────────────┐      ┌────────────────────┐
│  Entra ID          │──►   │   Azure API        │──►   │ Kubernetes API     │
│  (weryfikacja ID)  │      │  (Azure RBAC)      │      │ (tylko wykonanie)  │
└────────────────────┘      └────────────────────┘      └────────────────────┘
                                   │
                                   │ ❌ 403 Forbidden
                                   ▼
                              Brak dostępu
```

---

## Hybrydowy model - kombinacja

### Możesz łączyć modele!

**Scenariusz: Ludzie przez Azure, Aplikacje przez Service Accounts**

```yaml
# Azure RBAC dla developerów
# (konfigurowane w Azure Portal)

---
# Kubernetes RBAC dla aplikacji
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monitoring-app
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-metrics-reader
rules:
- apiGroups: [""]
  resources: ["pods", "nodes"]
  verbs: ["get", "list"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["pods", "nodes"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-app-binding
subjects:
- kind: ServiceAccount
  name: monitoring-app
  namespace: monitoring
roleRef:
  kind: ClusterRole
  name: pod-metrics-reader
  apiGroup: rbac.authorization.k8s.io
```

**Deployment używający Service Account:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: monitoring-app
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: monitoring
  template:
    metadata:
      labels:
        app: monitoring
    spec:
      serviceAccountName: monitoring-app  # ← Tu przypisujesz SA
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        # Token SA jest automatycznie montowany w /var/run/secrets/kubernetes.io/serviceaccount/
```

---

## Debugowanie problemów z uprawnieniami

### Jak rozpoznać, który model używasz?

```bash
# Sprawdź cluster config
az aks show --resource-group myRG --name myAKS --query aadProfile

# Jeśli null → Model 1 (Local Accounts)
# Jeśli managed=true, enableAzureRBAC=false → Model 2
# Jeśli managed=true, enableAzureRBAC=true → Model 3
```

### Typowe błędy i rozwiązania

#### Model 1: Local Accounts
```
Error: Forbidden: User "system:anonymous" cannot get path "/"
```
**Rozwiązanie:** Brak lub nieprawidłowy certyfikat w kubeconfig
```bash
az aks get-credentials --resource-group myRG --name myAKS --admin --overwrite-existing
```

#### Model 2: Entra ID + K8s RBAC
```
Error: pods is forbidden: User "a1b2c3d4-..." cannot list resource "pods"
```
**Rozwiązanie:** Dodaj RoleBinding w Kubernetes
```bash
kubectl create clusterrolebinding user-admin \
  --clusterrole=cluster-admin \
  --user=a1b2c3d4-1234-5678-9abc-def012345678
```

#### Model 3: Entra ID + Azure RBAC
```
Error: Forbidden: User "jan@firma.pl" cannot list resource "pods" 
at the cluster scope
```
**Rozwiązanie:** Dodaj Azure Role Assignment
```bash
az role assignment create \
  --role "Azure Kubernetes Service RBAC Reader" \
  --assignee jan@firma.pl \
  --scope /subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerService/managedClusters/myAKS
```

### Narzędzie diagnostyczne

```bash
# Sprawdź swoje obecne uprawnienia
kubectl auth can-i --list

# Sprawdź konkretną akcję
kubectl auth can-i create deployments --namespace production

# Sprawdź dla innego użytkownika (jako admin)
kubectl auth can-i list pods --as=jan@firma.pl
```

---

## Zalecenia i best practices

### Dla małych projektów (1-10 osób)
**Rekomendacja: Model 1 (Local Accounts)**
- Prosty setup
- Bez kosztów dodatkowych usług
- Wystarczająca kontrola

### Dla średnich firm (10-100 osób)
**Rekomendacja: Model 2 (Entra ID + K8s RBAC)**
- Centralne zarządzanie tożsamością
- Zachowanie pełnej kontroli w Kubernetes
- Możliwość migracji do Model 3 w przyszłości

### Dla dużych korporacji (100+ osób)
**Rekomendacja: Model 3 (Entra ID + Azure RBAC)**
- Pełna integracja z Azure governance
- Łatwiejsze compliance audyty
- Mniej pracy dla zespołu platformowego

### Security best practices (niezależnie od modelu)

1. **Principle of Least Privilege**
   - Przyznawaj minimalne wymagane uprawnienia
   - Używaj namespace-scoped ról zamiast ClusterRole gdzie to możliwe

2. **Regularny audyt**
   ```bash
   # Lista wszystkich RoleBindings
   kubectl get rolebindings,clusterrolebindings --all-namespaces
   
   # Lista Azure role assignments
   az role assignment list --scope /subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerService/managedClusters/myAKS
   ```

3. **Wyłącz Local Accounts w produkcji** (jeśli używasz Model 2 lub 3)
   ```bash
   az aks update \
     --resource-group myRG \
     --name myAKS \
     --disable-local-accounts
   ```

4. **Używaj grup zamiast indywidualnych użytkowników**
   ```bash
   # Lepiej:
   az role assignment create \
     --role "Azure Kubernetes Service RBAC Reader" \
     --assignee DevTeam@firma.pl  # Grupa
   
   # Niż:
   # 10 osobnych przypisań dla każdego developera
   ```

5. **Break-glass account** - Zawsze miej awaryjny dostęp
   ```bash
   # Przechowuj w bezpiecznym miejscu (np. Azure Key Vault)
   az aks get-credentials --admin --file ~/emergency-kubeconfig
   ```

---

## Podsumowanie

### Która opcja dla Ciebie?

**Wybierz Model 1 jeśli:**
- Masz mały zespół
- Cenisz prostotę
- Nie potrzebujesz MFA
- Chcesz mieć pełną kontrolę w Kubernetes

**Wybierz Model 2 jeśli:**
- Potrzebujesz MFA i Entra ID integration
- Chcesz zachować pełną granularność Kubernetes RBAC
- Masz zespół znający Kubernetes
- Chcesz flexibility między on-prem i cloud

**Wybierz Model 3 jeśli:**
- Zarządzasz wieloma klastrami z Azure
- Priorytetem jest compliance i audyt
- Wolisz zarządzać wszystkim z Azure Portal
- Masz dedykowany zespół Azure, nie K8s experts

### Kluczowe różnice w pigułce

| Model | Uwierzytelnianie | Autoryzacja | Gdzie decyzja? |
|-------|------------------|-------------|----------------|
| **1** | Certyfikaty | Kubernetes RBAC | Kubernetes API |
| **2** | Entra ID | Kubernetes RBAC | Kubernetes API |
| **3** | Entra ID | Azure RBAC | Azure API |