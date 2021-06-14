$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token vy5602.rgmfi37uplcqchac --discovery-token-ca-cert-hash sha256:ff947740db3a30f99f752824fb9488c013bb6810706d952d4c1daf2dfccb2f56 
