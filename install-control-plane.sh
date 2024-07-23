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
sudo mkdir -p /etc/docker
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
# Cập nhật lại package index
sudo apt-get update

# Cài đặt Kubernetes components
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Cấu hình các module kernel cần thiết
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Cấu hình sysctl params cần thiết
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Khởi tạo cluster (thay YOUR_POD_CIDR bằng CIDR mạng pod của bạn)
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Thiết lập kubeconfig cho user hiện tại
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Cài đặt network plugin (ví dụ: Calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "Control plane đã được cài đặt và khởi tạo."
echo "Hãy lưu token join cluster được hiển thị ở trên để thêm worker nodes sau này."