$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token xw77ff.dhtsi2cldqqfwxct --discovery-token-ca-cert-hash sha256:b7ccdebdc818d1d527eb4072177b9991dbd7fca2a32647cf9020cb419a7cf0da 
