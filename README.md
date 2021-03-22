# KubernetesOnWindows

This guide is based on [this very nice Vagrantfile](https://gist.github.com/danielepolencic/ef4ddb763fd9a18bf2f1eaaa2e337544) and this very good [guide on how install Kubernetes on Ubuntu Focal (20.04)](https://github.com/mialeevs/kubernetes_installation). I hope I can later also automaize the setup of the linux vm for Kuberntes in the Vagrantfile. At the moment this has to be done by hand:

For all linux nodes:

Add GDP keys and repositories for both Docker and Kubernetes
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
```

Install Docker and Kubernetes, hold versions
```
sudo apt-get install -y docker-ce=5:20.10.5~3-0~ubuntu-$(lsb_release -cs) kubelet=1.20.4-00 kubeadm=1.20.4-00 kubectl=1.20.4-00
sudo apt-mark hold docker-ce kubelet kubeadm kubectl
```

disable swap
```
swapoff -a
sudo sed -i '/swap/d' /etc/fstab
```

bridged traffic to iptables is enabled for kube-router:
```
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables=1" | sudo tee -a /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-arptables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

Only for master node:

start cluster with Calico (this can take a few minutes):
```
sudo kubeadm init --apiserver-advertise-address=10.0.0.10 --pod-network-cidr=192.168.0.0/16
```
to start the cluster with the current user:
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

set up Calico
```
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

windows:
open PowerShell as admin (right click the icon, "Run as Administrator").
insall docker PowerShell module:
```
install-module -name DockerMsftProvider –Force
```

install Docker:
```
Install-Package Docker –Providername DockerMsftProvider -Force
```

reboot:
```
restart-computer
```

start docker:
```
Start-Service docker
```

pull Docker image for Kubernetes:
```
docker image pull mcr.microsoft.com/windows/nanoserver:1809
```
tag the Docker image:
```
docker image tag mcr.microsoft.com/windows/nanoserver:1809 microsoft/nanoserver:latest
```

mkdir C:\kubernetes
cd C:\kubernetes
$ProgressPreference=’SilentlyContinue’
iwr -outf kubernetes-node-windows-amd64.tar.gz "https://dl.k8s.io/v1.15.1/kubernetes-node-windows-amd64.tar.gz"
tar -xkf kubernetes-node-windows-amd64.tar.gz -C C:\kubernetes
mv C:\kubernetes\kubernetes\node\bin\*.exe C:\kubernetes

Here is a [guide on how to install Docker on Win Server 2019](https://www.hostafrica.co.za/blog/new-technologies/how-to-install-docker-on-linux-and-windows/#win) and another [guide on how to install Kubernetes on Win Server 2019](https://www.hostafrica.co.za/blog/new-technologies/install-kubernetes-cluster-windows-server-worker-nodes/)
