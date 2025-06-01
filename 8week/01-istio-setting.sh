################################################################################
# Alias for convinient
################################################################################
alias kubectl='kubectl --kubeconfig ./kubeconfig'
alias istioctl='istioctl --kubeconfig ./kubeconfig'
FORUM=$(terraform -chdir=infra-terraform output -json | yq '.vm_ip.value')
APP_IP=$(terraform -chdir=infra-terraform output -json | yq '.cluster_ip.value')

################################################################################
# Install default istio
################################################################################
kubectl create namespace istio-system
kubectl label namespace istio-system topology.istio.io/network=west-network
#istioctl install -f ch13/controlplane/cluster-in-west-network.yaml --set values.global.proxy.privileged=true -y
istioctl install -f ch13/controlplane/cluster-in-west-network-with-vm-features.yaml --set values.global.proxy.privileged=true -y
kubectl apply -f addons
kubectl create ns istioinaction
kubectl label namespace istioinaction istio-injection=enabled
# All enpoints needs to be the NodePort Service because we use K3s.
kubectl patch svc -n istio-system istio-ingressgateway -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 8080, "nodePort": 30000}]}}'
kubectl patch svc -n istio-system istio-ingressgateway -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8443, "nodePort": 30005}]}}'
kubectl patch svc -n istio-system istio-ingressgateway -p '{"spec": {"type": "NodePort", "externalTrafficPolicy": "Local"}}'
kubectl patch svc -n istio-system prometheus -p '{"spec": {"type": "NodePort", "ports": [{"port": 9090, "targetPort": 9090, "nodePort": 30001}]}}'
kubectl patch svc -n istio-system grafana -p '{"spec": {"type": "NodePort", "ports": [{"port": 3000, "targetPort": 3000, "nodePort": 30002}]}}'
kubectl patch svc -n istio-system kiali -p '{"spec": {"type": "NodePort", "ports": [{"port": 20001, "targetPort": 20001, "nodePort": 30003}]}}'
kubectl patch svc -n istio-system tracing -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 16686, "nodePort": 30004}]}}'

kubectl -n istioinaction apply -f ch12/webapp-deployment-svc.yaml
kubectl -n istioinaction apply -f ch12/webapp-gw-vs.yaml
kubectl -n istioinaction apply -f ch12/catalog.yaml

################################################################################
# Prepare Istio for VM
################################################################################
# Set Istiod
#istioctl install -f ch13/controlplane/cluster-in-west-network-with-vm-features.yaml --set values.global.proxy.privileged=true -y
# Deploy east-west gateway
istioctl install -f ch13/gateways/cluster-east-west-gw.yaml --set meshConfig.accessLogFile=/dev/stdout -y
#istioctl install -f ch13/gateways/cluster-east-west-gw.yaml -y
kubectl apply -f ch13/expose-services.yaml
kubectl apply -f ch13/expose-istiod.yaml -n istio-system