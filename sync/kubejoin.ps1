# To avoid the "crictl.exe not on the path error, we add containerd permanantly to the pathhhhh"
$env:path += ";C:\Program Files\containerd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

kubeadm join 10.0.2.15:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token x3sloc.76v9vmngy4iqqbae     --discovery-token-ca-cert-hash sha256:ab028a3edaf4df32d47fff414bf5a534bb3c53288ba3f6f86b61b6342df34aa8
