resource "yandex_compute_instance" "kubespray_control_1_bastion" {
  name               = "kubespray-control-bastion"
  platform_id        = "standard-v3"
  hostname           = "kubespray-control-bastion"
  service_account_id = yandex_iam_service_account.sa-compute-admin.id
  maintenance_policy = "restart"
  resources {
    cores  = 4
    memory = 4
  }
  boot_disk {
    initialize_params {
      size     = var.disk_size
      type     = var.disk_type
      image_id = data.yandex_compute_image.family_images_linux.id
    }
  }
  scheduling_policy {
    preemptible = true
  }
  lifecycle {
    ignore_changes = [boot_disk]
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.cluster-subnet1.id
    nat       = true
  }
  metadata = {
    ssh-keys = "var.ssh_user:${file(var.public_key_path)}"
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = self.network_interface[0].nat_ip_address
      private_key = file(var.private_key_path)
    }
    inline = [
      "echo check connection"
    ]
  }
}

locals {
  bastion_host = yandex_compute_instance.kubespray_control_1_bastion.network_interface[0].nat_ip_address
}
