# Porównanie opcji Ingress na Azure Kubernetes Service (AKS)

## Szybkie porównanie - tabela

| Kryterium | NGINX Ingress | Application Gateway (AGIC) | Web App Routing | Traefik | Istio Gateway |
|-----------|---------------|----------------------------|-----------------|---------|---------------|
| **Koszt** | Darmowy (open-source) | ~150-300 USD/mc | Darmowy | Darmowy | Darmowy |
| **Łatwość instalacji** | ⭐⭐⭐ Średnia | ⭐⭐⭐⭐ Łatwa | ⭐⭐⭐⭐⭐ Bardzo łatwa | ⭐⭐⭐ Średnia | ⭐⭐ Trudna |
| **Zarządzanie** | Samodzielne | Managed by Azure | Managed by Azure | Samodzielne | Samodzielne |
| **Wydajność** | Wysoka | Bardzo wysoka | Wysoka | Wysoka | Wysoka |
| **SSL/TLS** | Tak (cert-manager) | Tak (natywne) | Tak (automatyczne) | Tak | Tak |
| **WAF** | Wymaga ModSecurity | Tak (natywnie) | Nie | Wymaga pluginów | Wymaga dodatków |
| **Autoskalowanie** | HPA | Tak (natywnie) | HPA | HPA | HPA |
| **Popularne w produkcji** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ (nowe) | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Dokumentacja** | Doskonała | Dobra | Dobra | Dobra | Bardzo dobra |
| **Azure Integration** | Podstawowa | Pełna | Pełna | Podstawowa | Podstawowa |

---

## 1. NGINX Ingress Controller

### Opis
Najbardziej popularny i sprawdzony Ingress Controller w świecie Kubernetes. Open-source, elastyczny i szeroko wspierany przez społeczność.

### Kiedy wybrać?
- ✅ Standardowe projekty bez specyficznych wymagań Azure
- ✅ Potrzebujesz maksymalnej elastyczności konfiguracji
- ✅ Masz doświadczenie z NGINX
- ✅ Chcesz uniknąć vendor lock-in
- ✅ Budżet jest ograniczony

### Instalacja
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

### Plusy
- ✅ Darmowy i open-source
- ✅ Ogromna społeczność i wsparcie
- ✅ Bardzo elastyczny (annotations, custom configs)
- ✅ Działa wszędzie (nie tylko Azure)
- ✅ Doskonała dokumentacja i przykłady
- ✅ Rate limiting, authentication, rewrites

### Minusy
- ❌ Wymaga samodzielnego zarządzania i update'ów
- ❌ SSL certyfikaty musisz skonfigurować (cert-manager)
- ❌ Brak natywnej integracji z Azure WAF
- ❌ Monitoring wymaga dodatkowej konfiguracji

### Typowy use case
Aplikacje które mogą działać w dowolnej chmurze, startupy, projekty z ograniczonym budżetem.

---

## 2. Application Gateway Ingress Controller (AGIC)

### Opis
Natywne rozwiązanie Azure - wykorzystuje Azure Application Gateway jako Ingress. Fully managed przez Azure.

### Kiedy wybrać?
- ✅ Masz budżet i chcesz "managed solution"
- ✅ Potrzebujesz WAF (Web Application Firewall)
- ✅ Wymagane są compliance i security na poziomie enterprise
- ✅ Aplikacja jest ściśle związana z Azure
- ✅ Potrzebujesz SSL offloading poza klastrem

### Instalacja
```bash
# Podczas tworzenia klastra
az aks create \
  --enable-addons ingress-appgw \
  --appgw-name myAppGateway \
  --appgw-subnet-cidr 10.225.0.0/16

# Lub dodanie do istniejącego
az aks enable-addons \
  --addons ingress-appgw \
  --appgw-id <gateway-id>
```

### Plusy
- ✅ Fully managed przez Azure
- ✅ Natywny WAF (Web Application Firewall)
- ✅ Automatyczne SSL/TLS z Azure Key Vault
- ✅ Native autoskalowanie Application Gateway
- ✅ Integracja z Azure Monitor
- ✅ SSL offloading poza klastrem
- ✅ Zone redundancy

### Minusy
- ❌ Kosztowne (~150-300 USD/miesiąc za AppGW)
- ❌ Vendor lock-in (działa tylko na Azure)
- ❌ Mniej elastyczne niż NGINX
- ❌ Ograniczona konfiguracja przez annotations
- ❌ Wolniejsze zmiany konfiguracji (ARM deployments)

### Typowy use case
Enterprise aplikacje, finansowe, healthcare - tam gdzie bezpieczeństwo i compliance są priorytetem.

---

## 3. Web Application Routing (Managed NGINX)

### Opis
Najnowszy add-on od Microsoft - to zarządzany NGINX z automatyczną konfiguracją DNS i certyfikatów. Łączy zalety NGINX z "managed" podejściem.

### Kiedy wybrać?
- ✅ Chcesz prostoty bez kosztów Application Gateway
- ✅ Potrzebujesz automatycznego zarządzania certyfikatami
- ✅ Zależy Ci na szybkim starcie
- ✅ Projekty developerskie i testowe
- ✅ Chcesz NGINX bez maintenance'u

### Instalacja
```bash
az aks approuting enable \
  --resource-group myResourceGroup \
  --name myAKSCluster
```

