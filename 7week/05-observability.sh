helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm install prom prometheus-community/kube-prometheus-stack --version 71.1.0 \
  -n monitoring --create-namespace=true \
  -f values-prom-stack.yaml \
  --kubeconfig ./west-kubeconfig
kwest apply -f observability/pod-monitor.yaml
helm install prom prometheus-community/kube-prometheus-stack --version 71.1.0 \
  -n monitoring --create-namespace=true \
  -f values-prom-stack.yaml \
  --kubeconfig ./east-kubeconfig
keast apply -f observability/pod-monitor.yaml

kwest patch svc -n monitoring prom-kube-prometheus-stack-prometheus -p '{"spec": {"type": "LoadBalancer", "ports": [{"port": 9090, "targetPort": 9090 }]}}'
keast patch svc -n monitoring prom-kube-prometheus-stack-prometheus -p '{"spec": {"type": "LoadBalancer", "ports": [{"port": 9090, "targetPort": 9090 }]}}'

# federate metrics from east to west
EXTERNAL_IP=$(keast get svc -n monitoring prom-kube-prometheus-stack-prometheus -ojsonpath="{.status.loadBalancer.ingress[0].ip}") \
REMOTE=east-cluster CURRENT=west-cluster \
envsubst '${EXTERNAL_IP} ${REMOTE} ${CURRENT}' < observability/prom-federation.yaml > west-fed.yaml
kwest -n monitoring create secret generic west-fed --from-file=west-fed.yaml
kwest patch prometheus -n monitoring prom-kube-prometheus-stack-prometheus \
  --type=merge -p '{"spec": {"additionalScrapeConfigs":{"name": "west-fed", "key": "west-fed.yaml"}}}'

# retrieve configuration
#kwest -n monitoring get secrets west-fed -ojsonpath='{.data.west-fed\.yaml}' | base64 -d
#kwest -n monitoring describe prometheuses.monitoring.coreos.com prom-kube-prometheus-stack-prometheus
# delete secret
#kwest -n monitoring delete secrets west-fed

#################
# kiali
helm repo add kiali https://kiali.org/helm-charts
helm install kiali-operator kiali/kiali-operator \
    --namespace istio-system \
    --kubeconfig ./west-kubeconfig

kwest apply -f observability/kiali.yaml

# delete
#kwest -n istio-system delete kialis.kiali.io kiali
#helm --kubeconfig ./west-kubeconfig -n istio-system uninstall kiali-operator

# If you need to back up your kubeconfig, do it so.
#cp ~/.kube/config ~/.kube/config.backup
KUBECONFIG="./west-kubeconfig:./east-kubeconfig" kubectl config view --merge --flatten > ~/.kube/config
./kiali-prepare-remote-cluster.sh --kiali-cluster-context kind-west --remote-cluster-context kind-east \
  --process-kiali-secret true --process-remote-resources true \
  --remote-cluster-name east-cluster --remote-cluster-url https://east-control-plane:6443 \
  --dry-run false
# Refer to documents, Kiali Operator would restart the kiali dashboard for update, but it didn't work in my local.
# It needs manual restart.
kwest -n istio-system rollout restart kiali-operator

# jaeger
#kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
kwest apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
sleep 1
kwest apply -n istio-system -f - <<EOF
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: jaeger
spec:
  image: jaegertracing/jaeger:latest
  ports:
  - name: jaeger
    port: 16686
  config:
    service:
      extensions: [jaeger_storage, jaeger_query]
      pipelines:
        traces:
          receivers: [otlp]
          exporters: [jaeger_storage_exporter]
    extensions:
      jaeger_query:
        storage:
          traces: memstore
      jaeger_storage:
        backends:
          memstore:
            memory:
              max_traces: 100000
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    exporters:
      jaeger_storage_exporter:
        trace_storage: memstore
EOF


kwest -n istio-system patch svc jaeger-inmemory-instance-collector -p '{"spec": {"type": "LoadBalancer"}}'
#kwest -n istio-system patch svc jaeger-inmemory-instance-collector -p '{"spec": {"type": "LoadBalancer", "ports": [{"port": 16686, "targetPort": 16686 }]}}'

cat << EOF | istioctl upgrade --kubeconfig=./west-kubeconfig -f - -y
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultProviders:
      metrics:
        - prometheus
      tracing: []
    extensionProviders:
      - name: jaeger
        opentelemetry:
          port: 4317
          service: jaeger-inmemory-instance-collector.istio-system.svc.cluster.local
EOF

cat << EOF | kwest apply -f -
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  namespace: istio-system
  name: tracing
spec:
  tracing:
    - providers:
        - name: jaeger
      randomSamplingPercentage: 40.0
EOF

JAEGER_IP=$(kwest get svc -n istio-system jaeger-inmemory-instance-collector -ojsonpath="{.status.loadBalancer.ingress[0].ip}")

#cat << EOF | keast apply -f -
#apiVersion: networking.istio.io/v1
#kind: ServiceEntry
#metadata:
#  name: jaeger
#  namespace: istio-system
#spec:
#  hosts:
#  - jaeger-inmemory-instance-collector.istio-system.svc.cluster.local
#  addresses:
#  - $JAEGER_IP
#  ports:
#  - number: 4317
#    name: https
#    protocol: TLS
#  resolution: STATIC
#  location: MESH_EXTERNAL
#  endpoints:
#  - address: $JAEGER_IP
#EOF

JAEGER_IP=$(kwest get svc -n istio-system jaeger-inmemory-instance-collector -ojsonpath="{.status.loadBalancer.ingress[0].ip}")
cat << EOF | istioctl upgrade --kubeconfig=./east-kubeconfig -f - -y
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
spec:
  meshConfig:
    enableTracing: true
    defaultProviders:
      metrics:
        - prometheus
      tracing: []
    extensionProviders:
      - name: jaeger
        opentelemetry:
          port: 4317
          service: "$JAEGER_IP"
EOF

cat << EOF | keast apply -f -
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  namespace: istio-system
  name: tracing
spec:
  tracing:
    - providers:
        - name: jaeger
      randomSamplingPercentage: 40.0
EOF



