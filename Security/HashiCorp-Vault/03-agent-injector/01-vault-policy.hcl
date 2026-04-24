# Polityka Vault dla aplikacji myapp
# Dostęp tylko do odczytu sekretów w ścieżce secret/myapp/*

path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/myapp/*" {
  capabilities = ["read", "list"]
}

# Brak dostępu do sekretów innych aplikacji
# path "secret/data/otherapp/*" { } -- zabronione (domyślnie)
