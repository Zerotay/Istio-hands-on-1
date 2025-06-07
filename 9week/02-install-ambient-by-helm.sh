################################################################################
# Install Istio Ambient
################################################################################
helm repo add istio https://istio-release.storage.googleapis.com/charts
#helm repo update

helm install istio-base istio/base -n istio-system --create-namespace --wait --set meshConfig.accessLogFile=/dev/stdout --set variant=debug
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
helm install istiod istio/istiod --namespace istio-system --set profile=ambient --wait  --set variant=debug
# If there's too much resource used during installing istio-cni, the pod for the master node fails.
# Error says there's too many open files, and once it starts to fail, it never recovered.
sleep 10
helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait --set variant=debug
helm install ztunnel istio/ztunnel -n istio-system --wait --set variant=debug


################################################################################
# Install Observability tools
################################################################################
kubectl apply -f samples/addons
kubectl patch svc -n istio-system prometheus -p '{"spec": {"type": "NodePort", "ports": [{"port": 9090, "targetPort": 9090, "nodePort": 30001}]}}'
kubectl patch svc -n istio-system grafana -p '{"spec": {"type": "NodePort", "ports": [{"port": 3000, "targetPort": 3000, "nodePort": 30002}]}}'
kubectl patch svc -n istio-system kiali -p '{"spec": {"type": "NodePort", "ports": [{"port": 20001, "targetPort": 20001, "nodePort": 30003}]}}'
kubectl patch svc -n istio-system tracing -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 16686, "nodePort": 30004}]}}'

kubectl apply -f bookinfo.yaml
#kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/gateway-api/bookinfo-gateway.yaml

kubectl apply -f debug.yaml
k create ns test
kubectl apply -f debug.yaml -n test

GWLB=$(kubectl get svc bookinfo-gateway-istio -o jsonpath='{.status.loadBalancer.ingress[0].ip}')



