<#
Copyright 2021 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

# Install antrea: CNI Provider
mkdir -Force C:/k/

#########################################################################################################
### kubectl:  is needed by calico installer, but TODO, antrea and calico shouldnt need to do this, and we should just
### download kubectl as part of the generic windows kubernetes setup...
#########################################################################################################
$InstallationFiles = @{
      "https://dl.k8s.io/release/v1.21.0/bin/windows/amd64/kubectl.exe" = "C:/k/kubectl.exe"
}

foreach ($theURL in $InstallationFiles.keys) {
  $outPath = $InstallationFiles[$theURL]
  Write-Output("1 - checking $outPath ... ")
  if (!(Test-Path $outPath)) {
     Write-Output("2 - Acquiring ---> $theURL writing to  $outPath")
     curl.exe -L $theURL -o $outPath
     Write-Output("$outPath ::: DETAILS ...")
     Get-ItemProperty $outPath
     ls $outPath
     Write-Output("$outPath ::: DONE VERIFYING")
  }
  if (!(Test-Path $outPath)) {
    Write-Error "That download totally failed $outPath is not created...."
    exit 1
  }
}


###############################################################################################





Write-Output "FIRST RUNNING CALICO PRE SETUP STUFF"
Install-WindowsFeature RemoteAccess
Install-WindowsFeature RSAT-RemoteAccess-PowerShell
Install-WindowsFeature Routing

C:/forked/install-calico-windows.ps1 -DownloadOnly yes
Write-Output "CALICO ARTIFACTS.................................."
Write-Output "CALICO ARTIFACTS.................................."
Write-Output "CALICO ARTIFACTS.................................."

ls C:\CalicoWindows

Write-Output ".................................. CALICO ARTIFACTS"
Write-Output ".................................. CALICO ARTIFACTS"
Write-Output ".................................. CALICO ARTIFACTS"

