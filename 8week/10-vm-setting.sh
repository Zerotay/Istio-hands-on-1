curl -LO https://storage.googleapis.com/istio-release/releases/1.25.1/deb/istio-sidecar.deb
dpkg -i istio-sidecar.deb

mkdir -p /etc/certs
mkdir -p /var/run/secrets/tokens

cp /tmp/my-workload-files/root-cert.pem /etc/certs/root-cert.pem
cp /tmp/my-workload-files/istio-token /var/run/secrets/tokens/istio-token
cp /tmp/my-workload-files/cluster.env /var/lib/istio/envoy/cluster.env
cp /tmp/my-workload-files/mesh.yaml /etc/istio/config/mesh
cat /tmp/my-workload-files/hosts >> /etc/hosts

chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem

systemctl start istio
systemctl enable istio
