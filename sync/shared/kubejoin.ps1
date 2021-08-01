$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 7jgkt7.wmh9gws1atolsv9m --discovery-token-ca-cert-hash sha256:b05332e1d56afcdc108f07916bedd0f4edd3294ed382e465b14f27e15bc6e8f7 
