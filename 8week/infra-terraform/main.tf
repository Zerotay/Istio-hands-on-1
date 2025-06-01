provider "aws" {
  shared_config_files = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  default_tags {
    tags = { org = "cloudnet" }
  }
}


data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# SSH Key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}
resource "aws_key_pair" "eks_key_pair" {
  key_name = "eks-ssh-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  filename = "${path.module}/key.pem"
  content  = tls_private_key.ssh_key.private_key_pem
  file_permission = "0400"
}
