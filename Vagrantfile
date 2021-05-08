# -*- mode: ruby -*-
# vi: set ft=ruby :
# TODO create a Kubernetes (+ Kind) vagrant box for win server 2019 ()  

Vagrant.configure(2) do |config|

  # LINUX MASTER
  config.vm.define :master do |master|
    master.vm.host_name = "master"
    master.vm.box = "ubuntu/focal64"
    master.vm.network :private_network, ip:"10.20.30.10"
    master.vm.provider :virtualbox do |vb|
    master.vm.synced_folder "./sync", "/var/sync"
      vb.memory = 2048
      vb.cpus = 2
    end
    master.vm.provision :shell, privileged: false, path: "sync/master.sh"
  end

  # WINDOWS WORKER (win server 2019)
  config.vm.define :winw1 do |winw1|
    winw1.vm.host_name = "winw1"
    winw1.vm.box = "StefanScherer/windows_2019"  
    winw1.vm.provider :virtualbox do |vb|
      vb.memory = 8192 # 8GB memory is the normal min for windows clusters
      vb.cpus = 4 # 2 cores will be flakey on the join and RDP performance
      vb.gui = true
    end
    winw1.vm.network :private_network, ip:"10.20.30.11"
    winw1.vm.synced_folder "./sync", "c:\\sync"

    ### for Containerd support
    #winw1.vm.provision "shell", path: "sync/hyperv.ps1", privileged: true
    #winw1.vm.provision :reload
    #winw1.vm.provision "shell", path: "sync/containerd1.ps1", privileged: true
    #winw1.vm.provision :reload
    #winw1.vm.provision "shell", path: "sync/containerd2.ps1", privileged: true

    winw1.vm.provision "shell", path: "sync/docker.ps1", privileged: true
    winw1.vm.provision :reload
    winw1.vm.provision "shell", path: "sync/k.ps1", privileged: true
    winw1.vm.provision "shell", path: "sync/join.ps1", privileged: true
  end
  
end
