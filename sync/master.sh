: '
Copyright 2021 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'

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

# TODO HELP WANTED
#start cluster with Flannel:
# https://stackoverflow.com/questions/60391127/kubeadm-init-apiserver-advertise-address-flag-equivalent-in-config-file
# Someday consider
  #cat <<EOF | sudo tee kubeadm-config.yaml
  #kind: ClusterConfiguration
  #apiVersion: kubeadm.k8s.io/v1beta2
  #kubernetesVersion: v1.21.0
  #networking:
  #  podSubnet: "10.244.0.0/16"
  #---
  #kind: KubeletConfiguration
  #apiVersion: kubelet.config.k8s.io/v1beta1
  #cgroupDriver: systemd
  #EOF
# RIGHT NOW we NEED to use ApiSErverAdvertiseAddress... but not sure how to do that equivalent in kubeadm.

sudo kubeadm init --apiserver-advertise-address=10.20.30.10 --pod-network-cidr=10.244.0.0/16

#to start the cluster with the current user:
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

rm -f /var/sync/config
cp $HOME/.kube/config /var/sync/config

# CNI: Not 100% tested, just a prototype...
function cni_flannel {
  wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -P /tmp -q
  ## this is important for windows:
  sed -i 's/"Type": "vxlan"/"Type": "vxlan","VNI": 4096,"Port": 4789/' /tmp/kube-flannel.yml
  kubectl apply -f /tmp/kube-flannel.yml

  curl -s -L https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/kube-proxy.yml | sed 's/VERSION/v1.21.0/g' | kubectl apply -f -
  kubectl apply -f https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/flannel-overlay.yml
}

function cni_antrea {
  kubectl apply -f https://github.com/antrea-io/antrea/releases/download/v0.13.2/antrea.yml
}

# flannel
cni_antrea


######## MAKE THE JOIN FILE FOR WINDOWS ##########
######## MAKE THE JOIN FILE FOR WINDOWS ##########
######## MAKE THE JOIN FILE FOR WINDOWS ##########
rm -f /var/sync/kubejoin.ps1

cat << EOF > /var/sync/kubejoin.ps1
\$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", \$env:Path, [System.EnvironmentVariableTarget]::Machine)
EOF

kubeadm token create --print-join-command >> /var/sync/kubejoin.ps1

sed -i 's#--token#--cri-socket "npipe:////./pipe/containerd-containerd" --token#g' /var/sync/kubejoin.ps1

### NOW MAKE WINDOWS PROXY SECRETS...
#### TODO Put these in a single file or something...
cat << EOF > svcact2.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: kube-proxy
  name: kube-proxy-windows
  namespace: kube-system
EOF
kubectl create -f svcact2.yaml

cat << EOF > svcact.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node:kube-proxy
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: node:kube-proxy
subjects:
- kind: Group
  name: system:nodes
  apiGroup: rbac.authorization.k8s.io
- kind: ServiceAccount
  name: kube-proxy-windows
  namespace: kube-system
EOF
kubectl create -f svcact.yaml
