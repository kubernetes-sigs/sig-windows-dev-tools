Write-Output "Starting Kube-proxy and Kubelet..."

C:\CalicoWindows\kubernetes\install-kube-services.ps1

Write-Output "Starting Kube-proxy and Kubelet..."

Start-Service -Name kubelet
Start-Service -Name kube-proxy
