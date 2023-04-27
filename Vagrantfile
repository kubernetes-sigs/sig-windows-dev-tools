# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
require 'fileutils'

# Magefiles search for user-specific variables.local.yaml and set ENV[VAGRANT_VARIABLES],
# otherwise fallback to use the provided variables.yaml with default settings.
# The settings file is also copied to sync/shared/variables.yaml and used by controlplane scripts.
settingsFile = ENV["VAGRANT_VARIABLES"] || "variables.yaml"
if ENV["VAGRANT_VARIABLES"]
  puts "[Vagrantfile] Loading settings from ENV[VAGRANT_VARIABLES]=#{settingsFile}"
else
  puts "[Vagrantfile] Loading default settings from #{settingsFile}"
end
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

  ############ Linux Control Plane node ############
  config.vm.define :controlplane do |controlplane|
    controlplane.vm.host_name = "controlplane"
    controlplane.vm.box = "mloskot/sig-windows-dev-tools-ubuntu-2204"
    controlplane.vm.box_version = "1.0"
    controlplane.vm.boot_timeout = 900

    controlplane.vm.network :private_network, ip:"#{k8s_linux_kubelet_nodeip}"
    controlplane.vm.provider :virtualbox do |vb|
      vb.memory = linux_ram
      vb.cpus = linux_cpus
      vb.gui = false
      # Explicitly  Windows guest version and type
      vb.customize ["modifyvm", :id, "--ostype", 'Ubuntu22_LTS_64']
      # Enabling I/O APIC is required for 64-bit guests
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
      # Force newer VirtualBox default graphics controller for Linux guests
      vb.customize ['modifyvm', :id, '--graphicscontroller', 'vmsvga']
      # Explicitly disable unnecessary features for better performance
      vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
      vb.customize ["modifyvm", :id, "--accelerate2dvideo", "off"]
      vb.customize ['modifyvm', :id, '--clipboard', 'disabled']
      vb.customize ['modifyvm', :id, '--draganddrop', 'disabled']
      vb.customize ['modifyvm', :id, '--vrde', 'off']
    end
    
    controlplane.vm.synced_folder ".", "/vagrant", disabled:true
    controlplane.vm.synced_folder "./sync/shared", "/var/sync/shared"
    controlplane.vm.synced_folder "./forked", "/var/sync/forked"
    controlplane.vm.synced_folder "./sync/linux", "/var/sync/linux"

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

  ############ Windows worker node #1 ############
  config.vm.define :winw1 do |winw1|
    winw1.vm.box = "mloskot/sig-windows-dev-tools-windows-2019"
    winw1.vm.box_version = "1.0"
    winw1.vm.communicator = "winrm"
    winw1.vm.guest = :windows
    winw1.vm.boot_timeout = 900

    winw1.vm.provider :virtualbox do |vb|
      vb.memory = windows_ram
      vb.cpus = windows_cpus
      vb.gui = false
      # Explicitly  Windows guest version and type
      vb.customize ["modifyvm", :id, "--ostype", 'Windows2019_64']
      # Enabling I/O APIC is required for 64-bit guests
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
      # Explicitly use Windows guest default graphics controller
      vb.customize ['modifyvm', :id, '--graphicscontroller', 'vboxsvga']
      # Explicitly disable unnecessary features for better performance
      vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
      vb.customize ["modifyvm", :id, "--accelerate2dvideo", "off"]
      vb.customize ['modifyvm', :id, '--clipboard', 'disabled']
      vb.customize ['modifyvm', :id, '--draganddrop', 'disabled']
      vb.customize ['modifyvm', :id, '--vrde', 'off']
    end

    winw1.vm.network :private_network, ip:"#{windows_node_ip}"
    winw1.vm.synced_folder ".", "/vagrant", disabled:true
    winw1.vm.synced_folder "./sync/shared", "C:/sync/shared"
    winw1.vm.synced_folder "./sync/windows/", "C:/sync/windows/"
    winw1.vm.synced_folder "./forked", "C:/forked/"

    winw1.winrm.username = "vagrant"
    winw1.winrm.password = "vagrant"

    if not File.file?(".lock/joined") then
      # Update containerd
      winw1.vm.provision "shell", path: "sync/windows/0-containerd.ps1", args: "#{calico_version} #{containerd_version}", privileged: true

      # Joining the controlplane
      winw1.vm.provision "shell", path: "sync/windows/forked.ps1", args: "#{kubernetes_version}", privileged: true
      # TODO: Why this is required? From Makefile: making mock kubejoin file to keep Vagrantfile happy in sync/shared
      FileUtils.touch("sync/shared/kubejoin.ps1") unless File.exist?("sync/shared/kubejoin.ps1")
      winw1.vm.provision "shell", path: "sync/shared/kubejoin.ps1", privileged: true #, run: "never"
    else
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
    end
  end
end
