# Accessing the Windows box

> **TODO:** SECTION MOVED FROM README AND NEEDS TO BE REVIEWED AND UPDATED - volunteers needed!

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
