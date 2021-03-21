# TODO automate script for Linux: Docker, Windows, Firewall, Swap
# TODO create a Kubernetes (+ Kind) vagrant box for win server 2019 ()  

Vagrant.configure("2") do |config|
  config.vm.provider :virtualbox do |v|
    # consider adjusting this for your machine
    #v.memory = 2048
    #v.cpus = 2
  end

  config.vm.define :master do |master|    
    master.memory = 1024
    master.cpus = 1
    master.vm.box = "ubuntu/focal64"
    master.vm.hostname = "master"
    master.vm.network :private_network, ip: "10.0.0.10"
  end

   config.vm.define :windowsWorker1 do |windowsWorker1|
    windowsWorker1.memory = 4096
    windowsWorker1.cpus = 2
    windowsWorker1.vm.box = "StefanScherer/windows_2019"     
    windowsWorker1.vm.hostname = "windowsWorker1"
    windowsWorker1.vm.network :private_network, ip: "10.0.0.11"
  end
  
  # add/remove as you need
#  config.vm.define :linuxWorker1 do |linuxWorker1|
#    linuxWorker1.memory = 1024
#    linuxWorker1.cpus = 1
#    linuxWorker1.vm.box = "ubuntu/focal64"
#    linuxWorker1.vm.hostname = "linuxWorker1"
#    linuxWorker1.vm.network :private_network, ip: "10.0.0.12"
#  end

end
