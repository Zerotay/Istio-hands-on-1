###############################################################################
# Tap filter
###############################################################################
kaf ch14/tap-envoy-filter.yaml
#istioctl proxy-config listener deploy/webapp.istioinaction --port 15006 -o json

# Termianl 1: Connect to the tap stream
kubectl port-forward -n istioinaction deploy/webapp 15000 &
curl -X POST -d @./ch14/tap-config.json localhost:15000/tap

# Terminal 2: Check log
docker exec -it myk8s-control-plane istioctl proxy-config log deploy/webapp -n istioinaction --level http:debug
docker exec -it myk8s-control-plane istioctl proxy-config log deploy/webapp -n istioinaction --level tap:debug
kubectl logs -n istioinaction -l app=webapp -c istio-proxy -f

# Terminal 3: Test
EXT_IP=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
de curl -s -H "Host: webapp.istioinaction.io" http://$EXT_IP/api/catalog
de curl -s -H "x-app-tap: true" -H "Host: webapp.istioinaction.io" http://$EXT_IP/api/catalog
#while true; do docker exec -it mypc curl -s -H "x-app-tap: true" -H "Host: webapp.istioinaction.io" http://$EXT_IP/api/catalog ; echo ; date "+%Y-%m-%d %H:%M:%S" ; sleep 1; echo; done

###############################################################################
# rate limitting filter
###############################################################################
kubectl apply -f ch14/rate-limit/rlsconfig.yaml -n istioinaction
kubectl apply -f ch14/rate-limit/rls.yaml -n istioinaction
kubectl apply -f ch14/rate-limit/catalog-ratelimit.yaml -n istioinaction
kubectl apply -f ch14/rate-limit/catalog-ratelimit-actions.yaml -n istioinaction

# test
kubectl exec -ti -n istioinaction debug -- curl http://catalog/items -v
kubectl exec -ti -n istioinaction debug -- curl -H "x-loyalty: silver" http://catalog/items -v
kubectl exec -ti -n istioinaction debug -- curl -H "x-loyalty: gold"
kubectl exec -ti -n istioinaction debug --  curl -s -o /dev/null -w "%{http_code}" http://catalog/items

for i in {1..10};
do
  kubectl exec -ti -n istioinaction debug -- curl -s -o /dev/null -w "%{http_code}\n" http://catalog/items
  sleep 0.5
done | sort | uniq -c

for i in {1..10};
do
  kubectl exec -ti -n istioinaction debug -- curl -s -o /dev/null -w "%{http_code}\n" -H "x-loyalty: silver" http://catalog/items
  sleep 0.5
done | sort | uniq -c

for i in {1..10};
do
  kubectl exec -ti -n istioinaction debug -- curl -s -o /dev/null -w "%{http_code}\n" -H "x-loyalty: gold" http://catalog/items
  sleep 0.5
done | sort | uniq -c
###############################################################################
# Delete all
###############################################################################
kubectl delete envoyfilter -n istioinaction --all
kubectl delete -f ch14/rate-limit/rlsconfig.yaml -n istioinaction
kubectl delete -f ch14/rate-limit/rls.yaml -n istioinaction