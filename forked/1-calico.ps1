Install-RemoteAccess -VpnType RoutingOnly
Start-Service RemoteAccess
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

Write-Output "ABOUT TO RUN install-calico.ps1 script !!!!!!!!!!!!!!!!!!!"
if (-not (Test-Path -Path ./install-calico.ps1 -PathType Leaf)) {
    Write-Output "WARNING WARNING WARNING : I DONT SEE THE INSTALL-CALICO.ps1 FILE !!!!!!!!!!"
    ls ./
    exit 100
} else {
    ### Replace calico scripts with forked ones:
    Write-Output "Copying calico files............."
    
    cp C:/forked/install-calico.ps1 ./
    cp C:/forked/calico.psm1 ./libs/calico/
    cp C:/forked/config.ps1 ./
    Write-Output "................ DONE Copying forked calico files"

    ### This /opt/cni/bin directory is read by the calico node startup script
    Write-Output "............ RUNNING INSTALL_CALICO.ps1 with the following ENV VARS ............"
    Get-ChildItem env: 
    Get-Date
    .\install-calico.ps1
}

Write-Output "DONE INSTALLING CALICO I THINK !"
Get-Date
Get-Service -Name CalicoNode
Get-Service -Name CalicoFelix
