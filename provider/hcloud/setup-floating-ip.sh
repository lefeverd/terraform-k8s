#!/bin/bash

set -e

IP="$1"
	
echo "" > /etc/network/interfaces.d/99-hcloud-floating-ips.cfg
    cat >> /etc/network/interfaces.d/99-hcloud-floating-ips.cfg <<EOM
iface eth0 inet static
    address ${IP}
    netmask 255.255.255.255
EOM
