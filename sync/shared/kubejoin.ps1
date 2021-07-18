$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token h338tq.cvjm9pjf835ofute --discovery-token-ca-cert-hash sha256:5b71d704d9e65adb46857a0973f03cbcdaf518b71cbdb849fda8269f7d0dcc6a 
