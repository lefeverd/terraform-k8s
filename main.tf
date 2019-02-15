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

locals {
  total_count = "${var.masters_count + var.workers_count}"
  public_ips = "${concat(module.provider_masters.public_ips, module.provider_workers.public_ips)}"
  private_ips = "${concat(module.provider_masters.private_ips, module.provider_workers.private_ips)}"
  hostnames = "${concat(module.provider_masters.hostnames, module.provider_workers.hostnames)}"
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

module "wireguard" {
  source = "./security/wireguard"

  count        = "${local.total_count}"
  connections  = "${local.public_ips}"
  private_ips  = "${local.private_ips}"
  hostnames    = "${local.hostnames}"
  #overlay_cidr = "${module.kubernetes.overlay_cidr}"
}

module "firewall" {
  source = "./security/ufw"

  count                = "${local.total_count}"
  connections          = "${local.public_ips}"
  private_interface    = "${local.private_network_interface}"
  vpn_interface        = "${module.wireguard.vpn_interface}"
  vpn_port             = "${module.wireguard.vpn_port}"
  #kubernetes_interface = "${module.kubernetes.overlay_interface}"
}
/*
module "etcd" {
  source = "github.com/hobby-kube/provisioning/service/etcd"

  count       = "${local.total_count}"
  connections = "${local.public_ips}"
  hostnames   = "${local.hostnames}"
  vpn_unit    = "${module.wireguard.vpn_unit}"
  vpn_ips     = "${module.wireguard.vpn_ips}"
}

module "kubernetes" {
  source = "github.com/hobby-kube/provisioning/service/kubernetes"

  count          = "${local.total_count}"
  connections    = "${local.public_ips}"
  cluster_name   = "${var.domain}"
  vpn_interface  = "${module.wireguard.vpn_interface}"
  vpn_ips        = "${module.wireguard.vpn_ips}"
  etcd_endpoints = "${module.etcd.endpoints}"
}
*/
