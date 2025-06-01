################################################################################
# Create WorkloadGroup and send setting files to VM
################################################################################
kubectl create namespace forum-services
kubectl create serviceaccount forum-sa -n forum-services
kubectl apply -f ch13/workloadgroup.yaml
istioctl x workload entry configure -n forum-services --name forum \
  --clusterID "west-cluster" --autoregister \
  --capture-dns true \
  --ingressIP 192.168.10.10 \
  -o /tmp/my-workload-files/

scp -i infra-terraform/key.pem -r /tmp/my-workload-files ubuntu@$FORUM:/tmp/

# If you reach in this comments, it's time to set the files in the VM instance!
scp -i infra-terraform/key.pem -r 10-vm-setting.sh ubuntu@$FORUM:/tmp/
eval "$(terraform -chdir=infra-terraform output -json | yq '.vm_ssh_command.value')"

