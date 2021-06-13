$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token t44noc.i8o7a4c2nb24elj3 --discovery-token-ca-cert-hash sha256:ff7179d0aeda0e1a4bd3698904424b27c1c4c98fdf11ef7367103e94dfe864ea 
