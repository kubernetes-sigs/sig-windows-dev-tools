---
Author: Mateusz Loskot (aka mloskot)
E-mail: mateusz@loskot.net
---

# Quo Vadis SWDT?

Follow-up to [SIG-Windows weekly meeting](https://docs.google.com/document/d/1aCcqSDBuXQ2gTbBg6QuGvLxCmzlSrAbTfflCTmo-960/edit#heading=h.la7dlzuh8o0o) from Jan 2, 2024,
this is my brainstorm of ideas and issues about the state and future of SWDT.
It turned out to be not as structured and systematic as I wished, apologies
for the chaos of thoughts, but it is a brainstorm, or rather, a braindump.

## Promise

The SWDT initial promise of the batteries-included local cluster with Windows
worker nodes integration on variety of host operating system although very
attractive turned out to be difficult to fulfill in manner that is reliably
usable and maintainable at the same time.

The SWDT goals need to be clarified and redefined, so they are achievable.

## Issues

- Pre-built images used for node VM-s, especially Windows, impose significant
  maintenance burden and become outdated quickly.

- Content of pre-built images is not easy to swap with latest releases of
  Kubernetes components.

- Convenience tools like Vagrant require pre-built images and come with
  their own limitations and bugs, which may become frustrating blockers.

- VirtualBox on Windows has a long history of performance issues and conflicts
  with other hypervisors like Windows-native Hyper-V or even with WSL.

- Despite use of pre-built images, current implementation is still complex
  and hacky, based on numerous undocumented scripts and fragile flows.
  It also requires `make` which is neither Windows-native nor portable.
  
- Although the project is supposed to be intrinsically quite simple and high level,
  its overall maintenance unfriendliness makes it not attractive to contributors.
  It is worth to acknowledge that SWDT is an auxiliary project rather than a product.

- The end-user documentation is too long and fiddly. Not quite reflects, quote:
  "Our goal is to make Windows ridiculously easy to contribute to, play with".

## Value

SWDT as a collection of current "Kubernetes on Windows" knowledge
and practices typically scattered in numerous resources as well as
user-friendly and configurable application to execute those locally
for development, testing and learning purposes on Linux or Windows host.

SWDT as a [facade](https://en.wikipedia.org/wiki/Facade_pattern)
masking complexity of Kubernetes documentation and tools for the basic
purpose of running a cluster with Windows-based workloads.

Despite there is multitude of Kubernetes distributions available to
run a local cluster, niche for a solution with simple minimal bare
Kubernetes on Linux and Windows seems to remains vacant. That is,
vanilla Kubernetes without using any amazing magic like the  kind does,
but plain `kubeadm` joining virtual or physical machines as nodes.

**Ku(bare)netes**! [tm] ;)

## Dream

Give users a command line tool that can **non-interactively** do:

1. Create Linux VM and install minimal Linux OS configured to become
   Kubernetes master node with control plane
2. Create Windows VM and install Windows Server OS configured to become
   Kubernetes worker node
3. Install container runtime, CNI and Kubernetes from official release
   or user-specified build
4. Initialise the control plane
5. Join the Windows node

and that can do it:

- on Linux or Windows host
- with host-native (or close) virtualisation solution i.e. KVM/QEMU on Linux
  and Hyper-V on Windows
- without using any pre-built SWDT-specific images.

and such CLI is written in Go, so it can run on Linux and Windows host smoothly.

Major challenges:

1. How to non-interactively create VM-s to build cluster nodes?
2. How to non-interactively install OS on VM-s to provision cluster nodes?

Especially, how to manage it for Windows node as Windows OS is still not
as friendly for non-human operators as Linux is.

### libvirt

libvirt is highly capable, but is still Linux-oriented solution, so it would be only
usable for managing Linux node on Linux host.

Although there is Microsoft [Hyper-V driver](https://libvirt.org/drvhyperv.html) available,
[it does not seem to be battle tested](https://lists.libvirt.org/archives/list/users@lists.libvirt.org/thread/IHVIAT72GD43DERY6FXIVNMMXHMNHLQ5/#IHVIAT72GD43DERY6FXIVNMMXHMNHLQ5).

Choosing libvirt comes with risk of becoming a distraction due to getting involved in
low-level work of fixing and maintaining the driver which, however beneficial for the
greater community, would stand against the own goals of SWDT project.

### Microsoft Virtualization API-s for Windows and Linux

Microsoft offers [plenty of options](https://learn.microsoft.com/en-us/virtualization/api/),
but it looks like only the HCS API is feature-complete for management of VM lifecycle.
Additionally, HCN API would help to initially setup VNet.

This, however, is a low-level option which will increase complexity and skill requirements
what in turn may work against making SWDT a project that is attractive and accessible to
new Kubernetes contributors and testers.

### unattended.xml for Windows only

Although it's an old school and tedious solution, it actually is fairly easy to reason about.
This may solve handling of non-interactive OS installation for building Windows node.

### Windows Server as VHD

Microsoft offers VHD - 9 GB to download - which is actually a pre-installed OS,
so it could potentially solve the OS installation issue.

### PowerShell Direct for Windows only (?)

A powerful high-level solution for day two provisioning of Windows VM, [regardless of network configuration](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/powershell-direct)
For example, setup container runtime, CNI, Kubernetes, etc. and this actually is what
I used in my experiments in https://github.com/mloskot/swdt-nextgen

My research suggests me, that PowerShell seems to be de-facto a communication of
choice for managing VM-s from Go apps, for example:

- https://github.com/taliesins/terraform-provider-hyperv/
- https://github.com/hashicorp/packer-plugin-hyperv

### SSH

Similarly to PowerShell, SSH can be used for day two provisioning.
In fact, I have used it in my `swdt-nextgen` experiments for setting up Linux node.
I have successfully tested it with Windows too, as alternative to PowerShell Direct,
but it is more fiddly and fragile than PowerShell (arguments handling, escaping,.
outputs manipulation, etc. may become PITA)

### Ansible

Whatever it can do, I, personally, would rather fail trying to fix
libvirt driver for Hyper-V :)

### WSL

I have no idea if and how it could help, but I thought it is worth to mention it.
Perhaps WSL could be used as Linux node? History of WSL networking issues scares me.
Regardless of what the WSL can do for SWDT, it will be best if SWDT aims for
simple Linux and Windows native solutions, VM-s or bare metal hosts.

### Vagrant 3.0

IFF we resist to keep VM management as one of features of SWDT,
then, perhaps, we should revisit the use of Vagrant, but instead of
relying on a custom image/box, we should ensure SWDT can work with
vanilla Linux and Windows Server images available out there.

The compelling reason to stay with Vagrant is their promise to deliver
[Vagrant 3.0](https://www.hashicorp.com/resources/the-future-of-vagrant-toward-3-0)
in Go. This would open opportunity to write SWDT-specific plugins, in Go,
should we discover a need for that. The problem is that HashiCorp seems to
be far from delivering the Vagrant 3.0.

Vagrant is certainly a unified API and a facade removing lots of virtualization complexity.

## Dream Simplified

*All credit for what follows below goes to Amim, for his idea of lean approach to SWDT.*

1. User creates VM-s however she likes, at least two, one Linux and one Windows,
   but according to certain well-documented basic requirements in order to make
   VM-s viable as nodes.
   For example:
   - Minimal installation of Linux Debian or Fedora
   - Minimal installation of Windows Server 2022
   - virtual switches created
   - static IP-s assigned
   - SSH servers installed on all nodes
   - public SSH keys deployed for password-less SSH communication nodes
   - password set for local `Administrator` user on Windows nodes,
     in case `swdt` needs to run PowerShell Direct (i.e. SSH comm runs short)
   - CNI configuration decided (e.g. pod CIDR)

2. User writes the details of the VM-s in form of simple YAML, in `my-awesome-cluster.yaml`

   Alternatively, a super friendly mode, user runs
   `swdt config create --output my-awesome-cluster.yaml`
   and a beautiful bubbly TUI asks the user sequence of questions,
   then generates the YAML ;)

3. User runs `swdt cluster create --config my-awesome-cluster.yaml`

4. The `swdt` takes over the nodes and does [what is necessary](https://github.com/mloskot/swdt-nextgen)
   to create control plane and join worker node(s):

   - optimises system level configuration: disables swap, loads kernel modules,
     enables iptables features, disables Windows Firewall
   - edits `hosts` files for hostname-based node-to-node communication
   - installs containerd or other CRI specified by user's configuration and supported by SWDT
   - installs CNI specified by user's configuration and supported by SWDT
   - installs Kubernetes
   - runs tests

   Of course, software components like containerd and Kubernetes can be specified as
   "build this from source from this tag for me, please", then.

5. The `swdt` offers day two commands too:

   - `swdt get kubeconfig --output ./.kubeconfig`
   - `swdt get nodes` and `swdt get pods` as convenient shortcuts that do not require host-local `.kubeconfig`
   - `swdt node stop|start`
   - `swdt cluster update --config my-new-node-spec-here.yaml` that is adding new things should be supported, but reconfiguring existing setup like network should not

Stretching the dream further, it would be awesome if there was `swdt cluster destroy`
reverting all the `swdt config create` changes leaving the VM-s cleaned up.
If we figure a simple usable VM management API, then `swdt` could use snapshots/checkpoints,
even if it does not provide a complete VM lifecycle management.

The major benefits of the simplified (lean) approach:

- Clears up almost all of the current issues discussed above.
- Avoids over-engineering SWDT.
- Potentially, may even become virtualization-agnostic and, in the step 1. above,
  could allow bare metal hosts for nodes - it is all about networking after all.

## Summary

The SWDT, as explained above, falls into a category of auxiliary projects,
so it has slim chances to become a rockstar of Kubernetes distributors.
However, there are plenty of reasons to make SWDT a well-designed product,
useful to attack real problems and pleasant to work with and contribute to.

It is important that community involved in SIG-Windows agree upon common
goals and features, so they find SWDT usable for their own tasks.
Otherwise, the project will become deprecated sooner than it is released.
