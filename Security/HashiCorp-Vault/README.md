# HashiCorp Vault – zarządzanie sekretami w Kubernetes

## Co to jest HashiCorp Vault?

HashiCorp Vault to narzędzie do centralnego zarządzania sekretami (hasłami, kluczami API, certyfikatami, tokenami) w infrastrukturze IT. Rozwiązuje jeden z największych problemów bezpieczeństwa: **przechowywanie i dystrybucję sekretów**.

### Problem bez Vault

Bez centralnego narzędzia do zarządzania sekretami organizacje zazwyczaj:
- Wpisują sekrety bezpośrednio w kod źródłowy lub pliki konfiguracyjne
- Przechowują je w zmiennych środowiskowych bez szyfrowania
- Kopiują te same hasła do wielu miejsc (brak rotacji, brak audytu)
- Nie wiedzą kto, kiedy i jak użył danego sekretu

### Vault rozwiązuje te problemy przez:
- **Centralne przechowywanie** – jeden punkt prawdy dla wszystkich sekretów
- **Szyfrowanie** – sekrety szyfrowane w spoczynku i w tranzycie
- **Dynamic Secrets** – hasła generowane na żądanie z krótkim czasem życia (TTL)
- **Audit Log** – pełna historia kto i kiedy odczytał dany sekret
- **Fine-grained policies** – dokładna kontrola kto ma dostęp do czego

---

## Architektura Vault

```
┌─────────────────────────────────────────────┐
│                  Vault Server               │
│                                             │
│  ┌──────────────┐   ┌────────────────────┐  │
│  │ Auth Methods │   │  Secret Engines    │  │
│  │  - Kubernetes│   │  - KV v2           │  │
│  │  - JWT/OIDC  │   │  - Database        │  │
│  │  - AppRole   │   │  - PKI (certs)     │  │
│  │  - Token     │   │  - AWS/GCP/Azure   │  │
│  └──────┬───────┘   └────────────────────┘  │
│         │                                   │
│  ┌──────▼───────────────────────────────┐   │
│  │            Policies (ACL)            │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │         Storage Backend              │   │
│  │  (Consul, Raft, etcd, file, ...)     │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

### Seal / Unseal

Vault startuje w stanie **sealed** (zamknięty). Oznacza to, że nie może odczytać żadnych sekretów – dane są zaszyfrowane i klucz deszyfrujący nie jest w pamięci.

Aby Vault działał, musi zostać **unsealed** (odblokowany). Domyślnie używany jest mechanizm **Shamir's Secret Sharing**: klucz główny jest podzielony na N części (key shares), a do odblokowania potrzeba K z nich (threshold).

```bash
# Inicjalizacja – generuje 5 key shares, próg = 3
vault operator init -key-shares=5 -key-threshold=3

# Unseal (powtórz 3 razy z różnymi kluczami)
vault operator unseal <key-share-1>
vault operator unseal <key-share-2>
vault operator unseal <key-share-3>
```

W środowisku produkcyjnym należy używać **Auto Unseal** przez HSM, AWS KMS, GCP KMS lub Azure Key Vault.

---

## Podstawowe pojęcia

### Secret Engines

Secret Engines to wtyczki w Vault odpowiedzialne za przechowywanie i generowanie sekretów.

| Engine | Opis | Przykład użycia |
|--------|------|-----------------|
| **KV v2** | Key-Value store z wersjonowaniem | Hasła, klucze API, tokeny |
| **Database** | Dynamic secrets dla baz danych | Tymczasowe hasła do PostgreSQL/MySQL |
| **PKI** | Certificate Authority | Generowanie certyfikatów TLS |
| **AWS/GCP/Azure** | Chmurowe credentiale | Tymczasowe klucze AWS IAM |
| **SSH** | Podpisywanie kluczy SSH | Tymczasowy dostęp do serwerów |
| **Transit** | Szyfrowanie jako usługa | Szyfrowanie danych bez ich przechowywania |

```bash
# Włączanie KV v2
vault secrets enable -path=secret kv-v2

