# Ćwiczenie 06 – Integracja Vault z CI/CD

## Cel ćwiczenia

Skonfigurować Vault do bezpiecznego dostarczania sekretów do pipeline'ów CI/CD (GitHub Actions i GitLab CI) przy użyciu JWT/OIDC Auth Method – bez przechowywania długożyciowych tokenów w CI/CD.

## Dlaczego JWT/OIDC Auth dla CI/CD?

Tradycyjne podejście: przechowuj Vault Token jako sekret w CI/CD.

**Problem:**
- Tokeny mają długi czas życia
- Tokeny mogą wyciec z logów lub zmiennych
- Trudno rotować – ręczna aktualizacja w CI/CD

**Lepsze podejście: JWT/OIDC**

```
GitHub Actions/GitLab CI
       |
       | 1. Wygeneruj krótkotrwały JWT token (OIDC)
       |    (identyfikuje repo, branch, workflow)
       ▼
Vault Server
       |
       | 2. Weryfikuj JWT przez OIDC Discovery URL
       | 3. Sprawdź claims (repo, branch)
       | 4. Zwróć Vault Token (TTL 15 minut)
       ▼
CI/CD Pipeline
       |
       | 5. Użyj tokenu do odczytu sekretów
       | 6. Token wygasa automatycznie po zakończeniu
       ▼
Deploy/Build z sekretami (zamaskowane w logach)
```

## Wymagania wstępne

- Ukończone ćwiczenie 01 (Vault zainstalowany)
- Vault dostępny publicznie (lub przez tunel) z perspektywy GitHub/GitLab
- `VAULT_ADDR` i `VAULT_TOKEN` ustawione

## Krok 1 – Włącz JWT Auth Method

```bash
vault auth enable jwt

# Lub osobno dla GitHub i GitLab:
vault auth enable -path=github jwt
vault auth enable -path=gitlab jwt
```

## Krok 2a – Konfiguracja dla GitHub Actions

```bash
# OIDC Discovery URL GitHub Actions
vault write auth/jwt/config \
  oidc_discovery_url="https://token.actions.githubusercontent.com" \
  bound_issuer="https://token.actions.githubusercontent.com"

# Polityka dla GitHub Actions
vault policy write github-actions-policy - <<'EOF'
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}
EOF

# Rola – pozwala tylko określonemu repo i branchowi
vault write auth/jwt/role/github-myrepo \
  role_type=jwt \
  bound_claims_type=glob \
  bound_claims='{"sub":"repo:TWOJA_ORG/TWOJE_REPO:ref:refs/heads/main"}' \
  user_claim=sub \
  policies=github-actions-policy \
  ttl=15m
```

Patrz: [github-actions-example.yaml](./github-actions-example.yaml)

## Krok 2b – Konfiguracja dla GitLab CI

```bash
# OIDC Discovery URL GitLab (zmień na swój GitLab URL jeśli self-hosted)
vault write auth/jwt/config \
  oidc_discovery_url="https://gitlab.com" \
  bound_issuer="https://gitlab.com"

# Polityka
vault policy write gitlab-ci-policy - <<'EOF'
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}
EOF

# Rola – wiąże z projektem GitLab
vault write auth/jwt/role/gitlab-myproject \
  role_type=jwt \
  bound_claims='{"project_path":"TWOJA_GRUPA/TWOJ_PROJEKT","ref_type":"branch","ref":"main"}' \
  user_claim=sub \
  policies=gitlab-ci-policy \
  ttl=15m
```

Patrz: [gitlab-ci-example.yaml](./gitlab-ci-example.yaml)

## JWT Claims – co możesz weryfikować

### GitHub Actions claims

| Claim | Opis | Przykład |
|-------|------|---------|
| `sub` | Repo + ref | `repo:org/repo:ref:refs/heads/main` |
| `repository` | Pełna nazwa repo | `myorg/myrepo` |
| `ref` | Branch lub tag | `refs/heads/main` |
| `job_workflow_ref` | Workflow file | `myorg/myrepo/.github/workflows/deploy.yml@refs/heads/main` |
| `environment` | GitHub Environment | `production` |

### GitLab CI claims

| Claim | Opis | Przykład |
|-------|------|---------|
| `sub` | Unikalny identyfikator | `project_path:group/project:ref_type:branch:ref:main` |
| `project_path` | Ścieżka projektu | `mygroup/myproject` |
| `ref` | Branch/tag | `main` |
| `ref_type` | Typ ref | `branch` |
| `environment` | GitLab Environment | `production` |

## Najlepsze praktyki CI/CD + Vault

### 1. Krótkie TTL tokenów

```bash
# Maksymalnie 15-30 minut dla CI/CD
vault write auth/jwt/role/github-myrepo \
  ...
  ttl=15m \
  max_ttl=30m
```

### 2. Osobna rola per pipeline/środowisko

```bash
# DEV pipeline – dostęp do dev secrets
vault write auth/jwt/role/github-dev \
  bound_claims='{"environment":"development","repository":"myorg/myrepo"}' \
  policies=dev-secrets-policy \
  ttl=15m

# PROD pipeline – dostęp tylko z main branch + GitHub Environment "production"
vault write auth/jwt/role/github-prod \
  bound_claims='{"environment":"production","repository":"myorg/myrepo","ref":"refs/heads/main"}' \
  policies=prod-secrets-policy \
  ttl=10m
```

### 3. Odwołuj token po zakończeniu

```bash
# Na końcu każdego pipeline (GitHub Actions):
- name: Revoke Vault Token
  if: always()
  run: vault token revoke -self
  env:
    VAULT_ADDR: ${{ vars.VAULT_ADDR }}
    VAULT_TOKEN: ${{ steps.secrets.outputs.token }}
```

### 4. Nie loguj sekretów

GitHub Actions automatycznie maskuje zmienne z krokuu `vault-action`. GitLab CI maskuje zmienne z prefixem `CI_*` lub oznaczone jako "Masked".

## Weryfikacja

```bash
# JWT Auth włączony
vault auth list | grep jwt

# Role skonfigurowane
vault list auth/jwt/role

# Testowe logowanie z JWT (symulacja)
# vault write auth/jwt/login role=github-myrepo jwt=<token>

# Polityki dostępne
vault policy list | grep -E "github|gitlab"
```

## Scenariusz pełny – GitHub Actions

1. Workflow startuje → GitHub generuje OIDC token dla tego workflow
2. `hashicorp/vault-action` wysyła token do Vault
3. Vault weryfikuje token (bound_claims: repo + branch)
4. Vault zwraca sekrety bezpośrednio jako env vars
5. Sekrety zamaskowane w logach (`***`)
6. Token wygasa po 15 minutach

Patrz pełny przykład: [github-actions-example.yaml](./github-actions-example.yaml)
