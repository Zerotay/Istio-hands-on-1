# east
kind create cluster --name east --image kindest/node:v1.32.2 --kubeconfig ./east-kubeconfig --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 31000 # istio-ingrssgateway HTTP
    hostPort: 31000
  - containerPort: 31001 # Prometheus
    hostPort: 31001
  - containerPort: 31002 # Grafana
    hostPort: 31002
  - containerPort: 31003 # Kiali
    hostPort: 31003
  - containerPort: 31004 # Tracing
    hostPort: 31004
  - containerPort: 31005 # kube-ops-view
    hostPort: 31005
networking:
  podSubnet: 10.20.0.0/16
  serviceSubnet: 10.200.0.0/24
EOF
# west
kind create cluster --name west --image kindest/node:v1.32.2 --kubeconfig ./west-kubeconfig --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000 # istio-ingrssgateway HTTP
    hostPort: 30000
  - containerPort: 30001 # Prometheus
    hostPort: 30001
  - containerPort: 30002 # Grafana
    hostPort: 30002
  - containerPort: 30003 # Kiali
    hostPort: 30003
  - containerPort: 30004 # Tracing
    hostPort: 30004
  - containerPort: 30005 # kube-ops-view
    hostPort: 30005
networking:
  podSubnet: 10.10.0.0/16
  serviceSubnet: 10.100.0.0/24
EOF
# external client
docker run -d --rm --name mypc --network kind nicolaka/netshoot sleep infinity

# MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml \
  --kubeconfig=./west-kubeconfig
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml \
  --kubeconfig=./east-kubeconfig
kubectl -n metallb-system wait --for condition=available  deployment controller --kubeconfig=./west-kubeconfig --timeout=60s
kubectl -n metallb-system wait --for condition=available  deployment controller --kubeconfig=./east-kubeconfig --timeout=60s
cat << EOF | kubectl apply --kubeconfig=./west-kubeconfig -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - 172.18.255.101-172.18.255.120
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
EOF

cat << EOF | kubectl apply --kubeconfig=./east-kubeconfig -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - 172.18.255.201-172.18.255.220
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
EOF

alias kwest='kubectl --kubeconfig=./west-kubeconfig'
alias keast='kubectl --kubeconfig=./east-kubeconfig'
alias iwest='docker exec -it west-control-plane istioctl'
alias ieast='docker exec -it east-control-plane istioctl'
alias iwest='istioctl --kubeconfig=./west-kubeconfig'
alias ieast='istioctl --kubeconfig=./east-kubeconfig'
alias de='docker exec -ti mypc '


# default
kwest create ns istioinaction
kwest label ns istioinaction istio-injection=enabled
kwest create ns istio-system
kwest label namespace istio-system topology.istio.io/network=west-network

keast create ns istioinaction
keast label ns istioinaction istio-injection=enabled
keast create ns istio-system
keast label namespace istio-system topology.istio.io/network=east-network
