Write-Output "### Starting Docker"

Start-Service docker

Write-Output "### Only for Debug, checking Docker:"

Docker -v

Write-Output "### create the kubernetes folder"

New-Item -ItemType Directory -Force -Path C:\k

cd C:\k

Write-Output "### Downloading PrepareNode.ps1"

curl.exe -s -LO https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/PrepareNode.ps1

Write-Output "### Running PrepareNode.ps1"

PowerShell "C:\k\PrepareNode.ps1" -KubernetesVersion v1.20.4
