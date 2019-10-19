variable "token" {}

variable "hosts" {
  default = 0
}

variable "hosts_with_volume" {
  default = 0
}

variable "volume_size" {
  default = 10
}

variable "hostname_format" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "type" {
  type = "string"
}

variable "image" {
  type = "string"
}

variable "ssh_keys" {
  type = "list"
}

variable "use_floating_ip_as_lb" {
  default = false
}

provider "hcloud" {
  token = "${var.token}"
}

variable "apt_packages" {
  type    = "list"
  default = []
}

resource "hcloud_floating_ip" "master" {
  count = "${var.use_floating_ip_as_lb ? 1 : 0}"
  type = "ipv4"
  home_location = "nbg1"
  description = "${element(hcloud_server.host.*.name, count.index)}"
}

locals {
  floating_ip = "${ join(" ", hcloud_floating_ip.master.*.ip_address) }"
}


resource "hcloud_server" "host" {
  name        = "${format(var.hostname_format, count.index + 1)}"
  location    = "${var.location}"
  image       = "${var.image}"
  server_type = "${var.type}"
  ssh_keys    = ["${var.ssh_keys}"]

  count = "${var.hosts}"

  #lifecycle {
  #  prevent_destroy = true
  #}

  provisioner "remote-exec" {
    connection {
      host  = "${hcloud_server.host.0.ipv4_address}"
      user  = "root"
      agent = false
      private_key = "${file("~/.ssh/id_rsa")}"
    }

    inline = [
      "while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'waiting for boot-finished'; sleep 5; done;",
      "sleep 20",
      "apt-get update",
      "apt-get install -yq ufw ${join(" ", var.apt_packages)}",
    ]
  }
}

resource "hcloud_volume" "volume" {
    count = "${var.hosts_with_volume}"
    name = "volume-${element(hcloud_server.host.*.name, count.index)}"
    size = "${var.volume_size}"
    server_id = "${hcloud_server.host.id}"
    server_id = "${element(hcloud_server.host.*.id, count.index)}"
    automount = true
}

resource "null_resource" "floating_ip_setup" {
  count = "${var.use_floating_ip_as_lb ? 1 : 0}"

  connection {
    host  = "${hcloud_server.host.0.ipv4_address}"
    user  = "root"
    agent = false
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "file" {
    source      = "${path.module}/setup-floating-ip.sh"
    destination = "/tmp/setup-floating-ip.sh"
  }

  # Setup floating IP
  provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/setup-floating-ip.sh",
        "/tmp/setup-floating-ip.sh \"${local.floating_ip}\"",
        "/etc/init.d/networking restart"
    ]
  }
}

resource "hcloud_floating_ip_assignment" "main" {
  count = "${var.use_floating_ip_as_lb ? 1 : 0}"
  floating_ip_id = "${hcloud_floating_ip.master.0.id}"
  server_id = "${element(hcloud_server.host.*.id, count.index)}"
}

output "ids" {
  value = ["${hcloud_server.host.*.id}"]
}

output "hostnames" {
  value = ["${hcloud_server.host.*.name}"]
}

output "public_ips" {
  value = ["${hcloud_server.host.*.ipv4_address}"]
}

output "private_ips" {
  value = ["${hcloud_server.host.*.ipv4_address}"]
}

output "floating_ip" {
  value = "${local.floating_ip}"
}

output "private_network_interface" {
  value = "eth0"
}
