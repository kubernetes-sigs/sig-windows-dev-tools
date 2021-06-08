# Install NSSM: Workaround to privileged containers...
mkdir -Force C:/nssm/ nssm.zip
DownloadFile nssm.zip https://k8stestinfrabinaries.blob.core.windows.net/nssm-mirror/nssm-2.24.zip
C:\Windows\system32\tar.exe C C:/nssm/ -xvf .\nssm.zip --strip-components 2 */$arch/*.exe
Remove-Item -Force .\nssm.zip

# Install antrea: CNI Provider
mkdir -Force C:/k/antrea/ # scripts
mkdir -Force C:/k/antrea/bin/ #executables

######## ANTREA SETUP ########

# antrea OVS installer download
if (Test-Path -Path C:/k/antrea/Install-OVS.ps1 ) {
    Write-Host("Skipping download to avoid overwriting, already found on disk...")
}
else {
    curl.exe -LO https://raw.githubusercontent.com/antrea-io/antrea/main/hack/windows/Install-OVS.ps1
    cp .\Install-OVS.ps1 C:/k/antrea/Install-OVS.ps1
}
# antrea helper for credentials, kube proxy download .  note that this also downloads an antrea config
if (Test-Path -Path C:/k/antrea/helper.psm1 ) {
    Write-Host("Skipping download to avoid overwriting, already found on disk...")
}
else {
    curl.exe -LO https://raw.githubusercontent.com/antrea-io/antrea/main/hack/windows/helper.psm1
    cp .\helper.psm1 C:/k/antrea/helper.psm1
}

# antrea agent download
if (Test-Path -Path C:/k/antrea/bin/antrea-agent.exe ) {
    Write-Host("Skipping download to avoid overwriting, already found on disk...")
}
else {
   curl.exe https://github.com/antrea-io/antrea/releases/download/v1.1.0/antrea-agent-windows-x86_64.exe
   cp antrea-agent-windows-x86_64.exe C:/k/antrea/bin/antrea-agent.exe
}

