$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token ntp3em.rzo2sjw0h8zdkwsk --discovery-token-ca-cert-hash sha256:14f47a001b08a898abf29eb007dbff42a43017d451bf6b0a8adb19109280ce82 
