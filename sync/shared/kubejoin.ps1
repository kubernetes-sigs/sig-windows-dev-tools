$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token yxxkaq.hhlaeus0daigwljp --discovery-token-ca-cert-hash sha256:38d98a69683f9f96e31a47a009e6a959cfe7704fe4f3c925bd19cd7116b5261d 
