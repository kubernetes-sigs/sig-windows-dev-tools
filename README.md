# Welcome to the SIG Windows Development Environment!

This is a fully batteries-included development environment for Windows on Kubernetes, including:
- Vagrant file for launching a two-node cluster
- The latest Containerd
- Support for two CNIs: antrea, or calico on containerd:  configure your CNI option in variables.yml
  - Calico 3.19 on containerd runs containers out of the box
  - Antrea 0.13.2 runs but requires running with a patch for https://github.com/antrea-io/antrea/issues/2344 which was recently made available
- NetworkPolicy support for Windows and Linux provided by [Antrea](https://antrea.io) and [Calico](https://www.tigera.io/project-calico/)
- Windows binaries for kube-proxy.exe and kubelet.exe that are fully built from source (K8s main branch)
- Kubeadm installation that can put the bleeding-edge Linux control plane in place, so you can test new features like privileged containers

## Quick Start

### Prerequisites 
- Linux host - mostly tested on [Ubuntu](#ubuntu). Alternatively, see [Windows with WSL](#windows-with-wsl).
- [make](https://www.gnu.org/software/make/)
- [Vagrant](https://www.vagrantup.com/downloads)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (we only have VirtualBox automated here, but these recipes have been used with others, like Microsoft HyperV and VMware Fusion).
- [Kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

### Getting a cluster up and running

Simple steps to a Windows Kubernetes cluster, from scratch, built from source...

- `vagrant plugin install vagrant-reload vagrant-vbguest winrm winrm-elevated`, vagrant-reload needed to easily reboot windows VMs during setup of containers features.
- `make all`, this will create the entire cluster for you.  To compile k/k/ from local source, see instructions later in this doc. 
	- *If the above failed, run `vagrant provision winw1`, just in case you have a flake during windows installation.*
- `vagrant ssh controlplane` and run `kubectl get nodes` to see your running dual-os linux+windows k8s cluster.

## Windows with WSL
All the above Quick Start steps apply, except you have to run the `Makefile` targets in WSL while using 
vagrant.exe on the host. To do this pass the mount path to the executable on the host with the `VAGRANT` environment variable. 
To get the path for your `vagrant.exe` on the host use `Get-Command vagrant` in PowerShell like the following example.

```powershell
~ > $(get-command vagrant).Source.Replace("\","/").Replace("C:/", "/mnt/c/")
/mnt/c/HashiCorp/Vagrant/bin/vagrant.exe
```

Use that string in WSL by exporting an Environment variable and then use all the make calls freely.

```bash
export VAGRANT=/mnt/c/HashiCorp/Vagrant/bin/vagrant.exe
make all
# ...
make clean
```

## Ubuntu

Follow the steps presented below to prepare the Linux host environment and create the two-node cluster:

**1.** Install essential tools for build and vagrant/virtualbox packages.

*Example*:

Adding hashicorp repo for most recent vagrant bits:
```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository \
	"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
```

Installing packages:
```
sudo apt install build-essential vagrant virtualbox virtualbox-ext-pack -y
sudo vagrant plugin install vagrant-reload vagrant-vbguest winrm winrm-elevated vagrant-ssh
```

**2.** Create `/etc/vbox/networks.conf` to set the [network bits](https://www.virtualbox.org/manual/ch06.html#network_hostonly):

*Example*:
```
sudo mkdir /etc/vbox
sudo vi /etc/vbox/networks.conf

* 10.0.0.0/8 192.168.0.0/16
* 2001::/64
```

**3.** Clone the repo and build

```
git clone https://github.com/kubernetes-sigs/sig-windows-dev-tools.git
cd sig-windows-dev-tools
touch tools/sync/shared/kubejoin.ps1
make all
```

**4.** ssh to the virtual machines

- Control Plane node (Linux):
```
vagrant ssh controlplane
kubectl get pods -A
```

- Windows node:
```
vagrant ssh winw1
```

# Goal

Our goal is to make Windows ridiculously easy to contribute to, play with, and learn about for anyone interested
in using or contributing to the ongoing Kubernetes-on-Windows story. Windows is rapidly becoming an increasingly
viable alternative to Linux thanks to the recent introduction of Windows HostProcess containers and Windows support for NetworkPolicies + Containerd integration.



# Lets run it!

Ok let's get started... 

## 1) Pre-Flight checks...

For the happy path, just:

0) Start Docker so that you can build K8s from source as needed.
1) Install Vagrant, and then vagrant-reload
```
vagrant plugin install vagrant-reload vagrant-vbguest winrm winrm-elevated 
```
2) Modify CPU/memory in the variables.yml file. We recommend four cores 8G+ for your Windows node if you can spare it, and two cores 8G for your Linux node as well. 
 
## 2) Run it!

There are two use cases for these Windows K8s dev environments: Quick testing, and testing K8s from source.

## 3) Testing from source? `make all`

To test from source, run `vagrant destroy --force ; make all`.  This will

- destroy your existing dev environment (destroying the existent one, and removing binaries folder)
- clone down K8s from GitHub. If you have the k/k repo locally, you can `make path=path_to_k/k all` 
- compile the K8s proxy and kubelet (for linux and windows)
- inject them into the Linux and Windows vagrant environment at the /usr/bin and C:/k/bin/ location 
- start up the Linux and Windows VMs

AND THAT'S IT! Your machines should come up in a few minutes...

NOTE: Do not run the middle Makefile targets, they depend of the sequence to give the full cluster experience.

## IMPORTANT
Do not log into the VMs until the provisioning is done. That is especially true for Windows because it will prevent the reboots.

## Other notes 

If you still have an old instance of these VMs running for the same dir:
```
vagrant destroy -f && vagrant up
```
after everything is done (can take 10 min+), ssh' into the Linux VM:
```
vagrant ssh controlplane
```
and get an overview of the nodes:
```
kubectl get nodes
```
The Windows node might stay 'NotReady' for a while, because it takes some time to download the Flannel image.
```
vagrant@controlplane:~$ kubectl get nodes
NAME     STATUS     ROLES                  AGE    VERSION
controlplane    Ready      control-plane,controlplane   8m4s   v1.20.4
winw1           NotReady   <none>                       64s    v1.20.4
```
...
```
NAME     STATUS   ROLES                  AGE     VERSION
controlplane    Ready    control-plane,controlplane     16m     v1.20.4
winw1           Ready    <none>                         9m11s   v1.20.4
```

## Accessing the Windows box

You'll obviously want to run commands on the Windows box. The easiest way is to SSH into the Windows machine and use powershell from there:

```
vagrant ssh winw1
C:\ > powershell
```

Optionally, you can do this by noting the IP address during `vagrant provision` and running *any* RDP client (vagrant/vagrant for username/password, works for SSH).
To run a *command* on the Windows boxes without actually using the UI, you can use `winrm`, which is integrated into Vagrant. For example, you can run:

```
vagrant winrm winw1 --shell=powershell --command="ls"
```

IF you want to debug on the windows node, you can also run crictl:

```
.\crictl config --set runtime-endpoint=npipe:////./pipe/containerd-containerd
```

## Where we derived these recipes from 

- This guide is based on [this very nice Vagrantfile](https://gist.github.com/danielepolencic/ef4ddb763fd9a18bf2f1eaaa2e337544)
- this very good [guide on how to install Kubernetes on Ubuntu Focal (20.04)](https://github.com/mialeevs/kubernetes_installation). 
- The Windows part is informed by this [guide on how to install Docker on Win Server 2019](https://www.hostafrica.co.za/blog/new-technologies/how-to-install-docker-on-linux-and-windows/#win), [this guide on adding Windows nodes](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/adding-windows-nodes/), and [this guide](https://www.hostafrica.co.za/blog/new-technologies/install-kubernetes-cluster-windows-server-worker-nodes/) on how to install Kubernetes on Win Server 2019.
- We've also borrowed ideas from cluster api, kubeadm, and the antrea project too bootstrap how we manage CNI and containerd support.

# Contributing

Working on Windows Kubernetes is a great way to learn about Kubernetes internals and how Kubernetes works in a multi-OS environment.  

So, even if you aren't a Windows user, we encourage Kubernetes users of all types to try to get involved and contribute!

We are a new project and we need help with... 

- contributing / testing recipes on different Vagrant providers
- docs of existing workflows
- CSI support and testing
- privileged container support
- recipes with active directory
- any other ideas!

If nothing else, filing an issue with your bugs or experiences will be helpful long-term. If interested in pairing with us to do your first contribution, just reach out in #sig-windows (https://slack.k8s.io/). We understand that developing on Kubernetes with Windows is new to many folks, and we're here to help you get started.
