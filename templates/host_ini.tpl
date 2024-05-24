# ## Configure 'ip' variable to bind kubernetes services on a
# ## different ip than the default iface
# ## We should set etcd_member_name for etcd cluster. The node that is not a etcd member do not need to set the value, or can set the empty string value.
[all]
%{ for index, hostname in hostnames ~}
${hostname} ansible_host=${kubespray_public_ip["${index}"]} ip=${kubespray_private_ip["${index}"]}
%{ endfor ~}

[kube_control_plane]
%{ for index, hostname in control_hostnames ~}
${hostname}
%{ endfor ~}

[etcd]
%{ for index, hostname in control_hostnames ~}
${hostname}
%{ endfor ~}

[kube_node]
%{ for index, hostname in hostnames ~}
${hostname}
%{ endfor ~}

[k8s_cluster:children]
kube_control_plane
kube_node

[bastion]
%{ for index, hostname in bastion_name ~}
${hostname} ansible_host=${bastion_ip["${index}"]}
%{ endfor ~}

[postgres_cluster]
%{ for index, hostname in pg_hostnames ~}
${hostname}
%{ endfor ~}

[pgpool]
%{ for index, hostname in pgpool_hostnames ~}
${hostname}
%{ endfor ~}

[pgbench]
%{ for index, hostname in pgbench_hostnames ~}
${hostname}
%{ endfor ~}

# settings
[all:vars]
ansible_user=${ssh_user}
ansible_ssh_private_key_file=~/.ssh/yandex_test_cluster
ansible_ssh_common_args="-o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p -q {{ ansible_user }}@${bastion_ip[0]} {% if ansible_ssh_private_key_file is defined %}-i {{ ansible_ssh_private_key_file }}{% endif %}'"

#download_localhost=False
# Make kubespray cache even when download_run_once is false
#download_force_cache=False
# Keeping the cache on the nodes can improve provisioning speed while debugging kubespray
#download_keep_remote_cache=False
#local_path_provisioner_enabled=False
#local_path_provisioner_claim_root="/opt/local-path-provisioner/"

[k8s_cluster:vars]
# These two settings will put kubectl and admin.config in $inventory/artifacts
# kube_network_plugin=flannel
# kube_network_plugin_multus=False
# flannel_interface=eth1
kubeconfig_localhost=True
kubectl_localhost=True
docker_rpm_keepcache=1
download_run_once=True
