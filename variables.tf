/* general */
variable "masters_count" {
  default = 1
}

variable "use_floating_ip_as_lb" {
  default = true
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

variable "domain" {
  default = "yourdomain.be"
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
  default = "cx11"
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

variable "hcloud_image" {
  default = "ubuntu-16.04"
}
