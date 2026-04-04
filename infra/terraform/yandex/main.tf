resource "yandex_vpc_network" "net" {
  name = "devops-net"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "devops-subnet-a"
  zone           = var.zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_address" "static_ip" {
  name = "devops01-static-ip"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}
output "vm_static_ip" {
  value = yandex_vpc_address.static_ip.external_ipv4_address[0].address
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "vm" {
  name        = var.vm_name
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
    nat_ip_address = yandex_vpc_address.static_ip.external_ipv4_address[0].address
  }

  metadata = {
    ssh-keys = "${var.vm_user}:${var.ssh_pubkey}"
  }
}
