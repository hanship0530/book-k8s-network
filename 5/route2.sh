#!/usr/bin/env bash

IP=$(ip -br -4 addr | grep eth0 | awk '{print $3}')

cat <<EOT> /etc/netplan/50-vagrant.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
      - $IP
      routes:
      - to: 192.168.10.0/24
        via: 192.168.20.254
EOT

sudo chmod 400 /etc/netplan/50-vagrant.yaml
sudo netplan apply