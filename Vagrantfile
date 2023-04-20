# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
require 'fileutils'

# Give user-defined variables file higher precedence, for example, make.ps1
# searches for user-specific variables.local.yaml and assigns VAGRANT_VARIABLES.
# Otherwise, use the provided variables.yaml with defaults.
# This settings file will be copied to sync/shared/variables.yaml for controlplane.sh.
settingsFile = ENV["VAGRANT_VARIABLES"] || "variables.yaml"
puts "[Vagrantfile] settings: #{settingsFile}"
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
  puts "[Vagrantfile] cni: #{cni}"

  config.vagrant.plugins = ["vagrant-vbguest"]

  #   LINUX Control Plane
  config.vm.define :controlplane do |controlplane|
    controlplane.vm.host_name = "controlplane"
    controlplane.vm.box = "roboxes/ubuntu2204"
    controlplane.vm.boot_timeout = 900

    # Workaround for missing libraries on Debian 11, Ubuntu 22.04 and later boxes:
    # /opt/VBoxGuestAdditions-7.0.2/bin/VBoxClient: error while loading shared libraries: libXt.so.6: cannot open shared object file: No such file or directory
    # See https://github.com/dotless-de/vagrant-vbguest/issues/425#issuecomment-1515225030
    controlplane.vbguest.installer_hooks[:before_install] = [
      "apt-get update",
      "apt-get -y install libxt6 libxmu6"
    ]
    controlplane.vbguest.installer_hooks[:after_install] = [
      "VBoxClient --version"
    ]
    controlplane.vbguest.installer_options = { allow_kernel_upgrade: true }

    controlplane.vm.network :private_network, ip:"#{k8s_linux_kubelet_nodeip}"
    controlplane.vm.provider :virtualbox do |vb|
    controlplane.vm.synced_folder "./sync/shared", "/var/sync/shared"
    controlplane.vm.synced_folder "./forked", "/var/sync/forked"
    controlplane.vm.synced_folder "./sync/linux", "/var/sync/linux"
      vb.memory = linux_ram
      vb.cpus = linux_cpus
      # Enabling I/O APIC is required for 64-bit guests
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
      # Force newer VirtualBox default graphics controller for Linux guests
      vb.customize ['modifyvm', :id, '--graphicscontroller', 'vmsvga']
      # Explicitly disable unnecessary features for better performance
      vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
      vb.customize ["modifyvm", :id, "--accelerate2dvideo", "off"]
      vb.customize ['modifyvm', :id, '--clipboard', 'disabled']
      vb.customize ['modifyvm', :id, '--draganddrop', 'disabled']
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
    winw1.vm.host_name = "winw1"
    winw1.vm.box = "sig-windows-dev-tools/windows-2019"
    winw1.vm.box_version = "1.0"
    winw1.vm.boot_timeout = 900

    winw1.vm.provider :virtualbox do |vb|
      vb.memory = windows_ram
      vb.cpus = windows_cpus
      # Enabling I/O APIC is required for 64-bit guests
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
      # Explicitly use Windows guest default graphics controller
      vb.customize ['modifyvm', :id, '--graphicscontroller', 'vboxsvga']
      # Explicitly disable unnecessary features for better performance
      vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
      vb.customize ["modifyvm", :id, "--accelerate2dvideo", "off"]
      vb.customize ['modifyvm', :id, '--clipboard', 'disabled']
      vb.customize ['modifyvm', :id, '--draganddrop', 'disabled']
      # Use paravirtualization provider VirtualBox recommends for Windows guests
      vb.customize ["modifyvm", :id, "--paravirt-provider", "hyperv"]
      vb.gui = false
    end

    winw1.vm.network :private_network, ip:"#{windows_node_ip}"
    winw1.vm.synced_folder ".", "/vagrant", disabled:true
    winw1.vm.synced_folder "./sync/shared", "C:/sync/shared"
    winw1.vm.synced_folder "./sync/windows/", "C:/sync/windows/"
    winw1.vm.synced_folder "./forked", "C:/forked/"

    winw1.winrm.username = "vagrant"
    winw1.winrm.password = "vagrant"

    # Turn off Windows Firewall for apparent better performance
    winw1.vm.provision "shell", inline: "netsh advfirewall set allprofiles state off"

    if not File.file?(".lock/joined") then
      # Update containerd
      puts "[Vagrantfile] calico: #{calico_version}; containerd: #{containerd_version}"
      winw1.vm.provision "shell", path: "sync/windows/0-containerd.ps1", args: "#{calico_version} #{containerd_version}", privileged: true

      # Joining the controlplane
      winw1.vm.provision "shell", path: "sync/windows/forked.ps1", args: "#{kubernetes_version}", privileged: true
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
