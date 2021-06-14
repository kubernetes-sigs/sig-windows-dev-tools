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
set -e
kubernetes_version=${1-1.21.0}
echo "Using $kubernetes_version as the Kubernetes version"

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
sudo apt-get install -y docker-ce=5:20.10.5~3-0~ubuntu-$(lsb_release -cs) kubelet=$kubernetes_version-00 kubeadm=$kubernetes_version-00 kubectl=$kubernetes_version-00
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
  #kubernetes_version: v$kubernetes_version
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

rm -f /var/sync/shared/config
cp $HOME/.kube/config /var/sync/shared/config

# CNI: Not 100% tested, just a prototype...
function cni_flannel {
  wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -P /tmp -q
  ## this is important for windows:
  sed -i 's/"Type": "vxlan"/"Type": "vxlan","VNI": 4096,"Port": 4789/' /tmp/kube-flannel.yml
  kubectl apply -f /tmp/kube-flannel.yml

  curl -s -L https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/kube-proxy.yml | sed "s#VERSION#v$kubernetes_version#g" | kubectl apply -f -
  kubectl apply -f https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/flannel-overlay.yml
}

function cni_antrea {
  curl -s -L https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/kube-proxy.yml | sed "s#VERSION#v$kubernetes_version#g" | kubectl apply -f -
  kubectl apply -f https://github.com/antrea-io/antrea/releases/download/v0.13.2/antrea.yml
}

# flannel
cni_antrea


######## MAKE THE JOIN FILE FOR WINDOWS ##########
######## MAKE THE JOIN FILE FOR WINDOWS ##########
######## MAKE THE JOIN FILE FOR WINDOWS ##########
rm -f /var/sync/shared/kubejoin.ps1

cat << EOF > /var/sync/shared/kubejoin.ps1
\$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", \$env:Path, [System.EnvironmentVariableTarget]::Machine)
EOF

kubeadm token create --print-join-command >> /var/sync/shared/kubejoin.ps1

sed -i 's#--token#--cri-socket "npipe:////./pipe/containerd-containerd" --token#g' /var/sync/shared/kubejoin.ps1

### NOW MAKE WINDOWS PROXY SECRETS...
#### TODO Put these in a single file or something...

cat << EOF > kube-proxy-and-antrea.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: kube-proxy
  name: kube-proxy-windows
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node:kube-proxy
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:node-proxier
subjects:
- kind: Group
  name: system:node
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: system:nodes
  apiGroup: rbac.authorization.k8s.io
- kind: ServiceAccount
  name: kube-proxy-windows
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node:god2
  namespace: kube-system
subjects:
- kind: User
  name: system:node:winw1
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node:god3
  namespace: kube-system
subjects:
- kind: Group
  name: system:nodes
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node:god4
  namespace: kube-system
subjects:
- kind: User
  name: system:serviceaccount:kube-system:kube-proxy-windows
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl create -f kube-proxy-and-antrea.yaml
