/* general */
variable "masters_count" {
  default = 1
}

variable "use_floating_ip_as_lb" {
  default = true
}

variable "create_private_network" {
  default = false
}

variable "workers_count" {
  default = 2
}

variable "workers_with_volume" {
  default = 0
}

variable "workers_volume_size" {
  default = 40
}

variable "storage_nodes_count" {
  default = 2
}

variable "storage_nodes_with_volume" {
  default = 2
}

variable "storage_nodes_volume_size" {
  default = 40
}

variable "domain" {
  default = ""
}

variable "subdomain" {
  default = "k8s"
}

variable "ovh_application_key" {
  default = ""
}

variable "ovh_application_secret" {
  default = ""
}

variable "ovh_endpoint" {
  default = "ovh-eu"
}

/* hcloud */
variable "hcloud_token" {}

variable "hcloud_ssh_keys" {
  default = []
}

variable "hcloud_location" {
  default = "nbg1"
}

variable "hcloud_master_type" {
  default = "cx21"
}

variable "master_hostname_format" {
  default = "kube-master-%d"
}

variable "hcloud_worker_type" {
  default = "cx21"
}

variable "worker_hostname_format" {
  default = "kube-worker-%d"
}

variable "hcloud_storage_nodes_type" {
  default = "cx11"
}

variable "storage_nodes_hostname_format" {
  default = "kube-storage-%d"
}

variable "hcloud_image" {
  default = "debian-10"
}
