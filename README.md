# Welcome to the SIG Windows Development Environment!

This is a fully batteries-included development environment for Windows on Kubernetes, including:
- Vagrant file for launching a two-node cluster
- the latest Containerd
- Support for two CNIs: antrea, or calico on containerd:  configure your CNI option in variables.yml
  - calico 3.19 on containerd runs containers out of the box
  - antrea 0.13.2 runs but requires running with a patch for https://github.com/antrea-io/antrea/issues/2344 which was recently made available
- NetworkPolicy support for Windows and Linux provided by [Antrea](https://antrea.io) and [Calico](https://www.tigera.io/project-calico/)
- Windows binaries for kube-proxy.exe and kubelet.exe that are fully built from source (K8s main branch)
- kubeadm installation that can put the bleeding-edge Linux control plane in place, so you can test new features like privileged containers

# Quick start

- clone this repo (obviously!)
- install vagrant & virtualbox (the base tools for this project)
- `vagrant plugin install vagrant-reload winrm winrm-elevated`, vagrant-reload needed to easily reboot windows VMs during setup of containers features.
- `make all`, this will create the entire cluster for you and compile windows binaries from source
- if the above failed, run `vagrant provision winw1`, just in case you have a flake during windows installation.
- `vagrant ssh controlplane` and run `kubectl get nodes` to see your running dual-os linux+windows k8s cluster.
 
# Goal

Our goal is to make Windows ridiculously easy to contribute to, play with, and learn about for anyone interested
in using or contributing to the ongoing Kubernetes-on-Windows story. Windows is rapidly becoming an increasingly
viable alternative to Linux thanks to the recent introduction of Windows HostProcess containers and Windows support for NetworkPolicies + Containerd integration.

## Prerequisites

- Vagrant
- Vagrant reload, winrm and winrm-elevated plugins
- some Vagrant provider (we only have VirtualBox automated here, but these recipes have been used with others, like HyperV and Fusion).

# Lets run it!

Ok let's get started... 

## 1) Pre-Flight checks...

For the happy path, just:

0) Start Docker so that you can build K8s from source as needed.
1) Install Vagrant, and then vagrant-reload
```
vagrant plugin install vagrant-reload winrm winrm-elevated
```
2) Modify CPU/memory in the variables.yml file. We recommend four cores 8G+ for your Windows node if you can spare it, and two cores 8G for your Linux node as well. 
 
## 2) Run it!

There are two use cases for these Windows K8s dev environments: Quick testing, and testing K8s from source.

## 3) Testing from source? make all

To test from source, run `vagrant destroy --force ; make all`.  This will
- destroy your existing dev environment 
- clone down K8s from GitHub. If you have the k/k repo locally, you can `make path=path_to_k/k all` 
- compile the K8s proxy and kubelet
- inject them into the Vagrant Windows environment at the C:/k/bin/ location 
- start up the Linux and Windows VMs
- ... TODO ~ build Linux components from source as well ...

### Quick testing: Vagrant up

```
# 1) First run this, bc Vagrant needs to do some reload of machines
vagrant plugin install vagrant-reload 

# 2) Bring up your entire Windows cluster! 
vagrant up
```

AND THAT'S IT! Your machines should come up in a few minutes...

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

You'll obviously want to run commands on the Windows box. You can do this by noting the IP address during `vagrant provision` and running *any* RDP client (vagrant/vagrant for username/password).

To run a *command* on the Windows boxes without actually using the UI, you can use `winrm`, which is integrated into Vagrant. For example, you can run:

```
vagrant winrm winw1 --shell=powershell --command="ls"
# Note for notes on how to use powershell to debug stuff, check out
# https://github.com/vmware-tanzu/tgik/blob/master/episodes/144/README.md
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
- ideas about how we can make this repository easier to use
- test automation ([Sonobuoy](https://github.com/vmware-tanzu/sonobuoy), [E2E Framework](https://github.com/kubernetes-sigs/e2e-framework), and so on)
- new CNIs like [Calico](https://www.projectcalico.org) or [Cillium](https://cilium.io)
- CSI support and testing
- privileged container support
- recipes with active directory
- any other ideas!

If nothing else, filing an issue with your bugs or experiences will be helpful long-term. If interested in pairing with us to do your first contribution, just reach out in #sig-windows (https://slack.k8s.io/). We understand that developing on Kubernetes with Windows is new to many folks, and we're here to help you get started.
