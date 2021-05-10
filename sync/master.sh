# Add GDP keys and repositories for both Docker and Kubernetes
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update

#Install Docker and Kubernetes, hold versions
sudo apt-get install -y docker-ce=5:20.10.5~3-0~ubuntu-$(lsb_release -cs) kubelet=1.20.4-00 kubeadm=1.20.4-00 kubectl=1.20.4-00
sudo apt-mark hold docker-ce kubelet kubeadm kubectl

#disable swap
swapoff -a
sudo sed -i '/swap/d' /etc/fstab

#bridged traffic to iptables is enabled for kube-router:
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables=1" | sudo tee -a /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-arptables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

#start cluster with Flannel:
sudo kubeadm init --apiserver-advertise-address=10.20.30.10 --pod-network-cidr=10.244.0.0/16

#to start the cluster with the current user:
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
cp $HOME/.kube/config /var/sync/config

#setting up flannel networking
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -P /tmp -q
## this is important for windows:
sed -i 's/"Type": "vxlan"/"Type": "vxlan","VNI": 4096,"Port": 4789/' /tmp/kube-flannel.yml
kubectl apply -f /tmp/kube-flannel.yml

curl -s -L https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/kube-proxy.yml | sed 's/VERSION/v1.20.4/g' | kubectl apply -f -
kubectl apply -f https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/flannel-overlay.yml

kubeadm token create --print-join-command > /var/sync/join.ps1

echo "`cat /var/sync/join.ps1` --cri-socket=\"npipe:////./pipe/containerd-containerd\"" > /var/sync/join.ps1
