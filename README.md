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

## Where did I steal all the stuff?
This guide is based on [this very nice Vagrantfile](https://gist.github.com/danielepolencic/ef4ddb763fd9a18bf2f1eaaa2e337544) and this very good [guide on how install Kubernetes on Ubuntu Focal (20.04)](https://github.com/mialeevs/kubernetes_installation). 
For the Windows part is used this [guide on how to install Docker on Win Server 2019](https://www.hostafrica.co.za/blog/new-technologies/how-to-install-docker-on-linux-and-windows/#win) and another [guide on how to install Kubernetes on Win Server 2019](https://www.hostafrica.co.za/blog/new-technologies/install-kubernetes-cluster-windows-server-worker-nodes/).
