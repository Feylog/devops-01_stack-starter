provider "yandex" {
  service_account_key_file = pathexpand("~/.yc/sa-key.json")
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}
