$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token fewn1r.evy8krm0f4xvqcac --discovery-token-ca-cert-hash sha256:f87ed7d225085d86c5b93b7dce2dc20d38aacea803d7af3f158ddf7804720dec 
