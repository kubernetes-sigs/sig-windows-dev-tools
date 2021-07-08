$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token a55937.vmg7z39jeupj2fub --discovery-token-ca-cert-hash sha256:5cdaf56dde348615abf3f013ff78cd9f9de5d0ec1f71768e6114c7030c8aecca 
