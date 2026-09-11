## Packer VM image builder

This folder hosts the plain boot and automatic installation scripts
using packer. Two builders are available, both reusing the same
Windows Server 2022 unattended installation config in `kvm/floppy/`:

* **kvm** - QEMU/KVM builder, produces a QCOW2 artifact. This is the
  existing default and runs on a Linux host.
* **hyperv** - Hyper-V builder (experimental), produces a Hyper-V VM
  artifact. Runs only on a Windows host with Hyper-V enabled.

### KVM/QEMU (default)

Pre-requisites:

* Hashicorp Packer >=1.10.2

2 ISOs are required, save them on isos folder:

* **windows.iso** - [Windows 2022 Server](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022)
* **virtio-win.iso** - [Windows Virtio Drivers](https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md)

#### Running

```shell
make start
```

Behind the scenes it will call Packer in the kvm build

```shell
packer init kvm
PACKER_LOG=1 packer build kvm
```

#### Export

The folder `output` will contain the `win2k22` QEMU QCOW Image.

### Hyper-V (experimental)

Hyper-V itself must be available and enabled on the Windows host.
Two workflows are supported for driving the build:

1. **Native Windows PowerShell**

   Requirements:
   - Windows host with Hyper-V enabled
   - Administrator privileges
   - Packer installed

2. **WSL2**

   HashiCorp's Hyper-V plugin supports being driven from WSL2, provided
   the repository is located on the Windows filesystem, e.g.
   `/mnt/c/Users/<user>/...`, and `PACKER_CACHE_DIR` also points to the
   Windows filesystem. A repository checked out on WSL's native ext4
   filesystem (e.g. `~/github/...`) is not supported for this workflow.

It reuses the same `windows.iso` as the KVM/QEMU builder - save it at
`kvm/isos/windows.iso`, there is no separate `hyperv/isos` folder.
Unlike KVM/QEMU, Hyper-V does **not** need `virtio-win.iso`: it uses its
own native (synthetic) drivers, so no second driver ISO is attached.

The template intentionally sets `generation = 1`: the existing unattended
install is delivered via `floppy_files` (`kvm/floppy/autounattend.xml` and
`kvm/floppy/openssh.ps1`), and Hyper-V Generation 2 VMs do not support
floppy drives. Note that these floppy files were originally written for
the KVM/QEMU builder and still contain VirtIO-specific driver paths from
that setup - whether that's harmless under Hyper-V has not been verified
against a real Hyper-V build yet.

#### Running

**Native Windows PowerShell** - open PowerShell as Administrator, `cd`
into this `packer` directory, then run:

```powershell
$env:PACKER_LOG = "1"
packer init hyperv
packer build hyperv
```

**WSL2** - with the repository on the Windows filesystem and
`PACKER_CACHE_DIR` pointing there too:

```shell
export PACKER_CACHE_DIR=/mnt/c/Users/<user>/.packer
PACKER_LOG=1 packer init hyperv
PACKER_LOG=1 packer build hyperv
```

By default Packer auto-detects an external virtual switch. To target a
specific switch instead, pass the `switch_name` variable, for example:

```shell
packer build -var "switch_name=Default Switch" hyperv
```

#### Export

The folder `output/hyperv` will contain the `win2k22` Hyper-V artifact.
