# Lets run it!

> **TODO:** SECTION MOVED FROM README AND NEEDS TO BE REVIEWED AND UPDATED - volunteers needed!

Ok let's get started... 

## 1) Pre-Flight checks...

For the happy path, just:

0) Start Docker so that you can build K8s from source as needed.
1) Install Vagrant, and then vagrant-reload
```
vagrant plugin install vagrant-reload vagrant-vbguest winrm winrm-elevated 
```
2) Modify CPU/memory in the variables.yml file. We recommend four cores 8G+ for your Windows node if you can spare it, and two cores 8G for your Linux node as well. 
 
## 2) Run it!

There are two use cases for these Windows K8s dev environments: Quick testing, and testing K8s from source.

## 3) Testing from source? `make all`

To test from source, run `vagrant destroy --force ; make all`.  This will

- destroy your existing dev environment (destroying the existent one, and removing binaries folder)
- clone down K8s from GitHub. If you have the k/k repo locally, you can `make path=path_to_k/k all` 
- compile the K8s proxy and kubelet (for linux and windows)
- inject them into the Linux and Windows vagrant environment at the /usr/bin and C:/k/bin/ location 
- start up the Linux and Windows VMs

AND THAT'S IT! Your machines should come up in a few minutes...

NOTE: Do not run the middle Makefile targets, they depend of the sequence to give the full cluster experience.
