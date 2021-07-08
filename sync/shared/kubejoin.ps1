$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 1yxrcq.wln7jcdvdqr6zrak --discovery-token-ca-cert-hash sha256:5990535e3bfa3e67f6325beb4d6d2043e648a9c4ffaf70780f9f74f7030420e6 
