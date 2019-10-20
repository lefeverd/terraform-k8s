#!/bin/bash

set -e

IP="$1"
	
echo "" > /etc/network/interfaces.d/99-hcloud-floating-ips.cfg
    cat >> /etc/network/interfaces.d/99-hcloud-floating-ips.cfg <<EOM
auto eth0:1
iface eth0:1 inet static
    address ${IP}
    netmask 255.255.255.255
EOM
