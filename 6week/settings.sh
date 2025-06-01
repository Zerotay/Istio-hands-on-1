kind create cluster --config kind.yaml
istioctl install -f initstio.yaml -y 

helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm install metrics-server metrics-server/metrics-server --set 'args[0]=--kubelet-insecure-tls' -n kube-system


kubectl create ns istioinaction
kubectl label namespace istioinaction istio-injection=enabled
kubectl ns istioinaction

kubectl apply -f debug.yaml
kubectl apply -f addons


kubectl apply -f services/catalog/kubernetes/catalog.yaml -n istioinaction
kubectl apply -f ch10/catalog-deployment-v2.yaml -n istioinaction 
kubectl apply -f ch10/catalog-gateway.yaml -n istioinaction
kubectl apply -f ch10/catalog-virtualservice-subsets-v1-v2.yaml -n istioinaction
