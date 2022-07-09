cd C:\CalicoWindows

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

cp C:/forked/config.ps1 .\config.ps1

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
