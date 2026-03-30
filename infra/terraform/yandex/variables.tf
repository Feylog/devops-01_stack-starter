variable "token" { type = string }
variable "cloud_id" { type = string }
variable "folder_id" { type = string }
variable "ssh_pubkey" { type = string }

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "vm_user" {
  type    = string
  default = "ubuntu"
}

variable "vm_name" {
  type    = string
  default = "devops-01"
}
