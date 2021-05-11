# Add GDP keys and repositories for both Docker and Kubernetes
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update


#disable swap
swapoff -a
sudo sed -i '/swap/d' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


#Install Docker and Kubernetes, hold versions
sudo apt-get install -y docker-ce=5:20.10.5~3-0~ubuntu-$(lsb_release -cs) kubelet=1.20.4-00 kubeadm=1.20.4-00 kubectl=1.20.4-00
sudo apt-mark hold docker-ce kubelet kubeadm kubectl


# #bridged traffic to iptables is enabled for kube-router:
# echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
# echo "net.bridge.bridge-nf-call-ip6tables=1" | sudo tee -a /etc/sysctl.conf
# echo "net.bridge.bridge-nf-call-arptables=1" | sudo tee -a /etc/sysctl.conf
# sudo sysctl -p

# Configuring and starting containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

cat <<EOF | sudo tee kubeadm-config.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta2
kubernetesVersion: v1.21.0
networking:
  podSubnet: "10.244.0.0/16"
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF

#start cluster with Flannel:
sudo kubeadm init --config kubeadm-config.yaml

#to start the cluster with the current user:
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

rm -f /var/sync/config
cp $HOME/.kube/config /var/sync/config

#setting up flannel networking
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -P /tmp -q
## this is important for windows:
sed -i 's/"Type": "vxlan"/"Type": "vxlan","VNI": 4096,"Port": 4789/' /tmp/kube-flannel.yml
kubectl apply -f /tmp/kube-flannel.yml

curl -s -L https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/kube-proxy.yml | sed 's/VERSION/v1.21.0/g' | kubectl apply -f -
kubectl apply -f https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/flannel-overlay.yml

rm -f /var/sync/join.txt
kubeadm token create --print-join-command > /var/sync/join.txt
echo "`cat /var/sync/join.ps1` --cri-socket=\"npipe:////./pipe/containerd-containerd\"" > /var/sync/join.txt
