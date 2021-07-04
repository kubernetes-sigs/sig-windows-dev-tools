$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.0.0.22:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token t9wgsm.5tb4oe5d567nbb07 --discovery-token-ca-cert-hash sha256:b74b2c511c3e5e99e4775c194aef66fb628df029315673a4dd6aff62737c1e85 
