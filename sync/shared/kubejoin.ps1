$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 589d1w.x5or7eq04ih2d8tu --discovery-token-ca-cert-hash sha256:14e9444a5d9c0626c338a1fe2343d196e1abf9a860c4f5d905738a5427bfabf5 
