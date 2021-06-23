$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token xvufl4.cwao8gzg1i5prq3f --discovery-token-ca-cert-hash sha256:f980e7e73169e876b091304482b97bca2f6aeeae3c06d62936968a527ba0e2c8 
