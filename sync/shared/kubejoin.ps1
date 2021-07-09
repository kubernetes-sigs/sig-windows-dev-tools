$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token kzq9w0.vwrkq819o7swp2oz --discovery-token-ca-cert-hash sha256:0174eb4818ed2ce14807e5fa608a7355b6e6d6d7bcd3f8c8a326c8f1dadcbe18 
