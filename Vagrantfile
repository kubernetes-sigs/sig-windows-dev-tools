# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

# Modify these in the variables.yaml file... they are described there in gory detail...
settingsFile = ENV["VAGRANT_VARIABLES"] || 'sync/shared/variables.yaml'
settings = YAML.load_file settingsFile
k8s_linux_registry=settings['k8s_linux_registry']
k8s_linux_kubelet_deb=settings['k8s_linux_kubelet_deb']
k8s_linux_apiserver=settings['k8s_linux_apiserver']
kubernetes_compatibility=settings['kubernetes_compatibility']

overwrite_linux_bins = settings['overwrite_linux_bins']
overwrite_windows_bins = settings['overwrite_windows_bins'] ? "-OverwriteBins" : ""

linux_ram = settings['linux_ram']
linux_cpus = settings['linux_cpus']
windows_ram = settings['windows_ram']
windows_cpus = settings['windows_cpus']


Vagrant.configure(2) do |config|

  # LINUX Control Plane
  config.vm.define :controlplane do |controlplane|
    controlplane.vm.host_name = "controlplane"
    controlplane.vm.box = "ubuntu/focal64"
    # better because its available on vmware and virtualbox
    # controlplane.vm.box = "bento/ubuntu-18.04"
    controlplane.vm.network :private_network, ip:"10.20.30.10"
    controlplane.vm.provider :virtualbox do |vb|
    controlplane.vm.synced_folder "./sync/shared", "/var/sync/shared"
    controlplane.vm.synced_folder "./sync/linux", "/var/sync/linux"
      vb.memory = linux_ram
      vb.cpus = linux_cpus
    end

    ### This allows the node to default to the right IP i think....
    # 1) this seems to break the ability to get to the internet

    #controlplane.vm.provision :shell, privileged: true, inline: "sudo ip route add default via 10.20.30.10"
    # controlplane.vm.provision :shell, privileged: false, path: "sync/linux/controlplane.sh", args: "#{overwrite_linux_bins} #{k8s_linux_registry} #{k8s_linux_kubelet_deb} #{k8s_linux_apiserver} "

    # TODO shoudl we pass KuberneteVersion to calico agent exe? and also service cidr if needed?
    # dont run as priveliged cuz we need the kubeconfig from regular user
    if settings['cni'].equal? "calico" then
      controlplane.vm.provision "shell", path: "sync/linux/calico-0.sh"
    else
      controlplane.vm.provision "shell", path: "sync/linux/antrea-0.sh"
    end


  end

  # WINDOWS WORKER (win server 2019)
  config.vm.define :winw1 do |winw1|
    winw1.vm.host_name = "winw1"
    winw1.vm.box = "StefanScherer/windows_2019"  
    winw1.vm.network :private_network, ip:"10.20.30.11"
    winw1.vm.synced_folder ".", "/vagrant", disabled:true
    winw1.vm.synced_folder "./sync/shared", "C:/sync/shared"
    winw1.vm.synced_folder "./sync/windows/", "C:/sync/windows/"
    winw1.vm.synced_folder "./forked", "C:/forked/"

    winw1.vm.provider :virtualbox do |vb|
      vb.memory = windows_ram
      vb.cpus = windows_cpus
      vb.gui = false
    end

    winw1.vm.provision "shell", path: "sync/windows/hyperv.ps1", privileged: true
    winw1.vm.provision :reload
    winw1.vm.provision "shell", path: "sync/windows/containerd1.ps1", privileged: true #, run: "never"
    winw1.vm.provision :reload
    winw1.vm.provision "shell", path: "sync/windows/containerd2.ps1", privileged: true #, run: "never"
    winw1.vm.provision "shell", path: "forked/PrepareNode.ps1", privileged: true, args: "-KubernetesVersion #{kubernetes_compatibility} -ContainerRuntime containerD #{overwrite_windows_bins }" #, run: "never"
    winw1.vm.provision "shell", path: "sync/shared/kubejoin.ps1", privileged: true #, run: "never"

    # TODO shoudl we pass KuberneteVersion to calico agent exe? and also service cidr if needed?
    if settings['cni'].equal? "calico" then
      winw1.vm.provision "shell", path: "forked/0-calico.ps1", privileged: true #, run: "always"
    else         
      # Experimental at the moment...
      winw1.vm.provision "shell", path: "forked/0-antrea.ps1", privileged: true #, run: "always"
      winw1.vm.provision "shell", path: "forked/1-antrea.ps1", privileged: true, args: "-KubernetesVersion #{kubernetes_compatibility}" #, run: "always"
    end
  end
  
end
