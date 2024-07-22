# Cập nhật hệ thống
sudo apt-get update
sudo apt-get upgrade -y

# Cài đặt Docker
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Cài đặt kubeadm, kubelet, và kubectl
sudo apt-get install -y apt-transport-https curl
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Tắt swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\\(.*\\)$/#\\1/g' /etc/fstab

# Cấu hình containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# Cấu hình crictl
sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock --set image-endpoint=unix:///run/containerd/containerd.sock

# Khởi động lại kubelet
sudo systemctl restart kubelet

# Cài đặt net-tools
sudo apt install -y net-tools

# Cấu hình kernel parameters cho Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