### Plusy
- ✅ Darmowy (płacisz tylko za zasoby klastra)
- ✅ Bardzo łatwa instalacja i konfiguracja
- ✅ Automatyczne certyfikaty (Let's Encrypt)
- ✅ Automatyczna integracja z Azure DNS
- ✅ Zarządzany przez Azure (auto-updates)
- ✅ Bazuje na sprawdzonym NGINX

### Minusy
- ❌ Stosunkowo nowe rozwiązanie (mniej battle-tested)
- ❌ Mniej opcji konfiguracji niż czysty NGINX
- ❌ Brak WAF
- ❌ Ograniczona kontrola nad NGINX config

### Typowy use case
Nowoczesne aplikacje na Azure, gdzie chcesz balansu między prostotą a kontrolą. Idealne dla szkoleń!

---

## 4. Traefik

### Opis
Nowoczesny reverse proxy i load balancer stworzony z myślą o microservices i Kubernetes. Cloud-native design.

### Kiedy wybrać?
- ✅ Lubisz nowoczesne narzędzia
- ✅ Potrzebujesz dynamicznej konfiguracji
- ✅ Chcesz ładny dashboard
- ✅ Pracujesz z microservices
- ✅ Potrzebujesz TCP/UDP routing

### Instalacja
```bash
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace
```

### Plusy
- ✅ Darmowy i open-source
- ✅ Ładny Web UI / Dashboard
- ✅ Automatyczne wykrywanie zmian
- ✅ Dobra dokumentacja
- ✅ Nowoczesna architektura
- ✅ Wsparcie dla TCP/UDP
- ✅ Middleware (auth, rate limit, etc.)

### Minusy
- ❌ Mniejsza społeczność niż NGINX
- ❌ Wymaga samodzielnego zarządzania
- ❌ Mniej tutoriali i przykładów
- ❌ Własna terminologia (trzeba się nauczyć)

### Typowy use case
Nowoczesne mikroservisy, zespoły które lubią próbować nowych technologii, projekty z wymaganiami TCP/UDP.

---

## 5. Istio Ingress Gateway

### Opis
Część większego systemu - Istio Service Mesh. Ingress to tylko fragment funkcjonalności. Używany gdy potrzebujesz pełnego service mesh.

### Kiedy wybrać?
- ✅ Potrzebujesz pełnego service mesh
- ✅ Zaawansowane routing policies
- ✅ Mutual TLS między serwisami
- ✅ Distributed tracing out-of-the-box
- ✅ Zaawansowane security policies
- ✅ Duże środowiska microservices

### Instalacja
```bash
istioctl install --set profile=demo
kubectl label namespace default istio-injection=enabled
```

### Plusy
- ✅ Część pełnego service mesh
- ✅ Zaawansowany traffic management
- ✅ Mutual TLS automatycznie
- ✅ Observability (Kiali, Jaeger, Grafana)
- ✅ Circuit breaking, retries, timeouts
- ✅ A/B testing, canary deployments

### Minusy
- ❌ Najbardziej skomplikowane rozwiązanie
- ❌ Duży overhead (sidecary w każdym podzie)
- ❌ Długa krzywa uczenia
- ❌ Wymaga więcej zasobów
- ❌ Overkill dla prostych aplikacji

### Typowy use case
Duże środowiska microservices (50+ serwisów), aplikacje wymagające zaawansowanego security i observability.

---

## Decyzja - które wybrać?

### 🎯 Dla szkoleń i nauki
**Web Application Routing** - najszybszy start, wszystko działa "out of the box"

### 💼 Dla małych/średnich projektów
**NGINX Ingress** - sprawdzony, elastyczny, darmowy, działa wszędzie

### 🏢 Dla Enterprise z budżetem
**Application Gateway (AGIC)** - gdy potrzebujesz WAF, compliance, i managed solution

### 🚀 Dla nowoczesnych projektów
**Traefik** - jeśli lubisz nowoczesne narzędzia i ładny UI

### 🎓 Dla zaawansowanych (service mesh)
**Istio** - gdy potrzebujesz pełnego service mesh, nie tylko Ingress

---

## Porównanie kosztów (miesięcznie dla małego klastra)

| Rozwiązanie | Koszt infrastruktury | Koszt zarządzania (czas) | Całkowity koszt |
|-------------|---------------------|--------------------------|-----------------|
| NGINX | $0 | ~2-4h/mc (updates) | ~$0-200 |
| App Gateway | $150-300 | ~1h/mc | ~$150-400 |
| Web App Routing | $0 | ~0-1h/mc | ~$0-50 |
| Traefik | $0 | ~2-4h/mc | ~$0-200 |
| Istio | $0 | ~8-16h/mc (complexity) | ~$0-800 |

*Koszty zarządzania wycenione jako 50 USD/h inżyniera DevOps*

---

## Moja rekomendacja według scenariusza

### Scenariusz 1: "Uczę się Kubernetes"
→ **Web Application Routing** - zacznij od tego, potem naucz się NGINX

### Scenariusz 2: "Startup, MVP, ograniczony budżet"
→ **NGINX Ingress** - sprawdzony, darmowy, przenośny

### Scenariusz 3: "Korporacja, compliance, bezpieczeństwo"
→ **Application Gateway** - WAF, managed, Azure support

### Scenariusz 4: "Multi-cloud strategy"
→ **NGINX Ingress** - działa wszędzie tak samo

### Scenariusz 5: "100+ microservices"
→ **Istio** - ale tylko jeśli naprawdę potrzebujesz service mesh

