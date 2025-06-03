
alias de='docker exec -ti mypc '

###############################################################################
# Kreate
###############################################################################
kind create cluster --name myk8s --image kindest/node:v1.32.2 --config - <<EOF
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

###############################################################################
# MetalLB
###############################################################################
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


###############################################################################
# Install Istio
###############################################################################
cat << EOF | istioctl install -f - -y
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio-controlplane
  namespace: istio-system
spec:
  profile: default
  meshConfig:
    enableTracing: true
    defaultProviders:
      metrics:
        - prometheus
      tracing: []
    trustDomain: cluster.local
    discoverySelectors:
      - matchExpressions:
        - key: "kubernetes.io/metadata.name"
          operator: In
          values:
            - "istioinaction"
            - "istio-system"
  values:
    global:
      proxy:
        privileged: true
  components:
    pilot:
      k8s:
        env:
          - name: ENABLE_NATIVE_SIDECARS
            value: "true"
    egressGateways:
    - name: istio-egressgateway
      enabled: false
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        service:
          ports:
          - name: http
            port: 80
            targetPort: 8080
            nodePort: 30000
          - name: https
            port: 443
            targetPort: 8443
            nodePort: 30005
          externalTrafficPolicy: Local
EOF

kubectl apply -f addons

kubectl patch svc -n istio-system prometheus -p '{"spec": {"type": "NodePort", "ports": [{"port": 9090, "targetPort": 9090, "nodePort": 30001}]}}'
kubectl patch svc -n istio-system grafana -p '{"spec": {"type": "NodePort", "ports": [{"port": 3000, "targetPort": 3000, "nodePort": 30002}]}}'
kubectl patch svc -n istio-system kiali -p '{"spec": {"type": "NodePort", "ports": [{"port": 20001, "targetPort": 20001, "nodePort": 30003}]}}'
kubectl patch svc -n istio-system tracing -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 16686, "nodePort": 30004}]}}'

kubectl create ns istioinaction
kubectl label ns istioinaction istio-injection=enabled
kubectl apply -f debug.yaml -n istioinaction
kubectl apply -f services/catalog/kubernetes/catalog.yaml -n istioinaction
kubectl apply -f services/webapp/kubernetes/webapp.yaml -n istioinaction
kubectl apply -f services/webapp/istio/webapp-catalog-gw-vs.yaml -n istioinaction

