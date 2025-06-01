cat << EOF | istioctl install --kubeconfig=./west-kubeconfig -f - -y
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
      # istio-csr
      caAddress: cert-manager-istio-csr.istio-system.svc:443
      meshID: usmesh
      multiCluster:
        clusterName: west-cluster
      network: west-network
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: false
    pilot:
      k8s:
        env:
          - name: ENABLE_CA_SERVER
            value: "false"
          - name: ENABLE_NATIVE_SIDECARS
            value: "true"
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

cat << EOF | istioctl install --kubeconfig=./east-kubeconfig -f - -y
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
      # istio-csr
      caAddress: cert-manager-istio-csr.istio-system.svc:443
      meshID: usmesh
      multiCluster:
        clusterName: east-cluster
      network: east-network
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: false
    pilot:
      k8s:
        env:
          - name: ENABLE_CA_SERVER
            value: "false"
          - name: ENABLE_NATIVE_SIDECARS
            value: "true"
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        service:
          ports:
          - name: http
            port: 80
            targetPort: 8080
            nodePort: 31000
          - name: https
            port: 443
            targetPort: 8443
            nodePort: 31005
          externalTrafficPolicy: Local
EOF

kwest apply -f debug.yaml -n istioinaction
keast apply -f debug.yaml -n istioinaction
