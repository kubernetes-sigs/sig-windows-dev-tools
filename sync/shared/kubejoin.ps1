$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token ldbg6h.0v5tv80u16yx2okt --discovery-token-ca-cert-hash sha256:69cda857c2552e7ead87839b5e1948fb3fbdbf84f82156643d81e283527abc66 
