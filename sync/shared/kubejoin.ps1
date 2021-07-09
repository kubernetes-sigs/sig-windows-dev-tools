$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token artnye.t7y8mdtzt7tah2ou --discovery-token-ca-cert-hash sha256:ba36ee71bd5f05ce1633bdf2f1dbcc16074b5369c0de13da6a6f99aed029d189 
