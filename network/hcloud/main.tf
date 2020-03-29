variable "token" {}
variable "count" {}
variable "ids" {
  type = "list"
}

variable "ips" {
    type = "list"
}

provider "hcloud" {
  token = "${var.token}"
}

resource "hcloud_network" "privnet" {
  name = "private-network"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "privsubnet" {
  network_id = "${hcloud_network.privnet.id}"
  type = "server"
  network_zone = "eu-central"
  ip_range   = "10.0.1.0/24"
}

resource "hcloud_server_network" "srvnetwork" {
  count = "${var.count}"
  server_id = "${element(var.ids, count.index)}"
  network_id = "${hcloud_network.privnet.id}"
}

resource "null_resource" "private_network_setup" {
  count = "${var.count}"

  connection {
    host  = "${element(var.ips, count.index)}"
    user  = "root"
    agent = false
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "file" {
    source      = "${path.module}/61-private-network.cfg"
    destination = "/etc/network/interfaces.d/61-private-network.cfg"
  }
}
