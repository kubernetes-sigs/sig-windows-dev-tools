# Image-builder for Windows Nodes

This folder hosts the necessary tools to build and ship Windows node images builded from zero.
It uses `image-builder` and few custom customization to provide a build-in CNI and proper configuration,
the machine here is intend to be used into the `sig-windows-dev-tools` repository primarly. 

Only the VirtualBox hypervisor is fully tested, but OVA images building can be made as well.

## Running

After getting the ISO from MSDN inform it via the `VBOX_WINDOWS_ISO` environment variable.

```
cd image-builder
VBOX_WINDOWS_ISO=file:/tmp/windows-2019.iso ./image-builder.sh
```

Use `DEBUG=1` to enable verbosity in the build.

## What is included in the node

The official `image-builder` for Windows nodes already includes a few Kubernetes artifacts, plus
the ones added by this project:

1. Kubeadm
2. Kubelet
3. Kubectl
4. CNI plugins

NOTE 1: These files are coming from a burrito installation
NOTE 2: This script MUST support both Calico or Antrea installation.

### Steps required on Vagrant

It's still required to join the control plane, and this step is required 
via Kubejoin, with a provision, this is an usage example:

```
winw1.vm.provision "shell", path: "sync/shared/kubejoin.ps1", privileged: true
```

## How image-builder creates the image

![Image builder Diagram](images/diagram.jpg "Image-builder diagram")

The intent of this section is to describe with more details how image-builder runs
and generates the final Windows node. Since the steps here a focused on Vagrant boxes,
to the local node build for Windows 2019 target is used.

```
cd images/capi
make build-node-vbox-local-windows-2019
```

At this point the only necessary part is the [MSDN Windows ISO](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019), 
the Evaluation version is fine to be used here.

### Packer

