# TODO automate script for Linux: Docker, Windows, Firewall, Swap
# TODO create a Kubernetes (+ Kind) vagrant box for win server 2019 ()  

Vagrant.configure("2") do |config|
  config.vm.provider :virtualbox do |v|
    # consider adjusting this for your machine
    v.memory = 2048
    v.cpus = 2
  end


  config.vm.define :master do |master|
    master.vm.box = "ubuntu/focal64"
    master.vm.hostname = "master"
    master.vm.network :private_network, ip: "10.0.0.10"
  end

   config.vm.define :master do |master|
    master.vm.box = "ubuntu/focal64"
    master.vm.hostname = "windowsWorker1"
    master.vm.network :private_network, ip: "10.0.0.11"
  end
  
  # add/remove as you need
#  config.vm.define :worker1 do |worker1|
#   worker1.vm.box = "ubuntu/focal64"
#    worker1.vm.hostname = "linuxWorker1"
#    worker1.vm.network :private_network, ip: "10.0.0.12"
#  end

end
