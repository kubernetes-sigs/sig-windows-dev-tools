$ProgressPreference = 'SilentlyContinue'

#Write-Output "### Enabling Hyper-V-PowerShell-Module"
#Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell 

Write-Output "### Creating C:\k"

mkdir 'C:\k'

cd 'C:\k'

Write-Output "### Curling 'Install-Containerd.ps1'"

curl.exe -LO 'https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/Install-Containerd.ps1'

Write-Output "### Running 'Install-Containerd.ps1'"

PowerShell "C:\k\Install-Containerd.ps1"

Write-Output "done with 'containerd1.ps1'"