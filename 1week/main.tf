#################################################### 
##### kube ops view
#################################################### 
resource "helm_release" "kube_ops_view" {
  name      = "kube-ops-view"
  repository = "https://geek-cookbook.github.io/charts"
  chart      = "kube-ops-view"
  version = "1.2.2"

  namespace = "kube-system"
  create_namespace = true
  values = [
    <<-EOF
    env:
      TZ: Asia/Seoul
    service:
      main:
        type: NodePort
        ports:
          http:
            nodePort: 30005
    EOF
  ]
}

#################################################### 
##### metrics server
#################################################### 
resource "helm_release" "metrics_server" {
  name      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  # version = "1.2.2"

  namespace = "kube-system"
  values = [
    <<-EOF
    args:
    - --kubelet-insecure-tls
    EOF
  ]
}

#################################################### 
##### prometheus stack
#################################################### 
# resource "helm_release" "prometheus_stack" {
#   name      = "prometheus-stack"
#   repository = "https://prometheus-community.github.io/helm-charts"
#   chart      = "kube-prometheus-stack"
#   version = "69.3.1"

#   create_namespace = true
#   namespace = "monitoring"
#   values = [
#     <<-EOF
#     grafana:
#       service:
#         type: NodePort
#         nodePort: 30002
#       defaultDashboardsTimezone: Asia/Seoul

#     prometheus:
#       service:
#         type: NodePort
#         nodePort: 30001
#       prometheusSpec:
#         scrapeInterval: "15s"
#         evaluationInterval: "15s"
#         podMonitorSelectorNilUsesHelmValues: false
#         serviceMonitorSelectorNilUsesHelmValues: false
#         retention: 5d
#         retentionSize: "10GiB"

#     alertmanager:
#       enabled: false
#     defaultRules:
#       create: false
#     prometheus-windows-exporter:
#       prometheus:
#         monitor:
#           enabled: false
#     EOF
#   ]
# }
