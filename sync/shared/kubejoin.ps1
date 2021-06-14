$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 2pytoa.i18q97m6ljbevf60 --discovery-token-ca-cert-hash sha256:9247a4b18d4e4a8b5cda509663e8d04544780d7f77c066b16c9c8bd35024a453 
