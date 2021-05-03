
$ProgressPreference = 'SilentlyContinue'

Write-Output "### Installing Nuget"

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201  -Force

Write-Output "### Using dism: enabling Hyper-V"

dism -online -enable-feature -featurename:Microsoft-Hyper-V -all -NoRestart

Write-Output "### Installing Containers"

Install-WindowsFeature Containers

Write-Output "done with 'hyperv.ps1'"