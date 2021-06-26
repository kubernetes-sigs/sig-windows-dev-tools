$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 9ehroj.ymupqnfk6lmsi9mc --discovery-token-ca-cert-hash sha256:6c339766d490a41c79977e77c60e9a022b9b8aceacfa4c817cc8dd6c0fbd3c1d 
