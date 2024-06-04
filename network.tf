resource "yandex_vpc_network" "cluster-network1" {
  name = "cluster-network1"
}

resource "yandex_vpc_subnet" "cluster-subnet1" {
  name           = "cluster-subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.cluster-network1.id
  v4_cidr_blocks = ["10.141.0.0/24"]
  route_table_id = yandex_vpc_route_table.route_table.id
}

resource "yandex_vpc_gateway" "nat_gateway1" {
  name = "cluster-gateway1"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_table" {
  name       = "cluster-route-table1"
  network_id = yandex_vpc_network.cluster-network1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway1.id
  }
}

resource "yandex_lb_target_group" "control_group" {
  name = "control-nodes-group"
  # динамическое создание нужного количества блоков target
  dynamic "target" {
    for_each = local.control_nodes
    content {
      subnet_id = yandex_vpc_subnet.cluster-subnet1.id
      address   = target.value.network_interface.0.ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "external_lb" {
  name                = "api-server-loadbalancer-internal"
  deletion_protection = false
  listener {
    name        = "api-servers-external-endpoint"
    port        = 6883
    target_port = 6443
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.control_group.id
    healthcheck {
      name     = "api-servers-healthcheck"
      timeout  = 2
      interval = 5
      tcp_options {
        port = 6443
      }
    }
  }
}

locals {
  ip_external = [
    for listener in yandex_lb_network_load_balancer.external_lb.listener :
    [
      for spec in listener.external_address_spec : spec.address
    ]
    if listener.name == "api-servers-external-endpoint"
  ]
  port_external = [
    for listener in yandex_lb_network_load_balancer.external_lb.listener : listener.port
    if listener.name == "api-servers-external-endpoint"
  ]
}

output "lb_extenal_ip" {
  value = local.ip_external[0][0]
}

output "lb_extenal_port" {
  value = local.port_external[0]
}

resource "local_file" "all_over_vals" {
  content = templatefile("templates/lb_var_yml.tpl",
    {
      lb_ip   = local.ip_external[0][0]
      lb_port = local.port_external[0]
    }
  )
  filename = "group_vars/lb_var.yml"
}