[Packer](https://www.packer.io) is the default system used by `image-builder` to build all target nodes, it is modularized enough
to use different Hypervisors, for this project it is being used the [Virtualbox](https://www.packer.io/docs/builders/virtualbox/iso) 
with ISO mode generation. When running the make target packer is invoked and here is a breakdown of the command line arguments:

```
$ packer build                                                          \

## Common Configuration files

-var-file="images/capi/packer/config/kubernetes.json"                    \
-var-file="images/capi/packer/config/containerd.json"                    \
-var-file="images/capi/packer/config/goss-args.json"                     \
-var-file="images/capi/packer/config/additional_components.json"         \  

## Windows specific configuration files

-var-file="images/capi/packer/config/windows/kubernetes.json"            \ 
-var-file="images/capi/packer/config/windows/containerd.json"            \
-var-file="images/capi/packer/config/windows/docker.json"                \
-var-file="images/capi/packer/config/windows/ansible-args-windows.json"  \
-var-file="images/capi/packer/config/windows/common.json"                \ 
-var-file="images/capi/packer/config/windows/cloudbase-init.json"        \
    
## Virtualbox Windows specific configuration

-var-file="packer/vbox/packer-common.json"                               \
-var-file="images/capi/packer/vbox/windows-2019.json"                    \

# Builder choice -only=vmware-iso is the important filter.

-except=esx                                                              \
-except=vsphere                                                          \
-only=vmware-iso                                                         \

# Packer Windows Configuration

packer/vbox/packer-windows.json
```

These configurations files does not matters much until now, they will exists in the default target
install, the way to [extend these values](https://image-builder.sigs.k8s.io/capi/capi.html#customization) is to add
more custom configuration JSON files via the `PACKER_VAR_FILES` environment variable, these fiels are going to take 
precedence over the existent values. 

### Breaking down packer-windows.json

An important part is the configuration file used by packer, it's divided in 4 sections:

* builders - responsible for creating machines and generating images from them for various platforms.
* post-processors - run after the image is built by the builder and provisioned by the provisioner(s).
* provisioners - use builtin and third-party software to install and configure the machine image after booting. 
* variables - User variables allow your templates to be further configured with variables from the command-line, environment variables, Vault, or files. 

### VirtualBox-iso builder

All fields comments are in the official documentation, a few of them are interesting to notice.
It's being used `winrm` communicator this is enabled as the last step of the bootstrap of the guest
machine, as noted in the floppy files listing. 

The other important scripting here is the `autounattend.xml` or 
[Automated Windows Setup](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/automate-windows-setup), this XML
is reponsible to setup a few settings in the bootstrap time, it can be generated using [Windows AFG](https://www.windowsafg.com/server2019.html):

* General install settings
* Regional configuration
* Out of Box Experience settings
* Windows Update Settings
* Partition creation
* User Account information

Example of default builder settings:

```
{
    "boot_wait": "{{user `boot_wait`}}",
    "communicator": "winrm",
    "cpus": "{{user `cpu`}}",
    "disk_size": "{{user `disk_size`}}",
    "floppy_files": [
    "./packer/vbox/windows/{{user `build_name`}}/autounattend.xml",
    "./packer/vbox/windows/disable-network-discovery.cmd",
    "./packer/vbox/windows/disable-winrm.ps1",
    "./packer/vbox/windows/enable-winrm.ps1",
    "./packer/vbox/windows/sysprep.ps1"
    ],
    "guest_additions_mode": "disable",
    "guest_os_type": "{{user `local_guest_os_type`}}",
    "iso_checksum": "{{user `iso_checksum`}}",
    "iso_urls": [
    "{{user `os_iso_url`}}"
    ],
    "memory": "{{user `memory`}}",
    "name": "virtualbox-iso",
    "output_directory": "{{user `output_dir`}}",
    "shutdown_command": "powershell A:/sysprep.ps1",
    "shutdown_timeout": "1h",
    "type": "virtualbox-iso",
    "vm_name": "{{user `build_version`}}",
    "winrm_password": "S3cr3t0!",
    "winrm_timeout": "4h",
    "winrm_username": "Administrator"
}
```

## Exporting with post processing

In other jobs we the post-processor job uses a Python script to generate the OVA image. For this builder
a final compressed image for Vagrant is generated. The output `output/windows-2019.box` can be used
directly in the Vagrantfile, or uploaded to a repository on Vagrantup.

As noted a Vagrantfile template is provided as well.

```
{
    "keep_input_artifact": false,
    "output": "{{ user `output_dir`}}/windows-2019.box",
    "type": "vagrant",
    "vagrantfile_template": "./packer/vbox/vagrantfile-windows_2019.template"
}
```

### Ansible provisioning

The next step is to provision the machine with Ansible scripts, `ansible_*_vars` from variables
are the way to configure Ansible here:

```
{
    "extra_arguments": [
    "-e",
    "ansible_winrm_scheme=http",
    "--extra-vars",
    "{{user `ansible_common_vars`}}",
    "--extra-vars",
    "{{user `ansible_extra_vars`}}",
    "--extra-vars",
    "{{user `ansible_user_vars`}}"
    ],
    "playbook_file": "ansible/windows/node_windows.yml",
    "type": "ansible",
    "use_proxy": false,
    "user": "Administrator"
},
```

Breaking down the Ansible running command here:

```
ansible-playbook \
-e packer_build_name="virtualbox-iso" 
-e packer_builder_type=virtualbox-iso 
-e packer_http_addr=10.0.2.2:0 
-e ansible_winrm_scheme=http 
--extra-vars 
    runtime=docker-ee
    docker_ee_version=19.03.12 
    containerd_url=https://github.com/containerd/containerd/releases/download/v1.5.5/containerd-1.5.5-windows-amd64.tar.gzcontainerd_sha256=036428b8c4055b2eeba7c62ac84dc96552be9a2c14e3a8a6ac4052684cf73db0 
    pause_image= 
    additional_debug_files="" 
    containerd_additional_settings= 
    custom_role_names= 
    http_proxy= 
    https_proxy= 
    no_proxy= 
    kubernetes_base_url=https://kubernetesreleases.blob.core.windows.net/kubernetes/v1.20.10/binaries/node/windows/amd64 
    kubernetes_semver=v1.20.10 
    kubernetes_install_path=c:\k 
    cloudbase_init_url="https://github.com/cloudbase/cloudbase-init/releases/download/1.1.2/CloudbaseInitSetup_1_1_2_x64.msi" 
    cloudbase_plugins="
        cloudbaseinit.plugins.common.ephemeraldisk.EphemeralDiskPlugin, 
        cloudbaseinit.plugins.common.mtu.MTUPlugin,
        cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin,  
        cloudbaseinit.plugins.common.sshpublickeys.SetUserSSHPublicKeysPlugin, 
        cloudbaseinit.plugins.common.userdata.UserDataPlugin, 
        cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin, 
        cloudbaseinit.plugins.windows.createuser.CreateUserPlugin, 
        cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin" 
    cloudbase_metadata_services="cloudbaseinit.metadata.services.vmwareguestinfoservice.VMwareGuestInfoService" 
    cloudbase_plugins_unattend="cloudbaseinit.plugins.common.mtu.MTUPlugin" 
    cloudbase_metadata_services_unattend="cloudbaseinit.metadata.services.vmwareguestinfoservice.VMwareGuestInfoService"
    prepull=true 
    wins_url=https://github.com/rancher/wins/releases/download/v0.0.4/wins.exe 
    windows_updates_kbs="" 
    windows_updates_categories="" 
    windows_service_manager=nssm 
    nssm_url=https://azurek8scishared.blob.core.windows.net/nssm/nssm.exe 
    distribution_version= 
    netbios_host_name_compatibility=true 
    disable_hypervisor=false 
    cloudbase_logging_serial_port= 
    load_additional_components=false 
    additional_registry_images=false 
    additional_registry_images_list= 
    additional_url_images=false
    additional_url_images_list=
    additional_executables=false 
    additional_executables_list= 
    additional_executables_destination_path=
--extra-vars  
--extra-vars  
-e ansible_password=*****
images/capi/ansible/windows/node_windows.yml
```

Ansbile default tasks resides on `images/capi/ansible/windows/node_windows.yml`, this is a summary of them.

#### Default tasks

- Check if cloudbase-init url is set]
- Check if wins url is set
- Optimise powershell
- Get Install Drive
- Get Program Files Directory
- Get All Users profile path
- Get TEMP Directory

#### System preparation tasks
    
- Remove Windows updates default registry settings
- Add Windows update registry path
- Add Windows automatic update registry path
- Disable Windows automatic updates in registry
- Set Windows automatic updates to notify only in registry
- Set WinRm Service to delayed start
- Update Windows Defender signatures
- Install OpenSSH
- Set default SSH shell to Powershell
- Create SSH program data folder
- Enable ssh login without a password
- Set SSH service startup mode to auto and ensure it is started] ***
- Apply HNS fix for Multple LB policies
- Add required Windows Features
- Add Hyper-V

#### Cloudbase init

What is [cloudbase-init](https://cloudbase-init.readthedocs.io/en/latest/)? 

- Download Cloudbase-init
- Ensure log directory
- Install Cloudbase-init
- Set up cloudbase-init unattend configuration
- Set up cloudbase-init configuration
- Configure set up complete

#### Runtime

Containerd vs Docker

- Install docker via OneGet
- Start Docker Service
- Set up Docker Network

#### Kubernetes

- Download kubernetes binaries

* kubeadm
* kubectl
* kubelet
    
- Add kubernetes folder to path
- Create kubelet directory structure

* C:\var\log\kubelet
* C:\var\lib\kubelet\etc\kubernetes
* C:\var\lib\kubelet\etc\kubernetes\manifests
* C:\etc\kubernetes\pki

- Symlink kubelet pki folder
- Download nssm
- Create kubelet start file for nssm] 
- Install kubelet via nssm
- Ensure kubelet is installed
- Add firewall rule for kubelet
- Get wins
- Register wins.exe
- Ensure that wins service is running

#### Debugging 

Debugging helper files are downloaded:

```
debug/collectlogs.ps1
debug/dumpVfpPolicies.ps1
debug/portReservationTest.ps1
debug/starthnstrace.cmd
debug/startpacketcapture.cmd
debug/stoppacketcapture.cmd
debug/VFP.psm1
helper.psm1
hns.psm1
hack/DebugWindowsNode.ps1
```

### Goss provisioning

[GOSS](https://github.com/aelsabbahy/goss) is a quick and easy server validation,
this runs as the last provision step.

## Modifying the box with custom steps

```
WARNING: Experiment in progress
```

Installing Hyperv, ssh, containerd and Kubernetes binaries are already being contemplated 
in the Ansible tasks installations.

### Cloudinit

Basic details of the box, vagrant user, ssh key, etc. ?
Kubeadm reconfiguration and IP setting can be made here
What username and password are used here, and how to change it?

### Custom ansible roles

#### CNI installation details

Move forked *-calico.ps1 scripts to built-in.
CNI configuration must work with the new IP NIC.
