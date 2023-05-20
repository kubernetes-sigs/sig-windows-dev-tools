# Welcome to the SIG Windows Development Environment!

This is a fully batteries-included development setup to run two-node hybrid Kubernetes cluster
with control plane node on Linux and worker node on Windows.

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

This section presents the basic usage instructions. For advanced usage of the Mage-based driver to run
and manage the cluster refer to [docs/usage.md](docs/usage.md).

Follow these steps to run the two-node Kubernetes cluster from scratch, using downloaded
official Kubernetes binaries or binaries built from source:

1. Clone the repository

    ```console
    git clone https://github.com/kubernetes-sigs/sig-windows-dev-tools.git
    cd sig-windows-dev-tools
   ```

2. Check your local environment and configuration settings

    ```console
    mage config:vagrant
    mage config:settings
    ```

    These commands will verify Go, Mage and Vagrant installations are working, then print out
    configuration settings which will be used to create and run the cluster.

3. Create the cluster

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

4. Check status of machines, nodes and pods

    ```console
    mage cluster:status
    ```

    The mage status is a convenient wrapper for the following sequence of commands:

    ```console
    vagrant status
    vagrant ssh controlplane -c 'kubectl get nodes'
    vagrant ssh controlplane -c 'kubectl get -A pods'
    ```

5. Run `mage test:smoke` and `mage test:endToEnd`.

6. Run `mage clean` to delete the whole cluster and start over.

## Goal

Our goal is to make Windows ridiculously easy to contribute to, play with, and learn about for anyone interested
in using or contributing to the ongoing Kubernetes-on-Windows story. Windows is rapidly becoming an increasingly
viable alternative to Linux thanks to the recent introduction of Windows HostProcess containers and Windows support for NetworkPolicies + Containerd integration.

## Features

- Vagrant file for launching a two-node hybrid Kubernetes cluster with Linux and Windows nodes
- The latest ContainerD
- Support for two CNIs: Antrea, or Calico on ContainerD:
  - configure your CNI option in `variables.yml`
  - Calico 3.19 on ContainerD runs containers out of the box
  - Antrea 0.13.2 runs but requires running with a patch for https://github.com/antrea-io/antrea/issues/2344 which was recently made available
- `NetworkPolicy` support for Windows and Linux provided by [Antrea](https://antrea.io) and [Calico](https://www.tigera.io/project-calico/)
- Windows binaries for `kube-proxy.exe` and `kubelet.exe` that are fully built from source (K8s main branch)
- `kubeadm` installation that can put the bleeding-edge Linux control plane in place, so you can test new features like privileged containers
- Support for Windows as host
- Support for Windows Subsystem for Linux as host, see [docs/wsl.md](docs/wsl.md)

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
