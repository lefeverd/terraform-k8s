terraform {
  backend "local" {}
}

module "provider_masters" {
  source = "./provider/hcloud"

  token           = "${var.hcloud_token}"
  ssh_keys        = "${var.hcloud_ssh_keys}"
  location        = "${var.hcloud_location}"
  type            = "${var.hcloud_master_type}"
  image           = "${var.hcloud_image}"
  hosts           = "${var.masters_count}"
  hostname_format = "${var.master_hostname_format}"
  use_floating_ip_as_lb = "${var.use_floating_ip_as_lb}"
}

module "provider_workers" {
  source = "./provider/hcloud"

  token           = "${var.hcloud_token}"
  ssh_keys        = "${var.hcloud_ssh_keys}"
  location        = "${var.hcloud_location}"
  type            = "${var.hcloud_worker_type}"
  image           = "${var.hcloud_image}"
  hosts           = "${var.workers_count}"
  hostname_format = "${var.worker_hostname_format}"
  hosts_with_volume = "${min(var.workers_with_volume, var.workers_count)}"
  volume_size     = "${var.workers_volume_size}"
}

module "provider_storage_nodes" {
  source = "./provider/hcloud"

  token           = "${var.hcloud_token}"
  ssh_keys        = "${var.hcloud_ssh_keys}"
  location        = "${var.hcloud_location}"
  type            = "${var.hcloud_storage_nodes_type}"
  image           = "${var.hcloud_image}"
  hosts           = "${var.storage_nodes_count}"
  hostname_format = "${var.storage_nodes_hostname_format}"
}

locals {
  total_count = "${var.masters_count + var.workers_count + var.storage_nodes_count}"
  public_ips = "${concat(module.provider_masters.public_ips, module.provider_workers.public_ips, module.provider_storage_nodes.public_ips)}"
  private_ips = "${concat(module.provider_masters.private_ips, module.provider_workers.private_ips, module.provider_storage_nodes.private_ips)}"
  hostnames = "${concat(module.provider_masters.hostnames, module.provider_workers.hostnames, module.provider_storage_nodes.hostnames)}"
  private_network_interface = "${module.provider_masters.private_network_interface}" # Masters and workers should have the same
}

# module "provider" {
#   source = "github.com/hobby-kube/provisioning/provider/scaleway"
#
#   organization    = "${var.scaleway_organization}"
#   token           = "${var.scaleway_token}"
#   region          = "${var.scaleway_region}"
#   type            = "${var.scaleway_type}"
#   image           = "${var.scaleway_image}"
#   hosts           = "${local.total_count}"
#   hostname_format = "${var.hostname_format}"
# }

# module "provider" {
#   source = "github.com/hobby-kube/provisioning/provider/digitalocean"
#
#   token           = "${var.digitalocean_token}"
#   ssh_keys        = "${var.digitalocean_ssh_keys}"
#   region          = "${var.digitalocean_region}"
#   size            = "${var.digitalocean_size}"
#   image           = "${var.digitalocean_image}"
#   hosts           = "${local.total_count}"
#   hostname_format = "${var.hostname_format}"
# }

module "swap" {
  source = "./service/swap"

  count       = "${local.total_count}"
  connections = "${local.public_ips}"
}

module "dns" {
  source = "./dns/ovh"
  endpoint = "${var.ovh_endpoint}"
  count      = "${local.total_count}"
  application_key = "${var.ovh_application_key}"
  application_secret      = "${var.ovh_application_secret}"
  domain     = "${var.domain}"
  subdomain     = "${var.subdomain}"
  public_ips = "${local.public_ips}"
  hostnames  = "${local.hostnames}"
  master_hostname_format = "${var.master_hostname_format}"
  use_floating_ip_as_lb = "${var.use_floating_ip_as_lb}"
  lb_ip = "${module.provider_masters.floating_ip}"
}
