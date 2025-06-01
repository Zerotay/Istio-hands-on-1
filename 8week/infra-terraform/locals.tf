locals {
  name = "istio-hands-on"
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  vpc_cidr = "192.168.0.0/16"
  cluster_private_ip = "192.168.10.10"
  vm_private_ip = "192.168.10.200"



}