# Podstawowe operacje KV
vault kv put secret/myapp/config db_password="supersecret" api_key="abc123"
vault kv get secret/myapp/config
vault kv get -field=db_password secret/myapp/config
vault kv list secret/myapp/

# Wersjonowanie
vault kv put secret/myapp/config db_password="newpassword"
vault kv get -version=1 secret/myapp/config
```

### Auth Methods

Auth Methods to sposoby uwierzytelnienia do Vault.

| Method | Opis | Kiedy używać |
|--------|------|--------------|
| **Kubernetes** | Weryfikacja przez K8s Service Account | Aplikacje na K8s |
| **JWT/OIDC** | Tokeny JWT (GitHub Actions, GitLab CI) | CI/CD pipelines |
| **AppRole** | RoleID + SecretID | Automatyzacje, legacy apps |
| **Token** | Bezpośredni token Vault | Administratorzy, testy |
| **AWS IAM** | Rola AWS IAM | Aplikacje na AWS |

### Policies

Polityki definiują co dany podmiot może zrobić w Vault. Format HCL:

```hcl
# Polityka dla aplikacji myapp
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/myapp/*" {
  capabilities = ["read", "list"]
}

# Zabronione (domyślnie wszystko jest zabronione)
# path "secret/data/admin/*" {}
```

```bash
# Tworzenie polityki
vault policy write myapp-policy myapp-policy.hcl

# Listowanie polityk
vault policy list

# Czytanie polityki
vault policy read myapp-policy
```

### Dynamic Secrets

Dynamic Secrets to sekrety generowane na żądanie z automatycznym wygasaniem (TTL).

```bash
# Konfiguracja Database Engine dla PostgreSQL
vault secrets enable database

vault write database/config/mydb \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/mydb" \
  allowed_roles="myapp-role" \
  username="vault_admin" \
  password="admin_password"

vault write database/roles/myapp-role \
  db_name=mydb \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Generowanie tymczasowych credentiali
vault read database/creds/myapp-role
# Key                Value
# username           v-myapp-abc123
# password           A1B2C3D4-xyz
# lease_duration     1h
```

---

## Metody integracji z Kubernetes

Vault oferuje 4 główne metody integracji z K8s. Wybór zależy od wymagań projektu.

| Metoda | Jak działa | Zalety | Wady | Kiedy używać |
|--------|-----------|--------|------|--------------|
| **Agent Sidecar Injector** | Sidecar container wstrzykuje sekrety jako pliki do `/vault/secrets/` | Brak zmian w kodzie, automatyczna rotacja | Dodatkowy container, pliki zamiast env vars | Legacy apps, migracja |
| **Vault Secrets Operator (VSO)** | CRD synchronizuje sekrety do K8s Secret | Standard K8s API, GitOps-friendly | Sekrety widoczne jako K8s Secret (base64) | Nowe projekty, GitOps |
| **CSI Secrets Store** | Wolumen montowany przez CSI driver bezpośrednio z Vault | Brak K8s Secret (domyślnie), standard CSI | Skomplikowana konfiguracja | Wiele providerów (Vault + AWS SM) |
| **Direct API / SDK** | Aplikacja bezpośrednio odpytuje Vault API | Pełna kontrola, dynamic secrets | Wymaga zmian w kodzie | Mikroserwisy, dynamic secrets |

---

### Metoda 1 – Agent Sidecar Injector

Vault Agent Injector to **MutatingAdmissionWebhook** – przechwytuje każde tworzenie Poda i automatycznie wstrzykuje do niego dodatkowe kontenery, jeśli Pod ma odpowiednie annotacje.

```
┌──────────────────────────────────────────────────────────────┐
│  kubectl apply deployment.yaml                               │
│         │                                                    │
│         ▼                                                    │
│  Kubernetes API Server                                       │
│         │                                                    │
│         │  MutatingAdmissionWebhook                         │
│         ▼                                                    │
│  vault-agent-injector (Deployment w ns vault)                │
│         │  widzi annotacje vault.hashicorp.com/*             │
│         │  mutuje spec Poda – dodaje 2 kontenery             │
│         ▼                                                    │
│  Pod (zmutowany):                                            │
│  ┌─────────────────────────────────────────────────────┐     │
│  │ [init: vault-agent-init]  ──▶  loguje się do Vault  │     │
│  │                               pobiera sekrety       │     │
│  │                               zapisuje do           │     │
│  │                               /vault/secrets/       │     │
│  │                                    │                │     │
│  │ [app container]  ◀─────────────────┘                │     │
│  │   czyta /vault/secrets/config                       │     │
│  │                                                     │     │
│  │ [sidecar: vault-agent]  ──▶  odświeża sekrety       │     │
│  │                               co TTL/lease          │     │
│  └─────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

**Jak aplikacja dostaje sekrety:**
- Sekrety zapisywane jako pliki w `/vault/secrets/<nazwa>`
- Domyślny format: JSON (`{"db_password":"xyz","api_key":"abc"}`)
- Z szablonem Go: dowolny format (env-file, YAML, .properties, JSON)
- Aplikacja czyta plik lub uruchamia `source /vault/secrets/config`

**Rotacja sekretów:**
- Sidecar `vault-agent` działa przez cały czas życia Poda
- Automatycznie odświeża sekret przed wygaśnięciem lease
- Opcja `agent-inject-command-<name>` – wykonaj komendę po odświeżeniu (np. `kill -HUP 1` do reload bez restartu poda)

**Konfiguracja przez annotacje:**

```yaml
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "myapp"
  vault.hashicorp.com/agent-inject-secret-config: "secret/data/myapp/config"
  vault.hashicorp.com/agent-inject-template-config: |
    {{- with secret "secret/data/myapp/config" -}}
    export DB_PASSWORD="{{ .Data.data.db_password }}"
    export API_KEY="{{ .Data.data.api_key }}"
    {{- end }}
  # Tylko init container (bez sidecar) – sekrety nie będą odświeżane
  # vault.hashicorp.com/agent-pre-populate-only: "true"
```

**Widoczność sekretów w K8s:** NIE – sekrety nigdy nie trafiają do `kubectl get secrets`. Istnieją tylko wewnątrz poda jako pliki w tmpfs.

**Kiedy wybierać:**
- Aplikacja legacy, której nie możesz modyfikować
- Potrzebujesz dynamicznych sekretów (database, PKI) z automatyczną rotacją
- Chcesz zero zmian w kodzie i manifeście (tylko annotacje)

---

### Metoda 2 – Vault Secrets Operator (VSO)

VSO to Kubernetes Operator (CRD + Controller), który działa jako most między Vault a natywnymi K8s Secrets. Synchronizuje sekrety z Vault do K8s Secrets i opcjonalnie restartuje Deploymenty po zmianie.

```
┌────────────────────────────────────────────────────────────────┐
│  Git repo (GitOps)                                             │
│  VaultAuth.yaml + VaultStaticSecret.yaml                       │
│         │                                                      │
│         ▼  kubectl apply / ArgoCD / Flux                       │
│  Kubernetes API Server                                         │
│         │                                                      │
│         ▼  Watch CRD events                                    │
│  VSO Controller (Deployment w ns vault-secrets-operator-system)│
│         │                                                      │
│         │  1. Odczytuje VaultAuth → loguje się do Vault        │
│         │     przez Kubernetes Auth Method                     │
│         │                                                      │
│         │  2. Odczytuje VaultStaticSecret → pobiera sekret     │
│         │     z Vault KV                                       │
│         │                                                      │
│         │  3. Tworzy/aktualizuje K8s Secret                    │
│         ▼                                                      │
│  K8s Secret "myapp-config" (Opaque)                            │
│  data:                                                         │
│    db_password: c3VwZXJzZWNyZXQ=  (base64)                    │
│    api_key: dmF1bHQtYXBpLWtleQ==  (base64)                    │
│         │                                                      │
│         ▼  envFrom / secretKeyRef                              │
│  Pod (standardowe K8s API)                                     │
│    env:                                                        │
│      DB_PASSWORD=supersecret                                   │
│      API_KEY=vault-api-key                                     │
└────────────────────────────────────────────────────────────────┘
```

**Cykl synchronizacji:**

```
VaultStaticSecret.refreshAfter = 60s
         │
         ▼ co 60 sekund
VSO Controller sprawdza Vault
         │
         ├── sekret NIE zmienił się → nic nie robi
         │
         └── sekret ZMIENIŁ się → aktualizuje K8s Secret
                  │
                  └── rolloutRestartTargets skonfigurowane?
                           │
                           ├── TAK → kubectl rollout restart deployment/myapp
                           └── NIE → Pod nadal czyta stary sekret
                                     (dopóki nie zostanie zrestartowany)
```

**Ważne: sekrety są widoczne w K8s!**

```bash
kubectl get secret myapp-config -n demo-app -o yaml
# data:
#   db_password: c3VwZXJzZWNyZXQ=   ← base64, NIE szyfrowane
#   api_key: dmF1bHQtYXBpLWtleQ==

# Zdekodowanie przez każdego kto ma dostęp do Secret:
kubectl get secret myapp-config -n demo-app \
  -o jsonpath='{.data.db_password}' | base64 -d
```

> To jest kompromis VSO – wygoda GitOps vs widoczność sekretów w K8s etcd.
> Zabezpieczenie: stosuj **RBAC** ograniczający dostęp do Secrets + **etcd encryption at rest**.

**Obsługiwane typy CRD:**

| CRD | Opis |
|-----|------|
| `VaultConnection` | Adres i TLS do Vault (opcjonalne, można użyć defaultVaultConnection) |
| `VaultAuth` | Metoda uwierzytelnienia (kubernetes, jwt, appRole) |
| `VaultStaticSecret` | Synchronizacja KV v1/v2 do K8s Secret |
| `VaultDynamicSecret` | Dynamic secrets (database, AWS, PKI) → K8s Secret |
| `VaultPKISecret` | Certyfikaty TLS z PKI engine → K8s Secret (type: kubernetes.io/tls) |

**Kiedy wybierać:**
- Nowe projekty z GitOps (ArgoCD, Flux)
- Aplikacje które już używają K8s Secrets (`envFrom`, `secretKeyRef`)
- Potrzebujesz jednego Operatora na cały klaster (nie sidecar per Pod)
- Chcesz automatycznego restartu Deploymentu przy rotacji sekretu

---

### Metoda 3 – CSI Secrets Store Provider

Secrets Store CSI Driver to standard CNCF (nie tylko Vault) – pozwala montować sekrety z zewnętrznych providerów (Vault, AWS Secrets Manager, Azure Key Vault, GCP Secret Manager) jako wolumeny CSI w Podach.

```
┌──────────────────────────────────────────────────────────────────┐
│  SecretProviderClass (CRD)                                       │
│  provider: vault                                                 │
│  objects: [{secretPath: "secret/data/myapp/config",              │
│             secretKey: "db_password",                            │
│             objectName: "db_password"}]                          │
│         │                                                        │
│         ▼  Pod z volumes.csi.driver: secrets-store.csi.k8s.io   │
│  kubelet (na węźle)                                              │
│         │                                                        │
│         ▼  NodePublishVolume                                     │
│  Secrets Store CSI Driver (DaemonSet – jeden pod per węzeł)      │
│         │                                                        │
│         │  1. Pobiera SA token Poda                              │
│         │  2. Wywołuje Vault Provider plugin                     │
│         ▼                                                        │
│  Vault CSI Provider (DaemonSet – jeden pod per węzeł)            │
│         │                                                        │
│         │  3. Loguje się do Vault przez Kubernetes Auth          │
│         │  4. Pobiera sekrety z Vault KV                        │
│         │  5. Zwraca wartości do CSI Drivera                    │
│         ▼                                                        │
│  tmpfs wolumen zamontowany w Podzie                              │
│  /mnt/secrets-store/                                             │
│    db_password   ← plik (zawartość: "supersecret")              │
│    api_key       ← plik (zawartość: "vault-api-key-123")        │
│                                                                  │
│  Opcjonalnie (secretObjects w SecretProviderClass):              │
│         │                                                        │
│         ▼  tylko gdy Pod istnieje i wolumen jest zamontowany     │
│  K8s Secret "myapp-csi-secret"                                   │
│  data:                                                           │
│    db_password: c3VwZXJzZWNyZXQ=                                │
└──────────────────────────────────────────────────────────────────┘
```

**Kluczowa różnica względem VSO: sekrety NIE istnieją bez Poda**

```
Scenariusz: Pod zostaje usunięty

VSO:    K8s Secret "myapp-config" → nadal istnieje ✓
CSI:    K8s Secret "myapp-csi-secret" → USUWANY automatycznie ✗
        (jeśli nie ma żadnego Poda z zamontowanym wolumenem)
```

**Rotacja sekretów:**

```bash
# CSI Driver sprawdza zmiany co rotationPollInterval (domyślnie 2 minuty)
# Instalacja z włączoną rotacją:
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --set enableSecretRotation=true \
  --set rotationPollInterval=120s

# Po rotacji: pliki w /mnt/secrets-store/ są aktualizowane automatycznie
# Po rotacji: K8s Secret (secretObjects) jest aktualizowany automatycznie
# Po rotacji: Pod NIE jest restartowany (czyta plik ponownie lub trzeba
#             skonfigurować własny mechanizm reloadu aplikacji)
```

**Multi-provider – największa zaleta CSI:**

```yaml
# Jeden Pod może montować sekrety z wielu providerów jednocześnie
volumes:
  - name: vault-secrets
    csi:
      driver: secrets-store.csi.k8s.io
      volumeAttributes:
        secretProviderClass: vault-myapp-config   # z Vault
  - name: aws-secrets
    csi:
      driver: secrets-store.csi.k8s.io
      volumeAttributes:
        secretProviderClass: aws-myapp-config     # z AWS Secrets Manager
```

**Kiedy wybierać:**
- Środowisko multi-cloud (sekrety w Vault + AWS SM + Azure KV jednocześnie)
- Aplikacje które oczekują plików konfiguracyjnych (nie env vars)
- Chcesz uniknąć K8s Secrets (domyślnie sekrety nie trafiają do etcd)
- Migracja z Azure Key Vault CSI (ten sam interfejs)

---

### Metoda 4 – Direct API / Vault SDK

Aplikacja samodzielnie komunikuje się z Vault API przez HTTP lub dedykowany SDK. Daje największą kontrolę, ale wymaga zmian w kodzie.

```
┌──────────────────────────────────────────────────────────────┐
│  Pod (aplikacja)                                             │
│  ServiceAccount: myapp                                       │
│         │                                                    │
│         │  1. Odczytaj własny SA Token                       │
│         │     /var/run/secrets/kubernetes.io/serviceaccount/ │
│         │                                                    │
│         │  2. POST /v1/auth/kubernetes/login                 │
│         │     {role: "myapp", jwt: "<SA_TOKEN>"}             │
│         ▼                                                    │
│  Vault Server                                                │
│         │  weryfikuje SA Token przez K8s TokenReview API     │
│         │  zwraca Vault Token + lease_duration               │
│         ▼                                                    │
│  Pod (aplikacja)                                             │
│         │                                                    │
│         │  3. GET /v1/secret/data/myapp/config               │
│         │     Header: X-Vault-Token: <vault_token>           │
│         ▼                                                    │
│  Vault Server → zwraca sekret (JSON)                         │
│         │                                                    │
│         ▼                                                    │
│  Aplikacja przechowuje sekret w pamięci (nie na dysku)       │
│         │                                                    │
│         │  4. Przed wygaśnięciem lease – odnów token        │
│         │     PUT /v1/auth/token/renew-self                  │
│         │  lub ponów logowanie przez SA Token                │
└──────────────────────────────────────────────────────────────┘
```

**Przykład w Go (Vault SDK):**

```go
import vault "github.com/hashicorp/vault/api"
import auth "github.com/hashicorp/vault/api/auth/kubernetes"

func getSecret() (string, error) {
    client, _ := vault.NewClient(vault.DefaultConfig())

    // Logowanie przez Kubernetes Auth (SA Token z pliku)
    k8sAuth, _ := auth.NewKubernetesAuth("myapp")
    authInfo, _ := client.Auth().Login(context.Background(), k8sAuth)

    // Odczyt sekretu
    secret, _ := client.KVv2("secret").Get(context.Background(), "myapp/config")
    return secret.Data["db_password"].(string), nil
}
```

**Przykład w Pythonie:**

```python
import hvac
import os

def get_vault_secret():
    client = hvac.Client(url=os.environ["VAULT_ADDR"])

    # Logowanie przez Kubernetes Auth
    with open("/var/run/secrets/kubernetes.io/serviceaccount/token") as f:
        jwt_token = f.read()

    client.auth.kubernetes.login(role="myapp", jwt=jwt_token)

    # Odczyt sekretu – pozostaje w pamięci, nie trafia na dysk
    secret = client.secrets.kv.v2.read_secret_version(
        path="myapp/config", mount_point="secret"
    )
    return secret["data"]["data"]["db_password"]
```

**Dynamic Secrets – największa zaleta Direct API:**

```python
# Baza danych: nowe hasło generowane przy każdym uruchomieniu aplikacji
creds = client.secrets.database.generate_credentials(name="myapp-role")
db_user = creds["data"]["username"]     # v-myapp-abc123 (unikalne!)
db_pass = creds["data"]["password"]     # losowe hasło
lease_id = creds["lease_id"]           # do odnowienia lub odwołania

# Połączenie z bazą
conn = psycopg2.connect(host="postgres", user=db_user, password=db_pass)

# Po zakończeniu pracy – odwołaj lease (dobre praktyki)
client.sys.revoke_lease(lease_id=lease_id)
```

**Kiedy wybierać:**
- Potrzebujesz Dynamic Secrets (database, PKI, AWS IAM) w kodzie aplikacji
- Masz pełną kontrolę nad cyklem życia lease i rotacją
- Budujesz mikroserwis z własną logiką zarządzania sekretami
- Chcesz unikać jakiegokolwiek zapisu sekretów na dysk/filesystem

---

### Porównanie wszystkich metod

```
                    Agent       VSO         CSI         Direct API
                    Injector                Provider
─────────────────────────────────────────────────────────────────
Zmiana w kodzie     NIE         NIE         NIE         TAK
Zmiana w YAML       annotacje   CRD         volume      env VAULT_ADDR
Sekrety w K8s       NIE         TAK         opcjonalnie NIE
  Secret?
Sekrety w etcd?     NIE         TAK(!)      opcjonalnie NIE
Rotacja bez         TAK         z restart   plik auto,  TAK (w kodzie)
  restartu Poda     (sidecar)   (rollout)   env nie
Dodatkowy           sidecar     operator    DaemonSet   brak
  komponent         per Pod     per klaster per węzeł
Dynamic Secrets     TAK         TAK(VSO     NIE         TAK (pełna
  (database/PKI)    (sidecar)   Dynamic)                kontrola)
Multi-provider      NIE         NIE         TAK         NIE
GitOps              trudny      łatwy       łatwy       trudny
                    (annotacje) (CRD)       (CRD)       (kod)
```

**Drzewo decyzyjne – którą metodę wybrać:**

```
Czy możesz modyfikować kod aplikacji?
├── NIE
│   ├── Potrzebujesz GitOps / standardowego K8s Secret?
│   │   ├── TAK  → VSO (Vault Secrets Operator)
│   │   └── NIE
│   │       ├── Wiele providerów sekretów (AWS SM + Vault)?
│   │       │   ├── TAK  → CSI Secrets Store
│   │       │   └── NIE  → Agent Sidecar Injector
│   └── (patrz NIE powyżej)
└── TAK
    ├── Potrzebujesz Dynamic Secrets (tymczasowe hasła DB)?
    │   ├── TAK  → Direct API / Vault SDK
    │   └── NIE  → VSO lub Direct API (prostszy przypadek)
```

---

## Integracja z CI/CD

### GitHub Actions

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write   # wymagane dla JWT/OIDC
      contents: read
    steps:
      - uses: hashicorp/vault-action@v3
        with:
          url: https://vault.example.com
          method: jwt
          role: github-actions
          secrets: |
            secret/data/myapp/config db_password | DB_PASSWORD ;
            secret/data/myapp/config api_key | API_KEY
      
      - run: echo "Deploying with secrets (masked in logs)"
        env:
          DB_PASSWORD: ${{ env.DB_PASSWORD }}
```

### GitLab CI

```yaml
deploy:
  image: vault:latest
  variables:
    VAULT_ADDR: "https://vault.example.com"
  script:
    - vault login -method=jwt jwt=$CI_JOB_JWT_V2 role=gitlab-ci
    - export DB_PASSWORD=$(vault kv get -field=db_password secret/myapp/config)
    - vault token revoke -self   # zawsze odwołaj token po użyciu
    - ./deploy.sh
```

### Konfiguracja JWT Auth Method dla CI/CD

```bash
vault auth enable jwt

# GitHub Actions
vault write auth/jwt/config \
  oidc_discovery_url="https://token.actions.githubusercontent.com" \
  bound_issuer="https://token.actions.githubusercontent.com"

vault write auth/jwt/role/github-actions \
  role_type=jwt \
  bound_claims_type=glob \
  bound_claims='{"sub":"repo:myorg/myrepo:*"}' \
  user_claim=sub \
  policies=myapp-policy \
  ttl=15m
```

---

## Najlepsze praktyki

### 1. Zasada minimalnych uprawnień (Least Privilege)

Każda aplikacja powinna mieć dostęp tylko do sekretów których potrzebuje:

```hcl
# DOBRZE: wąskie uprawnienia
path "secret/data/myapp/{{identity.entity.aliases.auth_kubernetes_*.metadata.service_account_namespace}}/*" {
  capabilities = ["read"]
}

# ŹLE: zbyt szerokie uprawnienia
path "secret/*" {
  capabilities = ["read", "write", "delete"]
}
```

### 2. Dynamic Secrets zamiast Static

Zamiast stałych haseł do bazy danych, używaj dynamicznych credentiali:
- TTL 1 godzina zamiast hasła "które zawsze było"
- Każda aplikacja dostaje unikalne credentiale
- Automatyczna rotacja przy wygasaniu lease

### 3. Audit Log

Zawsze włączaj audit log w produkcji:

```bash
vault audit enable file file_path=/vault/logs/audit.log
```

### 4. Rotacja Root Token

Root token ma pełne uprawnienia – po inicjalizacji wygeneruj nowy root token i zniszcz stary:

```bash
vault token revoke <root-token>
# Generuj nowy root token tylko gdy potrzebny (vault operator generate-root)
```

### 5. Namespace i Resource Quotas

W Kubernetes izoluj Vault w dedykowanym namespace z odpowiednimi resource limits.

### 6. High Availability

W produkcji używaj Vault z Integrated Storage (Raft):
- Minimum 3 węzły Vault
- Auto Unseal przez KMS
- Regularne snapshoty: `vault operator raft snapshot save backup.snap`

---

## Moduły ćwiczeniowe

| # | Katalog | Temat |
|---|---------|-------|
| 01 | [01-installation](./01-installation/) | Instalacja Vault na K8s przez Helm |
| 02 | [02-k8s-auth](./02-k8s-auth/) | Konfiguracja Kubernetes Auth Method |
| 03 | [03-agent-injector](./03-agent-injector/) | Agent Sidecar Injector |
| 04 | [04-vault-secrets-operator](./04-vault-secrets-operator/) | Vault Secrets Operator (VSO) |
| 05 | [05-csi-secrets-store](./05-csi-secrets-store/) | CSI Secrets Store Provider |
| 06 | [06-cicd-integration](./06-cicd-integration/) | Integracja z CI/CD (GitHub Actions, GitLab CI) |

---

## Przydatne linki

- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Vault on Kubernetes](https://developer.hashicorp.com/vault/docs/platform/k8s)
- [Vault Secrets Operator](https://developer.hashicorp.com/vault/docs/platform/k8s/vso)
- [Helm Chart hashicorp/vault](https://github.com/hashicorp/vault-helm)
- [vault-action for GitHub Actions](https://github.com/hashicorp/vault-action)
