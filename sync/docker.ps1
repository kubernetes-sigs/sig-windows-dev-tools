
$ProgressPreference = 'SilentlyContinue'

Write-Output "### Installing Nuget"

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201  -Force

Write-Output "### Installing Powershell Docker Module"

Install-Module -Name DockerMsftProvider -Force

Write-Output "### Installing Docker"

Install-Package Docker -Providername DockerMsftProvider -Force

Write-Output "### Installing HyperV"

Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
