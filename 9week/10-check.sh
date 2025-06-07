################################################################################
# Default check
################################################################################
istioctl proxy-status
istioctl ztunnel-config workload
istioctl ztunnel-config service

# check daemonset config



################################################################################
# Ambient enabling
################################################################################

# check changes between labeling
kubectl label namespace default istio.io/dataplane-mode=ambient

kubectl label pod netshoot istio.io/dataplane-mode=none



################################################################################
# Waypoint
################################################################################
kubectl describe pod bookinfo-gateway-istio-6cbd9bcd49-6cphf | grep 'Service Account'

istioctl waypoint generate --for service
istioctl waypoint apply --for all

kubectl label ns default istio.io/use-waypoint=waypoint
################################################################################
# Observe
################################################################################
watch -d curl http://172.18.255.101/productpage -o /dev/null -v


################################################################################
# TC, Auth
################################################################################
kubectl label ns default istio.io/use-waypoint-

# 0. default

ADDRESS="reviews.default:9080/reviews/1"
#  ADDRESS="details.default:9080/details/1"
execute_test() {
  printf "\n--- curl from default debug ---\n"
  keti debug -- curl $ADDRESS
  printf "\n--- curl from default productpage ---\n"
  curl http://$GWLB/api/v1/products/1/reviews -s
  printf "\n--- curl from test debug ---\n"
  keti -n test debug -- curl $ADDRESS
}
execute_test

# 1. apply peer auth
kaf peer-authn-strict.yaml
execute_test
kdelf peer-authn-strict.yaml

# 2. apply l4 authz
kaf authz-l4.yaml
execute_test
kdelf authz-l4.yaml

# 3. apply l7 authz
kaf authz-l7.yaml
keti debug -- curl $ADDRESS -H "deny: true"
k label svc reviews istio.io/use-waypoint=waypoint
keti debug -- curl $ADDRESS -H "deny: true"

kdelf authz-l7.yaml

# 4. apply traffic control
kaf traffic-control.yaml
for i in {1..100};
do
  keti debug -- curl $ADDRESS | jq '.podname'
done | sort | uniq -c

for i in {1..100};
do
  keti -n test debug -- curl $ADDRESS | jq '.podname'
done | sort | uniq -c

cat <<EOF | kaf -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: test
spec:
  parentRefs:
  - name: bookinfo-gateway
  rules:
  - matches:
      - path:
          type: PathPrefix
          value: /reviews/1
    backendRefs:
      - name: reviews
        port: 9080
EOF

for i in {1..100};
do
  curl http://$GWLB/reviews/1 -s | jq '.podname'
done | sort | uniq -c

k delete httproutes test
kdelf traffic-control.yaml
