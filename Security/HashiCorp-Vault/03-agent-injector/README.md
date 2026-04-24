# Ćwiczenie 03 – Vault Agent Sidecar Injector

## Cel ćwiczenia

Użyć Vault Agent Injector do automatycznego wstrzykiwania sekretów do podów jako pliki – bez żadnych zmian w kodzie aplikacji.

## Jak działa Agent Injector?

```
1. Tworzysz Deployment z annotacjami vault.hashicorp.com/*
2. Vault Agent Injector (MutatingWebhook) przechwyca tworzenie poda
3. Wstrzykuje dwa dodatkowe kontenery:
   - vault-agent-init (init container): pobiera sekrety przed startem aplikacji
   - vault-agent (sidecar): odświeża sekrety gdy się zmieniają
4. Sekrety dostępne jako pliki w /vault/secrets/
```

```
Pod po wstrzyknięciu:
┌─────────────────────────────────────────────┐
│                     Pod                     │
│                                             │
│  ┌──────────────┐   ┌────────────────────┐  │
│  │ vault-agent  │──▶│    app-container   │  │
│  │  (sidecar)   │   │                    │  │
│  └──────────────┘   └────────────────────┘  │
│         │                    │              │
│         ▼                    ▼              │
│    /vault/secrets/       /vault/secrets/    │
│    config (plik)         config (plik)      │
└─────────────────────────────────────────────┘
```

## Wymagania wstępne

- Ukończone ćwiczenia 01 i 02
- Vault Agent Injector zainstalowany (część Helm chart – domyślnie włączony)

```bash
# Sprawdź czy injector działa
kubectl get pods -n vault
# vault-agent-injector-* powinien być Running
```

## Krok 1 – Utwórz politykę Vault

```bash
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN=$(jq -r '.root_token' ../01-installation/vault-init.json)

vault policy write myapp-policy - <<'EOF'
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}
EOF
```

Lub uruchom skrypt:
```bash
chmod +x 02-vault-role.sh
./02-vault-role.sh
```

## Krok 2 – Wdróż aplikację z annotacjami

```bash
kubectl apply -f 03-deployment-with-agent.yaml

# Poczekaj na poda
kubectl rollout status deployment/myapp -n demo-app
```

## Krok 3 – Sprawdź wstrzyknięte sekrety

```bash
# Sprawdź kontenery w pode (powinny być 3: vault-agent, app, vault-agent-init)
kubectl get pods -n demo-app
kubectl describe pod -n demo-app -l app=myapp | grep -A 20 "Init Containers:"

# Odczytaj wstrzyknięty plik z sekretami
kubectl exec -n demo-app deployment/myapp -c app -- cat /vault/secrets/config

# Sprawdź logi vault-agent
kubectl logs -n demo-app -l app=myapp -c vault-agent
```

## Annotacje Vault Agent Injector

| Annotacja | Opis | Przykład |
|-----------|------|---------|
| `vault.hashicorp.com/agent-inject` | Włącz wstrzykiwanie | `"true"` |
| `vault.hashicorp.com/role` | Rola Vault | `"myapp"` |
| `vault.hashicorp.com/agent-inject-secret-<name>` | Ścieżka sekretu | `"secret/data/myapp/config"` |
| `vault.hashicorp.com/agent-inject-template-<name>` | Szablon pliku | `{{ with secret "..." }}...{{ end }}` |
| `vault.hashicorp.com/agent-pre-populate-only` | Tylko init (bez sidecar) | `"true"` |
| `vault.hashicorp.com/agent-inject-command-<name>` | Komenda po odświeżeniu | `"kill -HUP 1"` |

## Szablony (Templates)

Domyślnie Vault zapisuje sekret jako JSON. Możesz użyć szablonu HCL/Go do formatowania:

```yaml
annotations:
  vault.hashicorp.com/agent-inject-secret-config: "secret/data/myapp/config"
  vault.hashicorp.com/agent-inject-template-config: |
    {{- with secret "secret/data/myapp/config" -}}
    export DB_PASSWORD="{{ .Data.data.db_password }}"
    export API_KEY="{{ .Data.data.api_key }}"
    {{- end }}
```

Wynik w `/vault/secrets/config`:
```bash
export DB_PASSWORD="supersecret-from-vault"
export API_KEY="vault-api-key-123"
```

Aplikacja może załadować: `source /vault/secrets/config`

## Ćwiczenie dodatkowe – Rotacja sekretów

```bash
# Zmień wartość sekretu w Vault
vault kv put secret/myapp/config \
  db_password="rotated-password-456" \
  api_key="new-api-key-xyz"

# Agent sidecar automatycznie pobierze nową wersję (po TTL/lease)
# Sprawdź zaktualizowany plik
kubectl exec -n demo-app deployment/myapp -c app -- cat /vault/secrets/config

# Aby wymusić reload, możesz skonfigurować agent-inject-command:
# vault.hashicorp.com/agent-inject-command-config: "kill -HUP 1"
```

## Weryfikacja

```bash
# Plik sekretów dostępny wewnątrz poda
kubectl exec -n demo-app deployment/myapp -c app -- ls -la /vault/secrets/
# total 8
# -rw-r--r-- config

# Zawartość pliku (format JSON domyślnie lub szablon Go)
kubectl exec -n demo-app deployment/myapp -c app -- cat /vault/secrets/config

# Vault Agent działa jako sidecar
kubectl get pods -n demo-app -o jsonpath='{.items[*].spec.containers[*].name}'
# vault-agent app
```

## Kiedy używać Agent Injector?

**Zalety:**
- Zero zmian w kodzie aplikacji
- Automatyczna rotacja sekretów
- Obsługa dynamicznych sekretów (database, etc.)

**Wady:**
- Dodatkowy sidecar container = więcej zasobów
- Sekrety jako pliki (nie env vars bezpośrednio)
- Wolniejszy start poda (init container)

**Rekomendacja:** Legacy aplikacje, migracja z innych rozwiązań, gdy nie możesz modyfikować kodu.
