#!/bin/bash

# Cập nhật hệ thống
sudo apt-get update
sudo apt-get upgrade -y

# Cài đặt các gói cần thiết
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Thêm khóa GPG của Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Thêm repository Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Cập nhật lại package index
sudo apt-get update

# Cài đặt Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Cấu hình Docker để sử dụng systemd
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Khởi động lại Docker
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Tắt swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "Thêm khóa GPG của Kubernetes"
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
echo "Cập nhật lại package index"
sudo apt-get update

echo "Cài đặt Kubernetes components"
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

echo "Cấu hình các module kernel cần thiết"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "Cấu hình sysctl params cần thiết"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo "Cấu hình containerd"
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

cat <<EOF | sudo tee /etc/default/kubelet
# Đảm bảo kubelet sử dụng containerd
echo "KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock" | sudo tee /etc/default/kubelet

echo "Khởi động lại kubelet"
sudo systemctl daemon-reload
sudo systemctl restart kubelet || true

echo "Checking kubelet status:"
sudo systemctl status kubelet || true

echo "Checking kubelet logs:"
sudo journalctl -xeu kubelet || true

echo "Worker node đã được cài đặt. Sử dụng lệnh 'kubeadm join' để kết nối vào cluster."