sudo kubeadm reset
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
# Thiết lập kubeconfig cho user hiện tại
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Cài đặt network plugin (ví dụ: Calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml --validate=false