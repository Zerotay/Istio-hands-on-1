helm repo add jetstack https://charts.jetstack.io
# west
helm install \
  cert-manager jetstack/cert-manager \
  --wait \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.2 \
  --set crds.enabled=true \
  --kubeconfig=./west-kubeconfig

cat << EOF | kubectl apply --kubeconfig=./west-kubeconfig -f -
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: cert-manager-vault-token
  namespace: istio-system
stringData:
  token: $VAULT_ROOT_TOKEN
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: istio-ca
#  name: vault
  namespace: istio-system
spec:
  vault:
    server: http://vault.vault.svc.cluster.local:8200
    path: west-cluster/sign/west-cluster-role
    auth:
      tokenSecretRef:
          name: cert-manager-vault-token
          key: token
EOF

cat << EOF | helm upgrade cert-manager-istio-csr jetstack/cert-manager-istio-csr \
  --install \
  --namespace istio-system \
  --wait \
  --kubeconfig=./west-kubeconfig -f -
app:
  server:
    clusterID: west-cluster
  runtimeConfiguration:
    create: true
    name: istio-issuer
    issuer:
      name: istio-ca
      kind: Issuer
      group: cert-manager.io
  tls:
#    trustDomain: "cluster.local"
    certificateDNSNames:
    - cert-manager-istio-csr.istio-system.svc
EOF

# east
helm install \
  cert-manager jetstack/cert-manager \
  --wait \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.2 \
  --set crds.enabled=true \
  --kubeconfig=./east-kubeconfig

VAULT_IP=$(kubectl --kubeconfig ./west-kubeconfig get svc -n vault vault -ojsonpath="{.status.loadBalancer.ingress[0].ip}")
cat << EOF | kubectl apply --kubeconfig=./east-kubeconfig -f -
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: cert-manager-vault-token
  namespace: istio-system
stringData:
  token: $VAULT_ROOT_TOKEN
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: istio-ca
  namespace: istio-system
spec:
  vault:
    server: http://$VAULT_IP:8200
    path: east-cluster/sign/east-cluster-role
    auth:
      tokenSecretRef:
          name: cert-manager-vault-token
          key: token
EOF


cat << EOF | helm upgrade cert-manager-istio-csr jetstack/cert-manager-istio-csr \
  --install \
  --namespace istio-system \
  --wait \
  --kubeconfig=./east-kubeconfig -f -
app:
  server:
    clusterID: east-cluster
  runtimeConfiguration:
    create: true
    name: istio-issuer
    issuer:
      name: istio-ca
      kind: Issuer
      group: cert-manager.io
  tls:
#    trustDomain: "cluster.local"
    certificateDNSNames:
    - cert-manager-istio-csr.istio-system.svc
EOF
