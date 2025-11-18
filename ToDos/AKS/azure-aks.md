# 1. Stwórz ServiceAccount
`kubectl create serviceaccount external-user -n kube-system`

# 2. Nadaj uprawnienia cluster-admin (lub mniej jeśli potrzebujesz)
``
kubectl create clusterrolebinding external-user-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:external-user
``

# 3. Wygeneruj token
`kubectl apply -f ToDos/secret-aks.yaml`
`TOKEN=$(kubectl get secret external-user-token -n kube-system -o jsonpath='{.data.token}' | base64 -d)`

# 4. Pobierz dane klastra
``
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_CERT=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
CLUSTER_NAME="sages-aks"
``

# 5. Wygeneruj kubeconfig
```
cat > external-kubeconfig.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CA_CERT}
    server: ${SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: external-user
  name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
users:
- name: external-user
  user:
    token: ${TOKEN}
EOF
```
