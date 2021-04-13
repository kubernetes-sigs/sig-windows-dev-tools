# -*- mode: ruby -*-
# vi: set ft=ruby :
# TODO create a Kubernetes (+ Kind) vagrant box for win server 2019 ()  

Vagrant.configure(2) do |config|
  # LINUX MASTER
  config.vm.define :master do |master|
    master.vm.host_name = "master"
    master.vm.box = "ubuntu/focal64"
    master.vm.network :private_network, ip:"10.0.0.10"
    master.vm.provider :virtualbox do |vb|
    master.vm.synced_folder "./master", "/var/sync"
      vb.memory = 2048
      vb.cpus = 2
    end
    master.vm.provision :shell, privileged: false, inline: $provision_master_node
  end

  # WINDOWS WORKER (win server 2019)
  config.vm.define :winw1 do |winw1|
    winw1.vm.host_name = "winw1"
    winw1.vm.box = "StefanScherer/windows_2019"  
    winw1.vm.provider :virtualbox do |vb|
      vb.memory = 4096
      vb.cpus = 2
      vb.gui = true
    end
    winw1.vm.network :private_network, ip:"10.0.0.11"
    winw1.vm.synced_folder "./win", "c:\\sync"

    #install docker
    #winw1.vm.provision "shell", privileged: "true", powershell_elevated_interactive: "true", inline: <<-SHELL
    #  Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -WarningAction "SilentlyContinue"
    #  Install-Module -Name DockerMsftProvider -Force -WarningAction "SilentlyContinue"
    #  Install-Package Docker -Providername DockerMsftProvider -Force -WarningAction "SilentlyContinue"
    #SHELL
    #reboot
    #winw1.vm.provision :reload
    #start docker
    # winw1.vm.provision "shell", privileged: "true", powershell_elevated_interactive: "true", inline: <<-SHELL
    #   Start-Service docker
    # SHELL
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

#start cluster with Flannel:
sudo kubeadm init --apiserver-advertise-address=10.0.0.10 --pod-network-cidr=10.244.0.0/16

#to start the cluster with the current user:
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
cp $HOME/.kube/config /var/sync/config

#to set up flannel networking
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
SHELL
