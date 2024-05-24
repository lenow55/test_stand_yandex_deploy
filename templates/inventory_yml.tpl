all:
  hosts:
    ${indent(4, hostnames)}
  vars:
    ansible_user=${ssh_user}
    ansible_ssh_private_key_file=~/.ssh/yandex_test_cluster
    ansible_ssh_common_args="-o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p -q {{ ansible_user }}@${bastion_ip[0]} {% if ansible_ssh_private_key_file is defined %}-i {{ ansible_ssh_private_key_file }}{% endif %}'"
