#!/usr/bin/env bash

IP=$(ip -br -4 addr | grep eth0 | awk '{print $3}')

echo ">>>> Route Add Config Start <<<<"

chmod 600 /etc/netplan/01-netcfg.yaml
chmod 600 /etc/netplan/50-vagrant.yaml

cat <<EOT> /etc/netplan/50-vagrant.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
      - $IP
      routes:
      - to: 192.168.20.0/24
        via: 192.168.10.254
EOT

netplan apply

echo ">>>> Route Add Config End <<<<"