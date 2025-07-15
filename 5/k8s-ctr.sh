#!/usr/bin/env bash

echo ">>>> K8S Controlplane config Start <<<<"

echo "[TASK 1] Initial Kubernetes"
kubeadm init --token 123456.1234567890123456 --token-ttl 0 --skip-phases=addon/kube-proxy --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.10.100 --cri-socket=unix:///run/containerd/containerd.sock >/dev/null 2>&1


echo "[TASK 2] Setting kube config file"
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config


echo "[TASK 3] Source the completion"
echo 'source <(kubectl completion bash)' >> /etc/profile
echo 'source <(kubeadm completion bash)' >> /etc/profile


echo "[TASK 4] Alias kubectl to k"
echo 'alias k=kubectl' >> /etc/profile
echo 'alias kc=kubecolor' >> /etc/profile
echo 'complete -F __start_kubectl k' >> /etc/profile


echo "[TASK 5] Install Kubectx & Kubens"
git clone https://github.com/ahmetb/kubectx /opt/kubectx >/dev/null 2>&1
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx


echo "[TASK 6] Install Kubeps & Setting PS1"
git clone https://github.com/jonmosco/kube-ps1.git /root/kube-ps1 >/dev/null 2>&1
cat <<"EOT" >> /root/.bash_profile
source /root/kube-ps1/kube-ps1.sh
KUBE_PS1_SYMBOL_ENABLE=true
function get_cluster_short() {
  echo "$1" | cut -d . -f1
}
KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
KUBE_PS1_SUFFIX=') '
PS1='$(kube_ps1)'$PS1
EOT
kubectl config rename-context "kubernetes-admin@kubernetes" "HomeLab" >/dev/null 2>&1


echo "[TASK 7] Install Calico CNI"
kubectl apply -f https://raw.githubusercontent.com/hanship0530/book-k8s-network/5/calico-v3.30.2.yaml >/dev/null 2>&1


echo "[TASK 8] Install calicoctl Tool"
curl -L https://github.com/projectcalico/calico/releases/download/v3.30.2/calicoctl-linux-arm64 -o calicoctl >/dev/null 2>&1
chmod +x calicoctl && mv calicoctl /usr/bin

echo "[TASK 9] Remove node taint"
kubectl taint nodes k8s-ctr node-role.kubernetes.io/control-plane-

echo "[TASK 10] Change Node IP"
sed -i 's/^\(KUBELET_KUBEADM_ARGS="\)/\1--node-ip=192.168.10.100 /' /var/lib/kubelet/kubeadm-flags.env
systemctl daemon-reexec && systemctl restart kubelet


echo ">>>> K8S Controlplane Config End <<<<"