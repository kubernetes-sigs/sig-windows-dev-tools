$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token v3seop.mso4p1ibifs87ucp --discovery-token-ca-cert-hash sha256:2dea5736a807dc50b09c67c4c0da2f66f30111cd379af31b172b7aa2482a479a 
