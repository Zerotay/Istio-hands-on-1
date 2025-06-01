#!/bin/bash
hostnamectl --static set-hostname k3s-s
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> /home/ubuntu/.bashrc
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

systemctl stop ufw && systemctl disable ufw
systemctl stop apparmor && systemctl disable apparmor

apt update && apt-get install bridge-utils net-tools conntrack ngrep jq tree unzip kubecolor -y
echo "${private_ip} k3s-s" >> /etc/hosts

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.32.4+k3s1 INSTALL_K3S_EXEC=" --disable=traefik --tls-san ${eip}"  \
    sh -s - server --token istiotoken --cluster-cidr "172.16.0.0/16" --service-cidr "10.10.200.0/24" --write-kubeconfig-mode 644

echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> /etc/profile
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

echo 'alias kc=kubecolor' >> /etc/profile
echo 'alias k=kubectl' >> /etc/profile
echo 'complete -o default -F __start_kubectl k' >> /etc/profile
source <(kubectl completion bash)
echo 'source <(kubectl completion bash)' >> /etc/profile

git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
