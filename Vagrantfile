# -*- mode: ruby -*-
# vi: set ft=ruby :
# TODO automate script for Linux: Docker, Windows, Firewall, Swap
# TODO create a Kubernetes (+ Kind) vagrant box for win server 2019 ()  

Vagrant.configure(2) do |config|

  config.vm.define :master do |master|
      master.vm.host_name = "master"
      master.vm.box = "ubuntu/focal64"
      master.vm.network :private_network, ip:"10.0.0.10"
      master.vm.provider :virtualbox do |vb|
	vb.memory = 2048
	vb.cpus = 2
      end
      master.vm.provision :shell, privileged: false, inline: $provision_master_node
  end

  config.vm.define :winWorker1 do |winWorker1|
      winWorker1.vm.host_name = "winWorker1"
      winWorker1.vm.box = "StefanScherer/windows_2019"  
      winWorker1.vm.network :private_network, ip:"10.0.0.11"
      winWorker1.vm.synced_folder ".", "c:\\sync"
      winWorker1.vm.provider :virtualbox do |vb|
          vb.memory = 4096
          vb.cpus = 2
          vb.gui = true
      end
  end
end

$provision_master_node = <<-SHELL
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

#start cluster with Calico:
sudo kubeadm init --apiserver-advertise-address=10.0.0.10 --pod-network-cidr=192.168.0.0/16

#to start the cluster with the current user:
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#set up calicoctl as a plugin for kubectl
#(cd /usr/local/bin && curl -o kubectl-calico -L  https://github.com/projectcalico/calicoctl/releases/download/v3.18.1/calicoctl && chmod +x kubectl-calico)
#kubectl-calico ipam configure --strictaffinity=true

SHELL
