$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 86039w.99bp7lykobg831qx --discovery-token-ca-cert-hash sha256:6f4cac90bb19a1af3c620eb4bbd015d00b2181653ab6f36a3bf5ebce0dc01e76 
