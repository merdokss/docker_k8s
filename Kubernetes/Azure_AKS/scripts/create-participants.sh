#!/bin/bash
set -euo pipefail

# Dostosuj listę uczestników przed uruchomieniem
PARTICIPANTS=("user01" "user02" "user03" "user04" "user05" \
              "user06" "user07" "user08" "user09" "user10")

for USER in "${PARTICIPANTS[@]}"; do
  echo "==> Tworzenie namespace: $USER"

  kubectl create namespace "$USER" --dry-run=client -o yaml | kubectl apply -f -

  kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota
  namespace: $USER
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "20"
    services: "10"
    persistentvolumeclaims: "5"
EOF

  echo "  $USER: gotowy"
done

echo ""
echo "Namespace'y uczestników:"
kubectl get namespaces | grep -E "$(IFS='|'; echo "${PARTICIPANTS[*]}")"
