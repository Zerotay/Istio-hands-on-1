alias kwest='kubectl --kubeconfig=./west-kubeconfig'
alias keast='kubectl --kubeconfig=./east-kubeconfig'
alias iwest='docker exec -it west-control-plane istioctl'
alias ieast='docker exec -it east-control-plane istioctl'
alias de='docker exec -ti mypc '


# loadbalacner ip
#JAEGER=$(kwest get svc -n istio-system  -ojsonpath="{.status.loadBalancer.ingress[0].ip}")
echo "JAEGER"
kwest -n istio-system get svc jaeger-inmemory-instance-collector -o go-template='
{{- (index .status.loadBalancer.ingress 0).ip -}}: {{- (index .spec.ports 0).port -}}
'
echo "$JAEGER"

echo "KIALI"
kwest -n istio-system get svc kiali -o go-template='
{{- (index .status.loadBalancer.ingress 0).ip -}}: {{- (index .spec.ports 0).port }}
'

#kwest -n istio-system get svc kiali -o go-template='
#{{- range $k, $v := .status -}}
#{{$k}} {{$v}}
#{{end -}}
#'

