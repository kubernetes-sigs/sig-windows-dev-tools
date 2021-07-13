$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token ttcnkw.7vtvjbj0r2l7zxcw --discovery-token-ca-cert-hash sha256:d8856a1e5474d6fea562f3b8a99b5db806f4e1a5fc110a7841582b9fda632c49 
