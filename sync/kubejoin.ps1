:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", :Path, [System.EnvironmentVariableTarget]::Machine)
kubeadm join 10.0.2.15:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token 7fjfe4.g88j3cohkjuyaxeo     --discovery-token-ca-cert-hash sha256:20ce09aace70da710531a7ff140e200444a70b08ad00d2dab77b260226ad24a8 
