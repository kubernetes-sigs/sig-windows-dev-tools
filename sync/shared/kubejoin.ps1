$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.20.30.10:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 19f1py.onamsn7i80hphxmh --discovery-token-ca-cert-hash sha256:be279c00a53961ee091d10fbc2a33ba09f850b08fe06ba313ddb03302be26d59

