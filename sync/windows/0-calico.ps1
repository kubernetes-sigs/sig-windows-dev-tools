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

# Force Kubernetes folder
mkdir -Force C:/k/

# Required configuration files symlink
New-Item -ItemType HardLink -Target "C:\etc\kubernetes\kubelet.conf" -Path "C:\k\config"

## ------------------------------------------
Write-Output "Downloading Calico Artifacts"
## ------------------------------------------

Invoke-WebRequest https://projectcalico.docs.tigera.io/scripts/install-calico-windows.ps1 -OutFile c:\install-calico-windows.ps1
C:\install-calico-windows.ps1 -DownloadOnly yes

## ------------------------------------------
Write-Output "Print installed files"
## ------------------------------------------

ls C:\CalicoWindows
