$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 3ocvm3.6zcwzzjoenhsr7t0 --discovery-token-ca-cert-hash sha256:a233ce79dcab1e41d8dfff074f9a0cae5eaeac4c858c7a1cdddf04f11c5c364a 
