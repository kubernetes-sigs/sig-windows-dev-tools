$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token elpat5.j1n1zvzlufsbgu2c --discovery-token-ca-cert-hash sha256:145e27c041004ff2f8673995344c31853157cb28caf4b83907850b3f1c8a7aeb 
