# KubernetesOnWindows
## How to run
Some parts of the vagrantfile for windows, especially rebooting, is causing trouble. A workaround for this is just to run the same commands from a makefile.
To actually run everything just use
```
make run
```
The last part for Win is not resolved yet and must be done by hand. To do so enter the Win VM (pw is "vagrant"), open `PowerShell` in Admin mode and run 
```
PowerShell "C:\sync\k.ps1"
```
In the last part of the script I still run into errors. Hopefully, when this is fixed, the PowerShell-script part can be moved to the vagrantfile or at least into the makefile.
```
#register & start kube-proxy
1
Service "kube-proxy" installed successfully!
2
Set parameter "AppDirectory" for service "kube-proxy".
3
Cannot index into a null array.
At C:\k\helper.psm1:179 char:5
+     $subnet = $hnsNetwork.Subnets[0].AddressPrefix
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [], RuntimeException
    + FullyQualifiedErrorId : NullArray

4
5
You cannot call a method on a null-valued expression.
At C:\sync\k.ps1:191 char:1
+ $sourceVip = $sourceVipJSON.ip4.ip.Split("/")[0]
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [], RuntimeException
    + FullyQualifiedErrorId : InvokeMethodOnNull

6
Set parameter "AppParameters" for service "kube-proxy".
7
Set parameter "DependOnService" for service "kube-proxy".
8
kube-proxy: Unexpected status SERVICE_START_PENDING in response to START control.

Status      : Paused
Name        : kubelet
DisplayName : kubelet


Status      : Running
Name        : kube-proxy
DisplayName : kube-proxy



PS C:\Windows\system32>
```

## Where did I steal all the stuff?
This guide is based on [this very nice Vagrantfile](https://gist.github.com/danielepolencic/ef4ddb763fd9a18bf2f1eaaa2e337544) and this very good [guide on how install Kubernetes on Ubuntu Focal (20.04)](https://github.com/mialeevs/kubernetes_installation). 
For the Windows part is used this [guide on how to install Docker on Win Server 2019](https://www.hostafrica.co.za/blog/new-technologies/how-to-install-docker-on-linux-and-windows/#win) and another [guide on how to install Kubernetes on Win Server 2019](https://www.hostafrica.co.za/blog/new-technologies/install-kubernetes-cluster-windows-server-worker-nodes/).
