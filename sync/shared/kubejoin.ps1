$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 9n3umk.o2iqrho7rjakrqps --discovery-token-ca-cert-hash sha256:045241bfcea2c884eceef830db4dcf9432c5f0aa8d00fbe2f54710f4bc284cdb 
