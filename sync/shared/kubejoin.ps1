$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token vn33of.7e3gwju6rx7q3dj3 --discovery-token-ca-cert-hash sha256:d06b177229ace7243c9595270a808a91c2a36b6430128a56aa4d5bd9b5a84577
