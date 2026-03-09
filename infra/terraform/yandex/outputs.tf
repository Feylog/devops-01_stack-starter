output "vm_external_ip" {
  value = yandex_compute_instance.vm.network_interface[0].nat_ip_address
}

output "ssh_command" {
  value = "ssh ${var.vm_user}@${yandex_compute_instance.vm.network_interface[0].nat_ip_address}"
}
