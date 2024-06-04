data "yandex_compute_image" "family_images_linux" {
  family = var.family_images_linux
}

locals {
  bastion_control_node = [
    yandex_compute_instance.kubespray_control_1_bastion
  ]

  control_nodes = concat(
    local.bastion_control_node,
    yandex_compute_instance.kubespray_control
  )

  control_nodes_behind_nat = yandex_compute_instance.kubespray_control

  work_nodes = concat(
    yandex_compute_instance.kubespray_postgres_cluster,
    yandex_compute_instance.kubespray_pgpool,
    yandex_compute_instance.kubespray_pgbench
  )

  bastion_public_ip  = local.bastion_control_node[*].network_interface[0].nat_ip_address
  bastion_private_ip = local.bastion_control_node[*].network_interface[0].ip_address

  behind_nat_ip = concat(
    local.control_nodes_behind_nat[*].network_interface[*].ip_address,
    local.work_nodes[*].network_interface[*].ip_address
  )

  cluster_nodes = concat(
    local.control_nodes,
    local.work_nodes
  )
}

resource "local_file" "host_ini" {
  content = templatefile("templates/host_ini.tpl",
    {
      ssh_user             = var.ssh_user
      hostnames            = local.cluster_nodes[*].name
      pg_hostnames         = yandex_compute_instance.kubespray_postgres_cluster[*].name
      pgpool_hostnames     = yandex_compute_instance.kubespray_pgpool[*].name
      pgbench_hostnames    = yandex_compute_instance.kubespray_pgbench[*].name
      control_hostnames    = local.control_nodes[*].name
      work_hostnames       = local.work_nodes[*].name
      kubespray_public_ip  = concat(local.bastion_public_ip, local.behind_nat_ip)
      kubespray_private_ip = concat(local.bastion_private_ip, local.behind_nat_ip)
      bastion_ip           = local.bastion_public_ip
      bastion_name         = local.bastion_control_node[*].name
    }
  )
  filename = "host.ini"
}
