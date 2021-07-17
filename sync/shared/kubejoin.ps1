$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token j01nfv.esu7p9clwthxc6mk --discovery-token-ca-cert-hash sha256:183305d8f62ecaf630a0df0e6c90802a638a6f5018dfecfc19bd5352eb61095e 
