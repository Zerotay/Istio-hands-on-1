alias kubectl='kubectl --kubeconfig ./kubeconfig'
alias istioctl='istioctl --kubeconfig ./kubeconfig'

# register Env from tfo
FORUM=$(terraform -chdir=infra-terraform output -json | yq '.vm_ip.value')
APP_IP=$(terraform -chdir=infra-terraform output -json | yq '.cluster_ip.value')

# show ssh command in new line for copying it easily.
printf "SSH to cluster\n"
terraform -chdir=infra-terraform output -json | yq '.cluster_ssh_command.value'
printf "SSH to VM\n"
terraform -chdir=infra-terraform output -json | yq '.vm_ssh_command.value'

