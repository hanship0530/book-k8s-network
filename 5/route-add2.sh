#!/usr/bin/env bash

echo ">>>> Route Add Config Start <<<<"

chmod 600 /etc/netplan/01-netcfg.yaml
chmod 600 /etc/netplan/50-vagrant.yaml

cat <<EOT>> /etc/netplan/50-vagrant.yaml
      routes:
      - to: 192.168.10.0/24
        via: 192.168.20.254
EOT

netplan apply

echo ">>>> Route Add Config End <<<<"