helm repo add hashicorp https://helm.releases.hashicorp.com

helm upgrade vault hashicorp/vault \
  --install -n vault --create-namespace \
  -f values-vault.yaml \
  --kubeconfig ./west-kubeconfig

# Vault won't be ready unless you unseal it, just take enough time to wait for initial process
sleep 25
echo "Wait for the pod up"

kwest exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 \
      -format=json > init-keys.json

alias vault="kubectl --kubeconfig ./west-kubeconfig -n vault exec vault-0 -- vault "
VAULT_UNSEAL_KEY=$(cat init-keys.json | jq -r ".unseal_keys_b64[]")
vault  operator unseal $VAULT_UNSEAL_KEY
VAULT_ROOT_TOKEN=$(cat init-keys.json | jq -r ".root_token")
vault  login $VAULT_ROOT_TOKEN

# check
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki

vault write pki/root/generate/internal \
    common_name=cluster.local \
    ttl=87600h -format=json | jq -r '.data.certificate' > CA.crt

vault write pki/config/urls \
    issuing_certificates="vault.vault.svc.cluster.local:8200/v1/pki/ca" \
    crl_distribution_points="vault.vault.svc.cluster.local:8200/v1/pki/crl"

# West cluster cert, auth
vault secrets enable -path=west-cluster pki
vault secrets tune -max-lease-ttl=87600h west-cluster
WEST_CSR=$(vault write -format=json west-cluster/intermediate/generate/internal \
    common_name="west-cluster" \
    | jq -r '.data.csr')
vault write -format=json pki/root/sign-intermediate csr="$WEST_CSR" \
    format=pem ttl="43800h" \
    | jq -r '.data.certificate' > west-cert.pem

cat west-cert.pem > west-chain.pem
cat CA.crt >> west-chain.pem
WEST_CHAIN=$(cat west-chain.pem)
vault write west-cluster/intermediate/set-signed certificate="$WEST_CHAIN"

vault write west-cluster/roles/west-cluster-role \
    allowed_domains=istio-ca \
    allow_subdomains=true \
    allow_any_name=true  \
    enforce_hostnames=false \
    require_cn=false \
    allowed_uri_sans="spiffe://*" \
    max_ttl=72h

# East cluster cert, auth
vault secrets enable -path=east-cluster pki
vault secrets tune -max-lease-ttl=87600h east-cluster
EAST_CSR=$(vault write -format=json east-cluster/intermediate/generate/internal \
    common_name="east-cluster" \
    | jq -r '.data.csr')
vault write -format=json pki/root/sign-intermediate csr=$EAST_CSR \
    format=pem ttl="43800h" \
    | jq -r '.data.certificate' > east-cert.pem

cat east-cert.pem > east-chain.pem
cat CA.crt >> east-chain.pem
EAST_CHAIN=$(cat east-chain.pem)
vault write east-cluster/intermediate/set-signed certificate=$EAST_CHAIN

vault write east-cluster/roles/east-cluster-role \
    allowed_domains=istio-ca \
    allow_subdomains=true \
    allow_any_name=true  \
    enforce_hostnames=false \
    require_cn=false \
    allowed_uri_sans="spiffe://*" \
    max_ttl=72h


rm CA.crt
rm *.pem


