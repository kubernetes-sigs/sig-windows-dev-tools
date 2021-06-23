$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token yy81yy.c5vf340s6eas9l41 --discovery-token-ca-cert-hash sha256:d69069be33f871a85090ce02698677bb5075fad431041f1d2343a16222feabc5 
