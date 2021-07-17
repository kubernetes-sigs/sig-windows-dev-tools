$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token p7t7ta.fnuqcm1sw5s9wgru --discovery-token-ca-cert-hash sha256:3cdc84cc4eb0628ed446953bccd913001a6cdee8d4fcfdde5c2ee591c5668c00 
