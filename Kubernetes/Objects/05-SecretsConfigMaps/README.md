## Secrets i ConfigMaps

### Secrets
Secret w Kubernetes to obiekt przechowujący poufne dane, takie jak hasła, tokeny OAuth, klucze SSH itp. Jest to bezpieczniejszy sposób przechowywania tych danych niż bezpośrednio w plikach manifestów YAML.

#### Tworzenie Secret
Secret można utworzyć na kilka sposobów, na przykład za pomocą polecenia `kubectl`:

1. Tworzenie Secret z danych literalnych:
   ```sh
   kubectl create secret generic <nazwa-secreta> --from-literal=<klucz>=<wartość>
   ```
#### Rodzaje Secret
W Kubernetes istnieje kilka rodzajów Secret, które można utworzyć w zależności od potrzeb:

1. **Opaque**: Domyślny typ Secret, który przechowuje dane w postaci par klucz-wartość.
   ```sh
   kubectl create secret generic <nazwa-secreta> --from-literal=<klucz>=<wartość>
   ```

2. **docker-registry**: Secret używany do przechowywania danych logowania do prywatnych rejestrów Docker.
   ```sh
   kubectl create secret docker-registry <nazwa-secreta> \
     --docker-username=<nazwa-użytkownika> \
     --docker-password=<hasło> \
     --docker-email=<email> \
     --docker-server=<adres-serwera>
   ```

3. **tls**: Secret używany do przechowywania certyfikatów TLS.
   ```sh
   kubectl create secret tls <nazwa-secreta> \
     --cert=<ścieżka-do-pliku-cert> \
     --key=<ścieżka-do-pliku-key>
   ```

4. **service-account-token**: Secret automatycznie tworzony przez Kubernetes dla konta serwisowego, zawierający token dostępu.
   ```sh
   kubectl create secret service-account-token <nazwa-secreta>
   ```

### ConfigMaps
ConfigMap w Kubernetes to obiekt przechowujący dane konfiguracyjne w postaci par klucz-wartość. Umożliwia to oddzielenie konfiguracji od kodu aplikacji.

#### Tworzenie ConfigMap
ConfigMap można utworzyć na kilka sposobów, na przykład za pomocą polecenia `kubectl`:

1. Tworzenie ConfigMap z pliku:
   ```sh
   kubectl create configmap <nazwa-configmap> --from-file=<ścieżka-do-pliku>
   ```
#### Rodzaje ConfigMap
W Kubernetes istnieje kilka sposobów tworzenia ConfigMap, w zależności od źródła danych:

1. **Z pliku**: ConfigMap tworzony z zawartości pliku.
   ```sh
   kubectl create configmap <nazwa-configmap> --from-file=<ścieżka-do-pliku>
   ```

2. **Z katalogu**: ConfigMap tworzony z zawartości wszystkich plików w katalogu.
   ```sh
   kubectl create configmap <nazwa-configmap> --from-file=<ścieżka-do-katalogu>
   ```

3. **Z danych literalnych**: ConfigMap tworzony z par klucz-wartość podanych bezpośrednio w poleceniu.
   ```sh
   kubectl create configmap <nazwa-configmap> --from-literal=<klucz>=<wartość>
   ```

4. **Z pliku env**: ConfigMap tworzony z pliku w formacie zmiennych środowiskowych.
   ```sh
   kubectl create configmap <nazwa-configmap> --from-env-file=<ścieżka-do-pliku-env>
   ```