# Welcome to the SIG Windows Development Environment!

This is a fully batteries-included development environment for Windows on Kubernetes, including:

- Vagrant file for launching a two-node cluster
- The latest Containerd
- Support for two CNIs: antrea, or calico on containerd:
  - configure your CNI option in `variables.yml`
  - Calico 3.19 on containerd runs containers out of the box
  - Antrea 0.13.2 runs but requires running with a patch for https://github.com/antrea-io/antrea/issues/2344 which was recently made available
- NetworkPolicy support for Windows and Linux provided by [Antrea](https://antrea.io) and [Calico](https://www.tigera.io/project-calico/)
- Windows binaries for kube-proxy.exe and kubelet.exe that are fully built from source (K8s main branch)
- Kubeadm installation that can put the bleeding-edge Linux control plane in place, so you can test new features like privileged containers

## Prerequisites

- Linux host - mostly tested on [Ubuntu](#ubuntu). Alternatively, Windows host.
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (we only have VirtualBox automated here, but these recipes have been used with others, like Microsoft HyperV and VMware Fusion).
- [Vagrant](https://www.vagrantup.com/downloads)
  - `vagrant plugin install vagrant-reload vagrant-vbguest winrm winrm-elevated`
  - `vagrant-reload` needed to easily reboot windows VMs during setup of containers features
- [Go](https://go.dev)
- [Mage](https://magefile.org)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) or any other Kubernetes client

Go and Mage are required to run steps of the cluster workflow which are coded as [Magefiles](https://magefile.org) in Go language.

## Quick Start

Simple steps to a Windows Kubernetes cluster, from scratch, from Kubernetes binaries downloaded or built from source:

1. Clone the repository

    ```console
    git clone https://github.com/kubernetes-sigs/sig-windows-dev-tools.git
    cd sig-windows-dev-tools
   ```

2. Optionally, copy `settings.yaml` with default settings to `settings.local.yaml` and modify you desire,
    for example, tweak RAM and CPUs for Vagrant machines or update Kubernetes version, etc.

3. Check your local environment and configuration settings

    ```console
    mage config:vagrant
    mage config:settings
    ```

    These commands will verify Go, Mage and Vagrant installations are working, then print out
    configuration settings which will be used to create and run the cluster.

4. Create the cluster

    ```console
    mage all        # or mage | tee run.log
    ```

    > **IMPORTANT:** Do not log into the VMs until the provisioning is done. That is especially true for Windows because it will prevent the reboots.

    The `mage all`, or just `mage` as equivalent creates the entire two-node Kubernetes cluster.

    Instead of `mage all` you can run sequence of `mage fetch` followed by `mage run` and `mage test:smoke`.
    Run `mage -l` to list all available commands (targets).

    By default, cluster is created from Kubernetes pre-built binaries.
    To compile Kubernetes from local source, on Linux host, see instructions later in this doc.

    > **TIP:** If provisioning of `winw1` failed, then try running `vagrant provision winw1`, just in case you have a flake during Windows installation.

5. Check status of machines, nodes and pods

    ```console
    mage status
    ```

    The mage status is a convenient wrapper for the sequence of these commands:

    ```console
    vagrant status
    vagrant ssh controlplane -c 'kubectl get nodes'
    vagrant ssh controlplane -c 'kubectl get -A pods'
    ```

    Alternatively, run `vagrant ssh controlplane` and run `kubectl get nodes` to see your running two-node dual-OS Linux+Windows k8s cluster.

    Alternatively, you can download kubeconfig form the controlplane node to run any Kubernetes client directly from the Windows host:

    ```console
    vagrant plugin install vagrant-scp
    vagrant scp controlplane:~/.kube/config ./swdt-kubeconfig
    kubectl --kubeconfig=./swdt-kubeconfig get nodes
    kubectl --kubeconfig=./swdt-kubeconfig get -A pods
    ```

6. Run `mage test:smoke` and `mage test:endToEnd`.

7. Run `mage clean` to delete the whole cluster and start over.

## Advanced Usage

There is a set of `mage` targets dedicated to testers who may appareciate fine-grained control of nodes lifetime:

1. Create individual node

    ```console
    mage node:create controlplane
    mage node:create winw1
    ```

2. Stop individual node

    ```console
    mage node:stop controlplane
    mage node:stop winw1
    ```

3. Start individual node

    ```console
    mage node:start controlplane
    mage node:start winw1
    ```

4. Destroy individual node

    ```console
    mage node:destroy winw1
    mage node:destroy controlplane
    ```

## Windows with WSL

All the above Quick Start steps apply, except you have to:

- clone this repo onto Windows host filesystem, not WSL filesystem
- use `vagrant.exe` installed on the host, typically `C:\HashiCorp\Vagrant\bin\vagrant.exe`

First, get the path for your `vagrant.exe` on the host use `Get-Command vagrant` in PowerShell like the following example.

```powershell
~ > $(get-command vagrant).Source.Replace("\","/").Replace("C:/", "/mnt/c/")
/mnt/c/HashiCorp/Vagrant/bin/vagrant.exe
```

Next, pass the mount path to the executable on the Windows host with the `VAGRANT` environment variable exported in WSL.

Then, ensure you clone this repository onto filesystem inside `/mnt` and not the WSL filesystem, in order to avoid failures similar to this one:

```console
The host path of the shared folder is not supported from WSL.
Host path of the shared folder must be located on a file system with
DrvFs type. Host path: ./sync/shared
```

Finally, steps to a Windows Kubernetes cluster on Windows host in WSL is turn into the following sequence:

```bash
export VAGRANT=/mnt/c/HashiCorp/Vagrant/bin/vagrant.exe
cd /mnt/c/Users/joe
git clone https://github.com/kubernetes-sigs/sig-windows-dev-tools.git
```

## Goal

Our goal is to make Windows ridiculously easy to contribute to, play with, and learn about for anyone interested
in using or contributing to the ongoing Kubernetes-on-Windows story. Windows is rapidly becoming an increasingly
viable alternative to Linux thanks to the recent introduction of Windows HostProcess containers and Windows support for NetworkPolicies + Containerd integration.

## Where we derived these recipes from

- This guide is based on [this very nice Vagrantfile](https://gist.github.com/danielepolencic/ef4ddb763fd9a18bf2f1eaaa2e337544)
- this very good [guide on how to install Kubernetes on Ubuntu Focal (20.04)](https://github.com/mialeevs/kubernetes_installation). 
- The Windows part is informed by this [guide on how to install Docker on Win Server 2019](https://www.hostafrica.co.za/blog/new-technologies/how-to-install-docker-on-linux-and-windows/#win), [this guide on adding Windows nodes](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/adding-windows-nodes/), and [this guide](https://www.hostafrica.co.za/blog/new-technologies/install-kubernetes-cluster-windows-server-worker-nodes/) on how to install Kubernetes on Win Server 2019.
- We've also borrowed ideas from cluster api, kubeadm, and the antrea project too bootstrap how we manage CNI and containerd support.

## Contributing

Working on Windows Kubernetes is a great way to learn about Kubernetes internals and how Kubernetes works in a multi-OS environment.  

So, even if you aren't a Windows user, we encourage Kubernetes users of all types to try to get involved and contribute!

We are a new project and we need help with...

- contributing / testing recipes on different Vagrant providers
- docs of existing workflows
- CSI support and testing
- privileged container support
- recipes with active directory
- any other ideas!

If nothing else, filing an issue with your bugs or experiences will be helpful long-term.

If interested in pairing with us to do your first contribution, just reach out in [#sig-windows](https://kubernetes.slack.com/archives/C0SJ4AFB7) on https://slack.k8s.io

We understand that developing on Kubernetes with Windows is new to many folks, and we're here to help you get started.
