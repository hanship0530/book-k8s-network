#!/usr/bin/env bash

echo ">>>> Initial Config Start <<<<"
echo "[TASK 1] Setting Root Password"
printf "qwe123\nqwe123\n" | passwd >/dev/null 2>&1

echo "[TASK 2] Setting Sshd Config"
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl restart sshd

echo "[TASK 3] Change Timezone & Setting Profile & Bashrc"
# Change Timezone
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

#  Setting Profile & Bashrc
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> .bashrc

echo "[TASK 4] Disable ufw & AppArmor"
systemctl stop ufw && systemctl disable ufw >/dev/null 2>&1
systemctl stop apparmor && systemctl disable apparmor >/dev/null 2>&1

echo "[TASK 5] Install Packages"
apt update -qq >/dev/null 2>&1
apt-get install apt-transport-https ca-certificates curl gnupg gpg prettyping sshpass bridge-utils net-tools jq tree resolvconf wireguard ngrep ipset iputils-arping ipvsadm -y -qq >/dev/null 2>&1
# Install Batcat - https://github.com/sharkdp/bat
apt-get install bat -y >/dev/null 2>&1
echo "alias cat='batcat --paging=never'" >> /etc/profile
# Install Exa - https://the.exa.website/
apt-get install exa -y >/dev/null 2>&1

echo "[TASK 6] Change DNS Server IP Address"
echo -e "nameserver 1.1.1.1" > /etc/resolvconf/resolv.conf.d/head
resolvconf -u

echo "[TASK 7] Setting Local DNS Using Hosts file"
echo "192.168.10.10 k8s-m" >> /etc/hosts
echo "192.168.20.100 k8s-w0" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.10.10$i k8s-w$i" >> /etc/hosts; done

echo "[TASK 8] Install Docker Engine"
curl -fsSL https://get.docker.com | sh >/dev/null 2>&1

echo "[TASK 9] Change Cgroup Driver Using Systemd"
cat <<EOT > /etc/docker/daemon.json
{"exec-opts": ["native.cgroupdriver=systemd"]}
EOT
systemctl daemon-reload >/dev/null 2>&1
systemctl restart docker

echo "[TASK 10] Disable and turn off SWAP"
swapoff -a

echo "[TASK 11] Install Kubernetes components (kubeadm, kubelet and kubectl) - v$2"
mkdir -p -m 755 /etc/apt/keyrings
K8SMMV=$(echo $2 | sed -En 's/^([0-9]+\.[0-9]+)\..*/\1/p')
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$K8SMMV/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$K8SMMV/deb/ /" >> /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update >/dev/null 2>&1
apt-get install -y kubelet=$2-00 kubectl=$2-00 kubeadm=$2-00 >/dev/null 2>&1
apt-mark hold kubelet kubeadm kubectl >/dev/null 2>&1
systemctl enable kubelet && systemctl start kubelet

echo "[TASK 12] Git Clone"
git clone https://github.com/hanship0530/book-k8s-network.git /root/book-k8s-network >/dev/null 2>&1

echo ">>>> Initial Config End <<<<"
