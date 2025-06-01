output "local_remote_ip" {
  value = trimspace(data.http.my_ip.response_body)
}
output "ssh_key_path" {
  value =  "${path.cwd}/${local_file.private_key.filename}"
}

output "cluster_ip" {
  value =  "${aws_eip.cluster.public_ip}"
}
output "cluster_ssh_command" {
  value =  "ssh -i ${path.cwd}/${local_file.private_key.filename} ubuntu@${aws_eip.cluster.public_ip}"
}

output "vm_ip" {
  value =  "${aws_instance.vm.public_ip}"
}
output "vm_ssh_command" {
  value =  "ssh -i ${path.cwd}/${local_file.private_key.filename} ubuntu@${aws_instance.vm.public_ip}"
}


resource "null_resource" "fetch_kubeconfig" {

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for k3s.yaml...'",
      "while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do sleep 2; done"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${local_file.private_key.filename}")
      host        = aws_eip.cluster.public_ip
    }
  }
  provisioner "local-exec" {
    command = <<EOT
      ssh -i ${local_file.private_key.filename} \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      ubuntu@${aws_eip.cluster.public_ip} \
      sudo cat /etc/rancher/k3s/k3s.yaml | \
      sed -E 's/127.0.0.1/${aws_eip.cluster.public_ip}/g' > ../kubeconfig
    EOT
  }

  depends_on = [
    aws_instance.cluster,
    aws_eip_association.cluster
  ]
}
