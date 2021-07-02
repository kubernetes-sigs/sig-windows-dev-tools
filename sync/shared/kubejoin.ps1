$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 08c8xy.6o8do67wikgtl0ew --discovery-token-ca-cert-hash sha256:6f5e08f8c38f688f78845108a59a5e5fb96ebbdc5b135e2bd93c7e4dfe9fe410 
