# sig-windows-dev-tools Dual Boot Setup

## Introduction

Welcome to sig-windows-dev-tools, a suite of tools designed to help Windows developers create and maintain high-quality applications.

This guide is here to provide instructions on how to setup a 2 node cluster environment utilizing your current Windows 11 PC.

## Features

- Automated testing and debugging
- Easy-to-use graphical user interface
- Support for multiple languages
- Comprehensive documentation

## Minimum Requirements

- Windows PC (Windows 11 Used)
- 100GB of free HDD space
- 16GB of RAM

## Installation

As we are utilizing our existing Windows 11 computer, we will start by shrinking the current hard drive. This will provide us the space we need to install Ubuntu and run the scripts necessary to automate the development 2 Node cluster setup.

## Documentation

### Windows Configuration Steps

1. Start by shrinking the current HDD and partitioning 100GB to install Ubuntu Desktop and additional tools.
    - Open disk management by searching `create and format hard disk partitions` within the start menu.
        - Right click on the hard drive you would like to shrink, select shrink, set the amount of space to shrink in MB (100GB Minimum) and select shrink.

2. These instructions were created using the latest Ubuntu LTS Desktop image (22.04 LTS) from [Ubuntu Desktop] and configured flash drive for installation boot.
    - Boot/ Install instructions can be found - [Ubuntu Tutorials]
3. Reboot your PC and install Ubuntu Desktop now we have an unallocated amount of space ready, and the boot drive configured from step 2.
4. Upon Reboot, insert the USB drive, and install Ubuntu desktop on the newly allocated space.
    - Boot/ Install instructions can be found - [Ubuntu Tutorials]

### Ubuntu Desktop Instructions

1. Install essential tools for build and vagrant/virtualbox packages.

    *Example*:

    Adding hashicorp repo for most recent vagrant bits:

    ```
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -;
    sudo apt-add-repository \
	    "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main";
    sudo apt-get update

    ```

    Installing packages:
    ```
    sudo apt install build-essential vagrant virtualbox virtualbox-ext-pack -y
    sudo vagrant plugin install vagrant-reload vagrant-vbguest winrm winrm-elevated vagrant-ssh
    ```

2. Create `/etc/vbox/networks.conf` to set the [network bits](https://www.virtualbox.org/manual/ch06.html#network_hostonly):

    *Example*:
    ```
    sudo mkdir /etc/vbox
    sudo vi /etc/vbox

    * 10.0.0.0/8 192.168.0.0/16
    * 2001::/64
    ```

3. Clone the repo and build

    **Change directory to where you want the sig-windows-dev-tools to be installed*:

    ```
    sudo apt install git;
    git clone https://github.com/kubernetes-sigs/sig-windows-dev-tools.git;
    cd sig-windows-dev-tools;
    mkdir -p tools/sync/shared;
    touch tools/sync/shared/kubejoin.ps1;
    sudo apt install make;
    make all

    ```

4. ssh to the virtual machines

    - Control Plane node (Linux):
    ```
    vagrant ssh controlplane
    kubectl get pods -A
    ```

    - Windows node:
    ```
    vagrant ssh winw1
    ```

Now [let's run it!](https://github.com/kubernetes-sigs/sig-windows-dev-tools#lets-run-it)

[Ubuntu Tutorials]: https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview
[Ubuntu Desktop]: https://ubuntu.com/download/desktop
