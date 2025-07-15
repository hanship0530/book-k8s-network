#!/usr/bin/env bash

echo ">>>> Initial Config Start <<<<"

echo "[TASK 0] Setting eth2"
chmod 600 /etc/netplan/01-netcfg.yaml
chmod 600 /etc/netplan/50-vagrant.yaml

cat << EOT >> /etc/netplan/50-vagrant.yaml
      routes:
      - to: 10.244.0.0/16
        type: blackhole
    eth2:
      addresses:
      - 192.168.20.200/24
EOT

netplan apply

echo "[TASK 1] Setting Profile & Bashrc"
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> /home/vagrant/.bashrc
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

echo "[TASK 2] Disable AppArmor"
systemctl stop ufw && systemctl disable ufw >/dev/null 2>&1
systemctl stop apparmor && systemctl disable apparmor >/dev/null 2>&1

echo "[TASK 3] Add Kernel setting - IP Forwarding"
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p >/dev/null 2>&1

echo "[TASK 4] Setting Dummy Interface"
modprobe dummy
ip link add loop1 type dummy
ip link set loop1 up
ip addr add 10.1.1.254/24 dev loop1

ip link add loop2 type dummy
ip link set loop2 up
ip addr add 10.1.2.254/24 dev loop2

echo "[TASK 5] Install Packages"
apt update -qq >/dev/null 2>&1
apt-get install sshpass net-tools jq tree resolvconf iptraf-ng iputils-arping ngrep quagga -y -qq >/dev/null 2>&1

echo "[TASK 6] Change DNS Server IP Address"
echo -e "nameserver 1.1.1.1" > /etc/resolvconf/resolv.conf.d/head
resolvconf -u

echo "[TASK 7] Setting Local DNS Using Hosts file"
echo "192.168.10.10 k8s-ctr" >> /etc/hosts
echo "192.168.20.100 k8s-w0" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.10.10$i k8s-w$i" >> /etc/hosts; done

echo "[TASK 8] Config Quagga Routing Software Suite"
# quagga logging
mkdir /var/log/quagga
chown quagga:quagga /var/log/quagga

# quagga config
cat <<EOF > /etc/quagga/zebra.conf
hostname zebra
password zebra
enable password zebra
!
log file /var/log/quagga/zebra.log
!
line vty
EOF
systemctl enable zebra >/dev/null 2>&1 && systemctl start zebra

cat <<EOF > /etc/quagga/bgpd.conf
hostname zebra-bgpd
password zebra
enable password zebra
!
log file /var/log/quagga/bgpd.log
!
debug bgp events
debug bgp filters
debug bgp fsm
debug bgp keepalives
debug bgp updates
!
router bgp 64512
bgp router-id 10.1.1.254
bgp graceful-restart
maximum-paths 4
maximum-paths ibgp 4
network 10.1.1.0/24
network 10.1.2.0/24
neighbor 192.168.10.10  remote-as 64512
neighbor 192.168.20.100 remote-as 64512
neighbor 192.168.10.101 remote-as 64512
neighbor 192.168.10.102 remote-as 64512
!
line vty
EOF

chown quagga:quagga /etc/quagga/bgpd.conf
chmod 640 /etc/quagga/bgpd.conf
systemctl enable bgpd >/dev/null 2>&1 && systemctl start bgpd

echo "[TASK 7] Install Apache"
apt install apache2 -y >/dev/null 2>&1
echo -e "<h1>Web Server : $(hostname)</h1>" > /var/www/html/index.html

echo ">>>> Initial Config End <<<<"
