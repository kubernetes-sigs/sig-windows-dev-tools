Install-RemoteAccess -VpnType RoutingOnly
cd C:\CalicoWindows

### This /opt/cni/bin directory is read by the calico node startup script
### These probably could be plumbed in through vagrant if we wanted to
$Env:CNI_BIN_DIR='C:/opt/cni/bin'
$Env:CNI_CONF_DIR='C:/etc/cni/net.d'
$env:KUBECONFIG="C:/etc/kubernetes/kubelet.conf"
$env:CALICO_NETWORKING_BACKEND="vxlan"
$env:CALICO_DATASTORE_TYPE="kubernetes"

if (-not(Test-Path -Path $env:KUBECONFIG -PathType Leaf)) {
    Write-Output "Missing KUBECONFIG env var ! exiting $env:KUBECONFIG"
    exit 1
}

if (-not (Test-Path -Path ./install-calico.ps1 -PathType Leaf)) {
    Write-Output "WARNING WARNING WARNING : I DONT SEE THE INSTALL-CALICO.ps1 FILE !!!!!!!!!!"
    ls ./
    exit 100
}

## ------------------------------------------
Write-Output "Running install-calico.ps1 script"
## ------------------------------------------

## Node-service can be replaced on 3.20.1 --
cp C:/forked/node-service.ps1 ./node/node-service.ps1
cp C:/forked/config.ps1 ./

Get-ChildItem env:
Get-Date
c:\CalicoWindows\install-calico.ps1
Write-Output "Done installing Calico!"


## ------------------------------------------
Write-Output "Starting calico felix"
## ------------------------------------------
Start-Service -Name CalicoFelix
Start-Service -Name CalicoNode

Write-Output "Checking for calico services ..."
Get-Service *ico*


## ------------------------------------------
Write-Output "Starting Kube-proxy..."
## ------------------------------------------
C:\CalicoWindows\kubernetes\install-kube-services.ps1
Start-Service -Name kube-proxy
