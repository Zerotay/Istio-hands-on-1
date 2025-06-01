cat << EOF | istioctl install --kubeconfig=./east-kubeconfig -f - -y
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
spec:
  meshConfig:
    accessLogFile: /dev/stdout
  profile: empty
  components:
    ingressGateways:
    - name: istio-eastwestgateway
      label:
        istio: eastwestgateway
        app: istio-eastwestgateway
        topology.istio.io/network: east-network
      enabled: true
      k8s:
        env:
        - name: ISTIO_META_ROUTER_MODE
          value: "sni-dnat"
        - name: ISTIO_META_REQUESTED_NETWORK_VIEW
          value: east-network
        service:
          ports:
          - name: status-port
            port: 15021
            targetPort: 15021
          - name: mtls
            port: 15443
            targetPort: 15443
          - name: tcp-istiod
            port: 15012
            targetPort: 15012
          - name: tcp-webhook
            port: 15017
            targetPort: 15017
  values:
    global
      meshID: usmesh
      multiCluster:
        clusterName: east-cluster
      network: east-network
EOF

sleep 20

keast apply -n istio-system -f ch12/gateways/expose-services.yaml

EXT_IP=$(keast -n istio-system get svc istio-eastwestgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl --cert ch12/certs/west-cluster/ca-cert.pem --key ch12/certs/west-cluster/ca-key.pem -H "Host: catalog.istioinaction.io" http://$EXT_IP/api/catalog/items