kind create cluster --name myk8s --image kindest/node:v1.32.2 --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000 # Sample Application
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
  extraMounts:
  - hostPath: ./pcap
    containerPath: /pcap
- role: worker
  extraMounts:
  - hostPath: ./pcap
    containerPath: /pcap
- role: worker
  extraMounts:
  - hostPath: ./pcap
    containerPath: /pcap
networking:
  podSubnet: 10.10.0.0/16
  serviceSubnet: 10.200.1.0/24
EOF

#for node in control-plane worker worker2; do echo "node : myk8s-$node" ; docker exec -it myk8s-$node sh -c 'apt update && apt install tree psmisc lsof ipset wget bridge-utils net-tools dnsutils tcpdump ngrep iputils-ping git vim -y'; echo; done

# external client
docker run -d --rm --name mypc --network kind nicolaka/netshoot sleep infinity

# MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
kubectl -n metallb-system wait --for condition=available  deployment controller --timeout=60s
cat << EOF | kubectl apply -f -
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


alias de='docker exec -ti mypc '
