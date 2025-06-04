istioctl proxy-status
istioctl ztunnel-config workload
istioctl ztunnel-config service

# check daemonset config




# check changes between labeling
kubectl label namespace default istio.io/dataplane-mode=ambient

kubectl label pod netshoot istio.io/dataplane-mode=none