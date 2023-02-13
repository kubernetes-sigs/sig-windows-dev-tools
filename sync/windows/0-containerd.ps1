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

Param(
    [parameter(HelpMessage="ContainerD Version")]
        [string] $calico_version="",
        [string] $containerd_version=""
        )


## ------------------------------------------
Write-Output "Stopping  ContainerD & Kubelet"
## ------------------------------------------

Stop-Service containerd -Force


## ------------------------------------------
Write-Output "Downloading Calico using ContainerD - [version: $calico_version] [version: $containerd_version]"
## ------------------------------------------

# download and extract binaries
Invoke-WebRequest https://docs.tigera.io/calico/${calico_version}/scripts/Install-Containerd.ps1 -OutFile c:\Install-Containerd.ps1
c:\Install-Containerd.ps1 -ContainerDVersion ${containerd_version} -CNIConfigPath "c:/etc/cni/net.d" -CNIBinPath "c:/opt/cni/bin"
