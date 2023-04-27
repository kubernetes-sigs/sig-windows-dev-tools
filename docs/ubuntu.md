
# Ubuntu

> **TODO:** SECTION MOVED FROM README AND NEEDS TO BE REVIEWED AND UPDATED - volunteers needed!

Follow the steps presented below to prepare the Linux host environment and create the two-node cluster:

**1.** Install essential tools for build and vagrant/virtualbox packages.

*Example*:

Adding hashicorp repo for most recent vagrant bits:
```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository \
	"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
```

Installing packages:
```
sudo apt install build-essential vagrant virtualbox virtualbox-ext-pack -y
sudo vagrant plugin install vagrant-reload vagrant-vbguest winrm winrm-elevated vagrant-ssh
```

**2.** Create `/etc/vbox/networks.conf` to set the [network bits](https://www.virtualbox.org/manual/ch06.html#network_hostonly):

*Example*:
```
sudo mkdir /etc/vbox
sudo vi /etc/vbox/networks.conf

* 10.0.0.0/8 192.168.0.0/16
* 2001::/64
```

**3.** Clone the repo and build

```
git clone https://github.com/kubernetes-sigs/sig-windows-dev-tools.git
cd sig-windows-dev-tools
touch tools/sync/shared/kubejoin.ps1
make all
```

**4.** ssh to the virtual machines

- Control Plane node (Linux):
```
vagrant ssh controlplane
kubectl get pods -A
```

- Windows node:
```
vagrant ssh winw1
```
