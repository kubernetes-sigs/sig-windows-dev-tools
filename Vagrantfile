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

  # WINDOWS WORKER (win server 2019)
  config.vm.define :winw1 do |winw1|

    # SSH doesnt work bc comnuicator.rb fails w/ windows and tries to use bash to provision
    winw1.vm.communicator = "winrm"
    #winw1.vm.winrm.port = "5985"
    #winw1.winrm.port = "5985"
    
    # Add the forwarded port rule that you need

    
    winw1.vm.host_name = "winw1"
    winw1.vm.communicator = "winrm"
    winw1.winrm.username = "vagrant"
    winw1.winrm.password = "vagrant"
    winw1.winrm.port = 5986 # WinRM HTTPS port
    winw1.winrm.transport = :ssl
    winw1.winrm.ssl_peer_verification = false
    winw1.vm.box = "sig-windows-dev-tools/windows-2019"

    # Doesnt support qemu...
    # winw1.vm.box = "mloskot/sig-windows-dev-tools-windows-2019"
    winw1.vm.box_version = "1.0"
    winw1.vm.network :private_network, ip:"#{windows_node_ip}"
    winw1.vm.provider "qemu" do |qe, override|
      qe.vm.network "private_network", type: "dhcp", ip: "10.20.30.20"
      qe.arch = "x86_64"
      qe.memory = windows_ram
      # need for x86_64
      qe.machine = "q35"
      qe.cpu = "qemu64"

      # devices compatible with this box
      qe.net_device = "e1000"
      qe.drive_interface = "ide"
      qe.ssh_port = 50023
      
      qe.extra_netdev_args = "net=10.20.30.0/24,dhcpstart=10.20.30.20"

      # use password (use winrm?)
      override.ssh.username = "vagrant"
      override.ssh.password = "vagrant"
    end

    winw1.vm.network :private_network, ip:"#{windows_node_ip}"
    winw1.vm.synced_folder ".", "/vagrant", disabled:true
    winw1.vm.synced_folder "./sync/shared", "C:/sync/shared"
    winw1.vm.synced_folder "./sync/windows/", "C:/sync/windows/"
    winw1.vm.synced_folder "./forked", "C:/forked/"

    winw1.winrm.username = "vagrant"
    winw1.winrm.password = "vagrant"

    puts "0"

    if not File.file?(".lock/joined") then
      puts "1"

      # Update containerd
     puts "calico: #{calico_version}; containerd: #{containerd_version}"
     winw1.vm.provision "shell", path: "sync/windows/0-containerd.ps1", args: "#{calico_version} #{containerd_version}", privileged: true

      puts "2"

      # Joining the controlplane
      winw1.vm.provision "shell", path: "sync/windows/forked.ps1", args: "#{kubernetes_version}", privileged: true

      puts "2.1"

      winw1.vm.provision "shell", path: "sync/shared/kubejoin.ps1", privileged: true #, run: "never"

      puts "[done defining win provisioning 1]"

    else
      puts "3"

      if not File.file?(".lock/cni") then
        if cni == "calico" then
          # we don't need to run Calico agents as service now,
          # calico will be installed as a HostProcess container
          # installs both felix and node
          #winw1.vm.provision "shell", path: "sync/windows/0-calico.ps1", privileged: true
          #winw1.vm.provision "shell", path: "sync/windows/1-calico.ps1", privileged: true
        else
          winw1.vm.provision "shell", path: "sync/windows/0-antrea.ps1", privileged: true #, run: "always"
          winw1.vm.provision "shell", path: "sync/windows/1-antrea.ps1", privileged: true, args: "#{windows_node_ip}" #, run: "always"
        end
      end
    puts "[done defining win provisioning 2]"
    end
  end
end
