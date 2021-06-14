$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token ms64st.11h754wjkx5vy4hb --discovery-token-ca-cert-hash sha256:9f0d06e18be74825ae4fbcf1e5c7f6e9a0912bc62715c5914146a878488baa91 
