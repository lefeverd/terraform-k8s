variable "count" {}

variable "connections" {
  type = "list"
}

resource "null_resource" "swap" {
  count = "${var.count}"

  connection {
    host  = "${element(var.connections, count.index)}"
    user  = "root"
    agent = false
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "remote-exec" {
    inline = [
      "fallocate -l 2G /swapfile",
      "chmod 600 /swapfile",
      "mkswap /swapfile",
      "swapon /swapfile",
      "echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/systemd/system/kubelet.service.d",
    ]
  }

  provisioner "file" {
    content     = "${file("${path.module}/templates/90-kubelet-extras.conf")}"
    destination = "/etc/systemd/system/kubelet.service.d/90-kubelet-extras.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl daemon-reload",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"cgroup_enable=memory swapaccount=1 /g' /etc/default/grub"
    ]
  }
}
