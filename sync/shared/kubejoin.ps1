$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 5y178d.8hyknflg5s1kcycg --discovery-token-ca-cert-hash sha256:a774745870de218114f0573a2355da9a6c0fa6d6c70f1ad600f9bc32674be064 
