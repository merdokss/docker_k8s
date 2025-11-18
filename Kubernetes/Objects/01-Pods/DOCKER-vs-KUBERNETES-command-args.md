# Różnica między nadpisywaniem ENTRYPOINT i CMD w Dockerze vs Kubernetes

## W Dockerze

### CMD - ŁATWO nadpisać ✅

```bash
# Obraz nginx ma: CMD ["nginx", "-g", "daemon off;"]

# Nadpisanie CMD - po prostu dodajesz argumenty na końcu:
docker run nginx echo "hello"
# To automatycznie nadpisuje CMD - nie potrzebujesz żadnej flagi!

# Inny przykład:
docker run nginx sh -c "ls -la"
# CMD jest nadpisany przez "sh -c ls -la"
```

**Dlaczego łatwo?** Docker automatycznie traktuje argumenty po nazwie obrazu jako nadpisanie CMD.

### ENTRYPOINT - TRUDNO nadpisać ❌

```bash
# Obraz nginx ma: ENTRYPOINT ["nginx"]

# Próba nadpisania jak CMD NIE DZIAŁA:
docker run nginx echo "hello"
# To NIE nadpisuje ENTRYPOINT! Uruchomi się: nginx echo "hello"
# (echo "hello" będzie argumentem dla nginx, nie nową komendą)

# Aby nadpisać ENTRYPOINT, MUSISZ użyć flagi --entrypoint:
docker run --entrypoint sh nginx -c "echo hello"
# Teraz ENTRYPOINT jest nadpisany na "sh"
```

**Dlaczego trudno?** Wymaga użycia specjalnej flagi `--entrypoint`.

## W Kubernetes

### Oba są RÓWNIE ŁATWE do nadpisania ✅

```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    # command nadpisuje ENTRYPOINT - równie łatwo jak args nadpisuje CMD
    command: ['sh', '-c']
    # args nadpisuje CMD
    args: ['echo "Hello from Kubernetes!"']
```

**Dlaczego łatwo?** Kubernetes ma dedykowane pola `command` i `args` - oba są równie łatwe do użycia.

## Porównanie

| Aspekt | Docker | Kubernetes |
|--------|--------|------------|
| **Nadpisanie CMD** | ✅ Łatwe - `docker run image <args>` | ✅ Łatwe - `args: [...]` |
| **Nadpisanie ENTRYPOINT** | ❌ Trudne - wymaga `--entrypoint` | ✅ Łatwe - `command: [...]` |
| **Spójność** | ❌ Różna trudność | ✅ Równa trudność |

## Przykłady praktyczne

### Docker - nadpisanie CMD
```bash
# Łatwe - bez flagi
docker run busybox echo "hello"
docker run nginx ls -la
```

### Docker - nadpisanie ENTRYPOINT
```bash
# Trudne - wymaga flagi
docker run --entrypoint sh busybox -c "echo hello"
docker run --entrypoint /bin/bash nginx -c "ls -la"
```

### Kubernetes - nadpisanie obu
```yaml
# Oba równie łatwe
spec:
  containers:
  - name: busybox
    image: busybox:latest
    command: ['sh', '-c']        # Nadpisuje ENTRYPOINT
    args: ['echo "hello"']       # Nadpisuje CMD
```

## Dlaczego ta różnica?

1. **Docker** - projektowany z myślą o prostocie użycia z linii komend
   - CMD był często używany, więc łatwe nadpisanie było priorytetem
   - ENTRYPOINT był dla "stałych" komend, więc nadpisanie było celowo utrudnione

2. **Kubernetes** - projektowany jako deklaratywny system
   - Wszystkie konfiguracje są w YAML
   - Oba pola (`command` i `args`) są równie dostępne
   - Brak potrzeby różnicowania trudności

## Wnioski

- **W Dockerze:** CMD łatwo, ENTRYPOINT trudno (wymaga `--entrypoint`)
- **W Kubernetes:** Oba łatwo (dedykowane pola `command` i `args`)
- **Dlatego** w Kubernetes nie ma problemu z nadpisywaniem ENTRYPOINT - jest równie łatwe jak CMD!

