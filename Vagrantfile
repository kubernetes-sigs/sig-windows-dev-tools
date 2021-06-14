# -*- mode: ruby -*-
# vi: set ft=ruby :

=begin
Copyright 2021 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

require 'yaml'
settings = YAML.load_file 'sync/shared/variables.yaml'
kubernetes_version_linux = settings['kubernetes_version_linux']
kubernetes_version_windows = settings['kubernetes_version_windows']

Vagrant.configure(2) do |config|

  # LINUX Control Plane
  config.vm.define :controlplane do |controlplane|
    controlplane.vm.host_name = "controlplane"
    controlplane.vm.box = "ubuntu/focal64"
    controlplane.vm.network :private_network, ip:"10.20.30.10"
    controlplane.vm.provider :virtualbox do |vb|
    controlplane.vm.synced_folder "./sync/shared", "/var/sync/shared"
    controlplane.vm.synced_folder "./sync/linux", "/var/sync/linux"
      vb.memory = 8192
      vb.cpus = 4
    end
    controlplane.vm.provision :shell, privileged: false, path: "sync/linux/controlplane.sh", args: "#{kubernetes_version_linux}"
  end

  # WINDOWS WORKER (win server 2019)
  config.vm.define :winw1 do |winw1|
    winw1.vm.host_name = "winw1"
    winw1.vm.box = "StefanScherer/windows_2019"  
    winw1.vm.network :private_network, ip:"10.20.30.11"
    winw1.vm.synced_folder ".", "/vagrant", disabled:true
    winw1.vm.synced_folder "./sync/shared", "C:\\sync\\shared"
    winw1.vm.synced_folder "./sync/windows", "C:\\sync\\windows"
    winw1.vm.provider :virtualbox do |vb|
      vb.memory = 8192
      vb.cpus = 4
      vb.gui = false
    end

    #THIS this now happens in /forked/PrepareNode.ps1
    #winw1.vm.provision "file", source: settings['kubelet_path'] , destination: "C:/k/kubelet.exe"
    #winw1.vm.provision "file", source: settings['kubeproxy_path'] , destination: "C:/k/kube-proxy.exe"

    ## uncomment the 'run' values if debugging CNI ....

    winw1.vm.provision "shell", path: "sync/windows/hyperv.ps1", privileged: true #, run: "never"
    winw1.vm.provision :reload

    winw1.vm.provision "shell", path: "sync/windows/containerd1.ps1", privileged: true #, run: "never"
    winw1.vm.provision :reload

    winw1.vm.provision "shell", path: "sync/windows/containerd2.ps1", privileged: true #, run: "never"

    winw1.vm.provision "shell", path: "forked/PrepareNode.ps1", privileged: true, args: "-KubernetesVersion #{kubernetes_version_windows} -ContainerRuntime containerD" #, run: "never"

    winw1.vm.provision "shell", path: "sync/shared/kubejoin.ps1", privileged: true #, run: "never"

    # Experimental at the moment...
    winw1.vm.provision "shell", path: "forked/0-antrea.ps1", privileged: true #, run: "always"
    winw1.vm.provision "shell", path: "forked/1-antrea.ps1", privileged: true, args: "-KubernetesVersion #{kubernetes_version_windows}" #, run: "always"

  end
  
end
