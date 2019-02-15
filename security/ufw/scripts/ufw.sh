#!/bin/sh
set -e

ufw --force reset
ufw allow ssh
ufw allow in on ${private_interface} to any port ${vpn_port} # vpn on private interface
ufw allow in on ${vpn_interface}
# allow all traffic on VPN tunnel interface
ufw allow in on wg0
#ufw allow in on dollar{kubernetes_interface} # Kubernetes pod overlay interface
ufw allow 6443 # Kubernetes API secure remote port
ufw allow 80
ufw allow 443
#ufw allow from 10.233.64.0/18 to any port 6789 # Allow rook/ceph communication on k8s pods network
ufw allow from 10.233.64.0/18 # Allow communication on k8s pods network
ufw allow from 10.233.0.0/18 # Allow communication on k8s services network
ufw default deny incoming
ufw --force enable
ufw status verbose
