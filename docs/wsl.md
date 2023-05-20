# Windows with WSL

All the basic steps from the [Quick Start](../README.md#quick-start) apply,
except you have to:

- Clone this repo onto Windows host filesystem, not WSL filesystem
- Use `vagrant.exe` installed on the host, typically `C:\HashiCorp\Vagrant\bin\vagrant.exe`

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
cd /mnt/c/Users/{your user name}
git clone https://github.com/kubernetes-sigs/sig-windows-dev-tools.git
```
