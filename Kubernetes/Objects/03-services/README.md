## NodePort

NodePort to typ usługi w Kubernetes, który umożliwia dostęp do aplikacji uruchomionych w klastrze Kubernetes z zewnątrz, poprzez otwarcie określonego portu na każdym węźle (node) w klastrze. NodePort działa jako rozszerzenie usługi typu ClusterIP, co oznacza, że usługa jest dostępna zarówno wewnątrz klastra, jak i z zewnątrz.

### Jak działa NodePort?

1. Kubernetes rezerwuje port z zakresu 30000-32767 na każdym węźle w klastrze.
2. Ruch przychodzący na ten port jest przekierowywany do odpowiedniego serwisu ClusterIP, a następnie do odpowiednich podów.
3. Użytkownicy mogą uzyskać dostęp do aplikacji, łącząc się z adresem IP dowolnego węzła w klastrze oraz z portem NodePort.

### Przykład definicji NodePort:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nodeport-service
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30001
```


## ClusterIP

ClusterIP to typ usługi w Kubernetes, który tworzy wewnętrzną usługę dostępną tylko wewnątrz klastra Kubernetes. Usługa ClusterIP jest dostępna tylko wewnątrz klastra i nie jest dostępna z zewnątrz.

### Jak działa ClusterIP?

1. Kubernetes tworzy wewnętrzną usługę dostępną tylko wewnątrz klastra.
2. Usługa ClusterIP jest dostępna tylko wewnątrz klastra i nie jest dostępna z zewnątrz.

### Przykład definicji ClusterIP:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-clusterip-service
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```


## LoadBalancer

LoadBalancer to typ usługi w Kubernetes, który tworzy zewnętrzną usługę dostępną z zewnątrz klastra. Usługa LoadBalancer jest dostępna z zewnątrz klastra i jest zwykle używana do wystawienia aplikacji na zewnątrz klastra.

### Jak działa LoadBalancer?

1. Kubernetes tworzy zewnętrzną usługę dostępną z zewnątrz klastra.
2. Usługa LoadBalancer jest dostępna z zewnątrz klastra i jest zwykle używana do wystawienia aplikacji na zewnątrz klastra.

### Przykład definicji LoadBalancer:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-loadbalancer-service
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```










