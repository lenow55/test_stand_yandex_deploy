#!/bin/bash

set -eu pipefail

start_time=$(date +%s)
date1=$(date +"%s")
TF_IN_AUTOMATION=1 terraform init -upgrade
TF_IN_AUTOMATION=1 terraform apply -auto-approve
# rm -rf kubespray || true
# git clone https://github.com/kubernetes-sigs/kubespray.git
cp -f host.ini kubespray/inventory/sample/host.ini
# перекидываю групповые переменные
cp -f group_vars/lb_var.yml kubespray/inventory/sample/group_vars/all/
cp -f group_vars/postgres_cluster.yml kubespray/inventory/sample/group_vars/
cp -f group_vars/pgbench.yml kubespray/inventory/sample/group_vars/
cp -f group_vars/pgpool.yml kubespray/inventory/sample/group_vars/
rm -rf kubespray/inventory/sample/{credentials,artifacts}
cd kubespray

source venv/bin/activate
ansible-playbook -i inventory/sample/host.ini --become cluster.yml
cd ..
ansible-playbook -i host.ini --become playbooks/dir_pg_cluster.yaml
ansible-playbook -i host.ini --become playbooks/dir_pgbench.yaml
ansible-playbook -i host.ini --become playbooks/dir_pgpool.yaml
deactivate

kubeconfig="./kubespray/inventory/sample/artifacts/admin.conf"
kubectl apply --server-side -f \
	https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.22/releases/cnpg-1.22.2.yaml \
	--kubeconfig=${kubeconfig}

sleep 5

helm repo add prometheus-community \
	https://prometheus-community.github.io/helm-charts

helm upgrade --install \
	-f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/docs/src/samples/monitoring/kube-stack-config.yaml \
	prometheus-community \
	prometheus-community/kube-prometheus-stack \
	--kubeconfig=${kubeconfig}

sleep 10

kubectl apply -f \
	https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/docs/src/samples/monitoring/prometheusrule.yaml \
	--kubeconfig=${kubeconfig}

kubectl apply -k ./kube_deploy/pg_cluster --kubeconfig=${kubeconfig}
kubectl apply -k ./kube_deploy/pgpool --kubeconfig=${kubeconfig}

sleep 240

kubectl apply -k ./kube_deploy/unit4pgbench --kubeconfig=${kubeconfig}

end_time=$(date +%s)
date2=$(date +"%s")
echo "###############"
echo "Execution time was $((end_time - start_time)) s."
DIFF=$((date2 - date1))
echo "Duration: $((DIFF / 3600)) hours $(((DIFF % 3600) / 60)) minutes $((DIFF % 60)) seconds"
echo "###############"
