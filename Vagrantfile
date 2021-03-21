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
  end

  config.vm.define :winWorker1 do |winWorker1|
      winWorker1.vm.host_name = "winWorker1"
      winWorker1.vm.box = "StefanScherer/windows_2019"  
      winWorker1.vm.network :private_network, ip:"10.0.0.11"
      winWorker1.vm.provider :virtualbox do |vb|
          vb.memory = 4096
          vb.cpus = 2
          vb.gui = true
      end
  end
	
end
