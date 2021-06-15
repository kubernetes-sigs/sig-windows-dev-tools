$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token ariivt.cftklu90vqp5mqau --discovery-token-ca-cert-hash sha256:ccf13900552a0c15b566e61ee13b8a820270e761ba4c2657798cfba4a7e7dd50 
