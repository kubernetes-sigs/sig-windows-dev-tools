# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
require 'fileutils'

# Modify these in the variables.yaml file... they are described there in gory detail...
# This will get copied down later to synch/shared/variables... and read by the controlplane.sh etc...
settingsFile = "variables.yaml" || ENV["VAGRANT_VARIABLES"]
FileUtils.cp(settingsFile, "sync/shared/variables.yaml")
settings = YAML.load_file settingsFile


kubernetes_version=settings["kubernetes_version"]
k8s_linux_kubelet_nodeip=settings['k8s_linux_kubelet_nodeip']
pod_cidr=settings['pod_cidr']
calico_version=settings['calico_version']
containerd_version=settings['containerd_version']


linux_ram = settings['linux_ram']
linux_cpus = settings['linux_cpus']
windows_ram = settings['windows_ram']
windows_cpus = settings['windows_cpus']
windows_node_ip = settings['windows_node_ip']

cni = settings['cni']

Vagrant.configure(2) do |config|
  puts "cni: #{cni}"

#   LINUX Control Plane
  config.vm.define :controlplane do |controlplane|
    controlplane.vm.host_name = "controlplane"
    controlplane.vm.box = "roboxes/ubuntu2004"

    controlplane.vm.network :private_network, ip:"#{k8s_linux_kubelet_nodeip}"

    controlplane.vm.synced_folder ".", "/vagrant", disabled: true
    controlplane.vm.synced_folder "./sync/shared", "/var/sync/shared", type: "rsync"
    controlplane.vm.synced_folder "./forked", "/var/sync/forked", type: "rsync"
    controlplane.vm.synced_folder "./sync/linux", "/var/sync/linux", type: "rsync"
    controlplane.vm.network "private_network", ip: "10.20.30.10"

    controlplane.vm.provider "qemu" do |qe|
      qe.memory = linux_ram
      qe.arch = "x86_64"

      # need for x86_64
      qe.machine = "q35"
      qe.cpu = "qemu64"
      qe.net_device = "virtio-net-pci"
      qe.extra_netdev_args = "net=10.20.30.0/24,dhcpstart=10.20.30.10"

      print "qemu loop"
    end

    ### This allows the node to default to the right IP i think....
    # 1) this seems to break the ability to get to the internet

    controlplane.vm.provision :shell, privileged: false, path: "sync/linux/controlplane.sh", args: "#{kubernetes_version} #{k8s_linux_kubelet_nodeip} #{pod_cidr}"

    # TODO shoudl we pass KuberneteVersion to calico agent exe? and also service cidr if needed?
    # dont run as priveliged cuz we need the kubeconfig from regular user
    if cni == "calico" then
      controlplane.vm.provision "shell", path: "sync/linux/calico-0.sh", args: "#{pod_cidr} #{calico_version}"
    else
      controlplane.vm.provision "shell", path: "sync/linux/antrea-0.sh"
    end
  end


  config.vm.define "winw1" do |winw1|
    winw1.vm.box = "sig-windows-dev-tools/windows-2019"
     windows_box_path = File.expand_path("../../boxes/sig-windows-dev-tools-windows-2019.qcow2", __FILE__)



     #winw1.vm.network :forwarded_port, guest: 5986, host: 55986
     #winw1.vm.network :forwarded_port, guest: 2222, host: 50024
     #winw1.vm.network :forwarded_port, guest:2222, host:50025
     #config.vm.network :forwarded_port, guest:2222, host:50026

     winw1.vm.provider :qemu do |qemu|
	  qemu.arch = "x86_64"
	  qemu.memory = windows_ram
	  qemu.machine = "q35"
	  qemu.cpu = "qemu64"
	  qemu.net_device = "e1000"
	  qemu.drive_interface = "ide"
	  # without this you get port collision and vagrant vm wont come up
	  qemu.ssh_port = 50023

	  qemu.command_line = [
	    "-device", "virtio-net-pci,netdev=net0",
	    "-netdev", "user,id=net0,hostfwd=tcp::50023:22,hostfwd=tcp::3333:22,hostfwd=tcp::55985:5985,hostfwd=tcp::55986:5986",
	    "-drive", "file=#{windows_box_path},format=qcow2,if=none,id=hd0",
	    "-device", "ide-hd,bus=ide.0,drive=hd0",
	    "-object", "rng-random,filename=/dev/random,id=rng0",
	    "-device", "virtio-rng-pci,rng=rng0",
	  ]
	  qemu.extra_netdev_args = "net=10.20.30.0/24,dhcpstart=10.20.30.20"
    end

    winw1.vm.provision "shell", inline: "echo Hello, World!"
    
    winw1.vm.communicator = "winrm"
    winw1.winrm.username = "vagrant"
    winw1.winrm.password = "vagrant"
    winw1.winrm.port = 5986 # WinRM HTTPS port
    winw1.winrm.transport = :ssl
    winw1.winrm.ssl_peer_verification = false
  end
end
