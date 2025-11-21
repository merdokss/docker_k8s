# MetalLB - Szybki Start

Krótki przewodnik instalacji i konfiguracji MetalLB w 5 minut.

---

## 🚀 Szybka instalacja (Layer 2)

### Krok 1: Zainstaluj MetalLB

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
```

Lub użyj skryptu:

```bash
chmod +x install.sh
./install.sh
```

### Krok 2: Sprawdź instalację

```bash
kubectl get pods -n metallb-system
# Oczekiwany wynik:
# NAME                          READY   STATUS    RESTARTS   AGE
# controller-xxx                1/1     Running   0          1m
# speaker-xxx                   1/1     Running   0          1m
```

### Krok 3: Skonfiguruj pulę IP

**WAŻNE:** Zmień zakres adresów IP na dostępne w Twojej sieci!

```bash
# Edytuj plik metallb-config-l2.yaml i zmień zakres adresów
# Następnie zastosuj konfigurację:
kubectl apply -f metallb-config-l2.yaml
```

Przykładowa konfiguracja (zmień adresy IP!):

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.240-192.168.1.250  # ZMIEŃ NA SWOJE ADRESY!
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - default-pool
```

### Krok 4: Przetestuj

```bash
# Utwórz testową usługę
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=LoadBalancer --port=80

# Sprawdź adres IP
kubectl get svc nginx
# NAME    TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
# nginx   LoadBalancer   10.96.123.45    192.168.1.240   80:30001/TCP   30s

# Przetestuj dostępność
curl http://192.168.1.240
```

---

## ✅ Checklist instalacji

- [ ] Kubernetes klaster działa (`kubectl cluster-info`)
- [ ] MetalLB zainstalowany (`kubectl get pods -n metallb-system`)
- [ ] Pula IP skonfigurowana (`kubectl get ipaddresspool -n metallb-system`)
- [ ] L2Advertisement utworzony (`kubectl get l2advertisement -n metallb-system`)
- [ ] Testowa usługa otrzymała EXTERNAL-IP (`kubectl get svc`)
- [ ] Usługa jest dostępna z zewnątrz (`curl http://<EXTERNAL-IP>`)

---

## 🔧 Rozwiązywanie problemów

### Usługa pozostaje w stanie `<pending>`

```bash
# Sprawdź czy MetalLB jest zainstalowany
kubectl get pods -n metallb-system

# Sprawdź konfigurację puli IP
kubectl get ipaddresspool -n metallb-system -o yaml

# Sprawdź logi
kubectl logs -n metallb-system -l app=metallb-controller
kubectl logs -n metallb-system -l app=metallb-speaker
```

### Brak dostępnych adresów IP

```bash
# Sprawdź ile adresów jest dostępnych
kubectl get ipaddresspool -n metallb-system -o yaml

# Zwiększ zakres adresów w puli
kubectl edit ipaddresspool default-pool -n metallb-system
```

### Adres IP przypisany, ale brak dostępu

```bash
# Sprawdź ARP
arp -a | grep <EXTERNAL-IP>

# Sprawdź który węzeł odpowiada
kubectl get nodes -o wide
kubectl logs -n metallb-system -l app=metallb-speaker | grep <EXTERNAL-IP>

# Sprawdź firewall
ping <EXTERNAL-IP>
```

---

## 📚 Dalsze kroki

- Przeczytaj pełną dokumentację: [README.md](README.md)
- Skonfiguruj BGP dla produkcji: `metallb-config-bgp.yaml`
- Zaawansowana konfiguracja: `metallb-config-advanced.yaml`
- Przykłady usług: `example-service.yaml`

---

## 🔗 Przydatne linki

- Oficjalna dokumentacja: https://metallb.io/
- GitHub: https://github.com/metallb/metallb
- Release notes: https://github.com/metallb/metallb/releases

