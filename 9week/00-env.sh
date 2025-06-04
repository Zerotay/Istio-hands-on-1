alias de='docker exec -ti mypc '
GWLB=$(kubectl get svc bookinfo-gateway-istio -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
