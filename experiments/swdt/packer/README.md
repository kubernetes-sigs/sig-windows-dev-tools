## Packer VM image builder

This folder hosts the plain boot and automatic installation scripts
using packer, the final outcome is the qemu artifact ready to be used
as a VM for swdt with SSH enabled.

Pre-requisites:

* Hashicorp Packer >=1.10.2

2 ISOs are required, save them on isos folder:

* **window.iso** - [Windows 2022 Server](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022) 
* **virtio-win.iso** - [Windows Virtio Drivers](https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md)

### Running 

```shell
make start
```

Behind the scenes it will call Packer in the kvm build

```shell
packer init kvm
PACKER_LOG=1 packer build kvm
```

### Export

The folder `output` will contain the `win2k22` QEMU QCOW Image.

