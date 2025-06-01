data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_eip" "cluster" {
  domain = "vpc"
}

resource "aws_eip_association" "cluster" {
  instance_id   = aws_instance.cluster.id
  allocation_id = aws_eip.cluster.id
}

data "template_file" "userdata_cluster" {
  template = file("${path.module}/templates/userdata_cluster.tpl")
  vars = {
    private_ip = local.cluster_private_ip
    eip = aws_eip.cluster.public_ip
  }
}

resource "aws_instance" "cluster" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3a.xlarge"

  subnet_id = aws_subnet.cluster.id
  vpc_security_group_ids = [aws_security_group.main.id]
  private_ip = local.cluster_private_ip
  associate_public_ip_address = false

  key_name = aws_key_pair.eks_key_pair.key_name

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 30
    volume_type = "gp3"
    delete_on_termination = true
  }
  user_data = data.template_file.userdata_cluster.rendered

  tags = {
    Name = "cluster-ec2"
  }
}

data "template_file" "userdata_vm" {
  template = file("${path.module}/templates/userdata_vm.tpl")
  vars = {
    private_ip = local.vm_private_ip
  }
}

resource "aws_instance" "vm" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  subnet_id = aws_subnet.cluster.id
  vpc_security_group_ids = [aws_security_group.main.id]
  private_ip = local.vm_private_ip

  key_name = aws_key_pair.eks_key_pair.key_name

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 30
    volume_type = "gp3"
    delete_on_termination = true
  }

  user_data = data.template_file.userdata_vm.rendered

  tags = {
    Name = "vm-ec2"
  }
}

# user_data = <<-EOF
#     #!/bin/bash
#     hostnamectl --static set-hostname k3s-s
#     echo 'alias vi=vim' >> /etc/profile
#     echo "sudo su -" >> /home/ubuntu/.bashrc
#     ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
#
#     systemctl stop ufw && systemctl disable ufw
#     systemctl stop apparmor && systemctl disable apparmor
#
#     apt update && apt-get install bridge-utils net-tools conntrack ngrep jq tree unzip kubecolor -y
#     echo "192.168.10.10 k3s-s" >> /etc/hosts
#
#     curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.15+k3s1 INSTALL_K3S_EXEC=" --disable=traefik --tls-san ${aws_eip.cluster.public_ip}"  \
#         sh -s - server --token istiotoken --cluster-cidr "172.16.0.0/16" --service-cidr "10.10.200.0/24" --write-kubeconfig-mode 644
#
#     echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> /etc/profile
#     curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
#
#     echo 'alias kc=kubecolor' >> /etc/profile
#     echo 'alias k=kubectl' >> /etc/profile
#     echo 'complete -o default -F __start_kubectl k' >> /etc/profile
#     source <(kubectl completion bash)
#     echo 'source <(kubectl completion bash)' >> /etc/profile
#
#     # Install Kubectx & Kubens
#     git clone https://github.com/ahmetb/kubectx /opt/kubectx
#     ln -s /opt/kubectx/kubens /usr/local/bin/kubens
#     ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
#
#     # Install Kubeps & Setting PS1
#     git clone https://github.com/jonmosco/kube-ps1.git /root/kube-ps1
#     cat <<"EOT" >> ~/.bash_profile
#     source /root/kube-ps1/kube-ps1.sh
#     KUBE_PS1_SYMBOL_ENABLE=true
#     function get_cluster_short() {
#       echo "$1" | cut -d . -f1
#     }
#     KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
#     KUBE_PS1_SUFFIX=') '
#     PS1='$(kube_ps1)'$PS1
#   EOF
