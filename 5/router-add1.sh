#!/usr/bin/env bash

IP=$(ip -br -4 addr | grep eth0 | awk '{print $3}')

echo ">>>> Route Add Config Start <<<<"

chmod 600 /etc/netplan/01-netcfg.yaml
chmod 600 /etc/netplan/50-vagrant.yaml

cat <<EOT>> /etc/netplan/50-vagrant.yaml
      routes:
      - to: 192.168.20.0/24
        via: 192.168.10.200
      - to: 10.244.0.0/16
        via: 192.168.10.200
EOT

netplan apply

echo ">>>> Route Add Config End <<<<"