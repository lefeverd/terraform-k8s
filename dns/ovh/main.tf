variable "count" {}

variable "application_key" {}

variable "application_secret" {}

variable "domain" {}

variable "subdomain" {}

variable "use_floating_ip_as_lb" {
  default = false
}
variable "lb_ip" {
  default = ""
}

variable "endpoint" {}

variable "hostnames" {
  type = "list"
}

variable "master_hostname_format" {}

variable "public_ips" {
  type = "list"
}

provider "ovh" {
  endpoint = "${var.endpoint}"
  application_key    = "${var.application_key}"
  application_secret = "${var.application_secret}"
  #consumer_key       = "zzzzzzzzzzzzzz"
}

# Create all the hosts DNS entries
resource "ovh_domain_zone_record" "hosts" {
    count = "${var.count}"
    zone = "${var.domain}"
    subdomain = "${element(var.hostnames, count.index)}.${var.subdomain}"
    fieldtype = "A"
    ttl = "120"
    target = "${element(var.public_ips, count.index)}"
}

# Create a CNAME for api to first master
resource "ovh_domain_zone_record" "api" {
    zone = "${var.domain}"
    subdomain = "api.${var.subdomain}"
    fieldtype = "CNAME"
    ttl = "120"
    target = "${format(var.master_hostname_format, 1)}.${var.subdomain}"
}

# Create root domain DNS entry pointing to LB (LoadBalancer) IP
resource "ovh_domain_zone_record" "domain" {
    count = "${var.use_floating_ip_as_lb ? 1 : 0}"
    zone = "${var.domain}"
    fieldtype = "A"
    ttl = "120"
    target = "${var.lb_ip}"
}

# Create a wildcard for the subdomain pointing to the root domain (must be created beforehand)
resource "ovh_domain_zone_record" "wildcard_subdomain" {
    zone = "${var.domain}"
    subdomain = "*.${var.subdomain}"
    fieldtype = "CNAME"
    ttl = "120"
    target = "${var.domain}."
}

# Create a wildcard for the domain pointing to the dynamic IP
resource "ovh_domain_zone_record" "wildcard_domain" {
    zone = "${var.domain}"
    subdomain = "*"
    fieldtype = "CNAME"
    ttl = "120"
    target = "${var.domain}."
}

output "domains" {
  value = ["${ovh_domain_zone_record.hosts.*.target}"]
}
