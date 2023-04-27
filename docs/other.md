# Other notes

> **TODO:** SECTION MOVED FROM README AND NEEDS TO BE REVIEWED AND UPDATED - volunteers needed!

If you still have an old instance of these VMs running for the same dir:
```
vagrant destroy -f && vagrant up
```
after everything is done (can take 10 min+), ssh' into the Linux VM:
```
vagrant ssh controlplane
```
and get an overview of the nodes:
```
kubectl get nodes
```
The Windows node might stay 'NotReady' for a while, because it takes some time to download the Flannel image.
```
vagrant@controlplane:~$ kubectl get nodes
NAME     STATUS     ROLES                  AGE    VERSION
controlplane    Ready      control-plane,controlplane   8m4s   v1.20.4
winw1           NotReady   <none>                       64s    v1.20.4
```
...
```
NAME     STATUS   ROLES                  AGE     VERSION
controlplane    Ready    control-plane,controlplane     16m     v1.20.4
winw1           Ready    <none>                         9m11s   v1.20.4
```
