# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
require 'fileutils'

# Magefiles search for user-specific settings.local.yaml and set ENV[SWDT_SETTINGS_FILE],
# otherwise fallback to use the provided settings.yaml with default settings.
# The settings file is also copied to sync/shared/settings.yaml and used by controlplane scripts.
settingsFile = ENV["SWDT_SETTINGS_FILE"] || "settings.yaml"
if ENV["SWDT_SETTINGS_FILE"]
  puts "[Vagrantfile] Loading settings from ENV[SWDT_SETTINGS_FILE]=#{settingsFile}"
else
  puts "[Vagrantfile] Loading default settings from #{settingsFile}"
end
FileUtils.cp(settingsFile, "sync/shared/settings.yaml")
settings = YAML.load_file settingsFile

cfg_kubernetes_version=settings["kubernetes_version"]
cfg_calico_version=settings["calico_version"]
cfg_containerd_version=settings["containerd_version"]
cfg_linux_box = settings["vagrant_linux_box"]
cfg_linux_box_version = settings["vagrant_linux_box_version"]
cfg_linux_ram = settings["vagrant_linux_ram"]
cfg_linux_cpus = settings["vagrant_linux_cpus"]
cfg_linux_node_ip=settings["linux_node_ip"]
cfg_windows_box = settings["vagrant_windows_box"]
cfg_windows_box_version = settings["windows_box_version"]
cfg_windows_ram = settings["vagrant_windows_ram"]
cfg_windows_cpus = settings["vagrant_windows_cpus"]
cfg_windows_node_ip = settings["windows_node_ip"]
cfg_cni = settings["cni"]
cfg_pod_cidr=settings["pod_cidr"]

Vagrant.configure(2) do |config|
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = settings["vagrant_vbguest_auto_update"]
  end

  ############ Linux Control Plane node ############
  config.vm.define :controlplane do |controlplane|
    controlplane.vm.host_name = "controlplane"
    controlplane.vm.box = cfg_linux_box
    controlplane.vm.box_version = cfg_linux_box_version
    controlplane.vm.boot_timeout = 900

    controlplane.vm.network :private_network, ip:"#{cfg_linux_node_ip}"
    controlplane.vm.provider :virtualbox do |vb|
      vb.memory = cfg_linux_ram
      vb.cpus = cfg_linux_cpus
      vb.gui = false
      # Explicitly set guest version and type
      vb.customize ['modifyvm', :id, '--ostype', 'Ubuntu22_LTS_64']
      # Enabling I/O APIC is required for 64-bit guests
      vb.customize ['modifyvm', :id, '--ioapic', 'on']
      # Force newer VirtualBox default graphics controller for Linux guests
      vb.customize ['modifyvm', :id, '--graphicscontroller', 'vmsvga']
      # Explicitly disable unnecessary features for better performance
      vb.customize ["modifyvm", :id, '--accelerate3d', "off"]
      vb.customize ["modifyvm", :id, '--accelerate2dvideo', "off"]
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

    controlplane.vm.provision :shell, privileged: false, path: "sync/linux/controlplane.sh", args: "#{cfg_kubernetes_version} #{cfg_linux_node_ip} #{cfg_pod_cidr}"

    # TODO shoudl we pass KuberneteVersion to calico agent exe? and also service cidr if needed?
    # dont run as priveliged cuz we need the kubeconfig from regular user
    if cfg_cni == "calico" then
      controlplane.vm.provision "shell", path: "sync/linux/calico-0.sh", args: "#{cfg_pod_cidr} #{cfg_calico_version}"
    else
      controlplane.vm.provision "shell", path: "sync/linux/antrea-0.sh"
    end
  end

  ############ Windows worker node #1 ############
  config.vm.define :winw1 do |winw1|
    winw1.vm.box = cfg_windows_box
    winw1.vm.box_version = cfg_windows_box_version
    winw1.vm.communicator = "winrm"
    winw1.vm.guest = :windows
    winw1.vm.boot_timeout = 900

    winw1.vm.provider :virtualbox do |vb|
      vb.memory = cfg_windows_ram
      vb.cpus = cfg_windows_cpus
      vb.gui = false
      # Explicitly set guest version and type
      vb.customize ['modifyvm', :id, '--ostype', 'Windows2019_64']
      # Enabling I/O APIC is required for 64-bit guests
      vb.customize ['modifyvm', :id, '--ioapic', 'on']
      # Explicitly use Windows guest default graphics controller
      vb.customize ['modifyvm', :id, '--graphicscontroller', 'vboxsvga']
      # Explicitly disable unnecessary features for better performance
      vb.customize ['modifyvm', :id, '--accelerate3d', 'off']
      vb.customize ['modifyvm', :id, '--accelerate2dvideo', 'off']
      vb.customize ['modifyvm', :id, '--clipboard', 'disabled']
      vb.customize ['modifyvm', :id, '--draganddrop', 'disabled']
      vb.customize ['modifyvm', :id, '--vrde', 'off']
    end

    winw1.vm.network :private_network, ip:"#{cfg_windows_node_ip}"
    winw1.vm.synced_folder ".", "/vagrant", disabled:true
    winw1.vm.synced_folder "./sync/shared", "C:/sync/shared"
    winw1.vm.synced_folder "./sync/windows/", "C:/sync/windows/"
    winw1.vm.synced_folder "./forked", "C:/forked/"

    winw1.winrm.username = "vagrant"
    winw1.winrm.password = "vagrant"

    if not File.file?(".lock/joined") then
      # Update containerd
      winw1.vm.provision "shell", path: "sync/windows/0-containerd.ps1", args: "#{cfg_calico_version} #{cfg_containerd_version}", privileged: true

      # Joining the controlplane
      winw1.vm.provision "shell", path: "sync/windows/forked.ps1", args: "#{cfg_kubernetes_version}", privileged: true
      # TODO: Why this is required? From old Makefile: making mock kubejoin file to keep Vagrantfile happy in sync/shared
      FileUtils.touch("sync/shared/kubejoin.ps1") unless File.exist?("sync/shared/kubejoin.ps1")
      winw1.vm.provision "shell", path: "sync/shared/kubejoin.ps1", privileged: true #, run: "never"
    else
      if not File.file?(".lock/cni") then
        if cfg_cni == "calico" then
          # we don't need to run Calico agents as service now,
          # calico will be installed as a HostProcess container
          # installs both felix and node
          #winw1.vm.provision "shell", path: "sync/windows/0-calico.ps1", privileged: true
          #winw1.vm.provision "shell", path: "sync/windows/1-calico.ps1", privileged: true
        else
          winw1.vm.provision "shell", path: "sync/windows/0-antrea.ps1", privileged: true #, run: "always"
          winw1.vm.provision "shell", path: "sync/windows/1-antrea.ps1", privileged: true, args: "#{cfg_windows_node_ip}" #, run: "always"
        end
      end
    end
  end
end
