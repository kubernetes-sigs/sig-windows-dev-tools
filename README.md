# KubernetesOnWindows

This is a fully batteries-included development for Windows on Kubernetes, including:
- Vagrant file for launching a two-node cluster
- the latest containerd
- NetworkPolicy support for Windows and Linux provided by [Antrea](https://antrea.io)
- Windows binaries for kube-proxy.exe and kubelet.exe that are fully built from source (K8s main branch)

Soon to be integrated into kubernetes-sigs/windows-dev-environment!

We welcome contributions. We'd especially love to see:
- More CNI providers (calico, cillium, ...)
- More Container Runtime ideas
- More vagrant infrastructures (Vsphere, VMWare Fusion, EC2, GCE, and so on)
- E2Es or scripts which exercise privileged containers or LDAP / AD
- CSI or other storage/volume add-ons
- other ideas!

# Goal

Our goal is to make Windows ridiculously easy to contribute to, play with, and learn about for anyone interested
in using or contributing to the ongoing Kubernetes-on-Windows story. Windows is rapidly becoming an increasingly
viable alternative to Linux thanks to the recent introduction of Windows HostProcess containers and Windows support for NetworkPolicies + Containerd integration.

## Prerequisites

- vagrant
- vagrant reload plugin
- some vagrant provider (we only have virtualbox automated here, but these recipes have been used with others, like HyperV)

# Lets run it!

Ok let's get started... 

## 1) Pre-Flight checks...

For the happy path, just:

1) Install vagrant, and then vagrant-reload
```
vagrant plugin install vagrant-reload
```

2) Modify cpu/memory.    We advise 8GB RAM for Windows. If your system has less than 16GB RAM, adjust the `Vagrantfile`:
```
    winw1.vm.provider :virtualbox do |vb|
      vb.memory = 4096
```
change the `4096` to `2048`.

## 2) Run it!

There are two use cases for these Windows K8s dev environments: Quick testing, and testing K8s from source.

## 3) Testing from source? make

To test from source, run `make all`.  This will
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

If you still have an old instance of these VMs running for the same dir:
```
vagrant destroy -f && vagrant up
```
after everything is done (can take 10 min+), ssh' into the Linux VM:
```
vagrant ssh master
```
and get an overview of the nodes:
```
kubectl get nodes
```
The win node might stay 'NotReady' for a while, because it takes some time to download the flannel image.
```
vagrant@master:~$ kubectl get nodes
NAME     STATUS     ROLES                  AGE    VERSION
master   Ready      control-plane,master   8m4s   v1.20.4
winw1    NotReady   <none>                 64s    v1.20.4
```
...
```
NAME     STATUS   ROLES                  AGE     VERSION
master   Ready    control-plane,master   16m     v1.20.4
winw1    Ready    <none>                 9m11s   v1.20.4
```

I have only tested this on one machine. If you run into trouble, you're very welcome to create a new issue and include info about your system. 

## Accessing the Windows box

You'll obviously want to run commands on the Windows box. You can do this by noting the IP address during `vagrant provision` and running *any* RDP client (vagrant/vagrant for username/password).

To run a *command* on the Windows boxes without actually using the UI, you can use `winrm`, which is integrated into Vagrant. For example, you can run:

```
vagrant winrm winw1 --shell=powershell --command="ls"
```

## Where did I steal all the stuff?

This guide is based on [this very nice Vagrantfile](https://gist.github.com/danielepolencic/ef4ddb763fd9a18bf2f1eaaa2e337544) and this very good [guide on how to install Kubernetes on Ubuntu Focal (20.04)](https://github.com/mialeevs/kubernetes_installation). 
The Windows part is informed by this [guide on how to install Docker on Win Server 2019](https://www.hostafrica.co.za/blog/new-technologies/how-to-install-docker-on-linux-and-windows/#win), [this guide on adding Windows nodes](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/adding-windows-nodes/), and [this guide](https://www.hostafrica.co.za/blog/new-technologies/install-kubernetes-cluster-windows-server-worker-nodes/) on how to install Kubernetes on Win Server 2019.
