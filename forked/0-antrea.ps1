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

# Install NSSM: Workaround to privileged containers...
mkdir C:/nssm/ -Force
curl.exe -LO https://k8stestinfrabinaries.blob.core.windows.net/nssm-mirror/nssm-2.24.zip
tar C C:/nssm/ -xvf ./nssm-2.24.zip --strip-components 2 */$arch/*.exe
Remove-Item -Force ./nssm-2.24.zip

# Install antrea: CNI Provider
mkdir -Force C:/k/antrea/ # scripts
mkdir -Force C:/k/antrea/bin/ #executables

######## ANTREA install files into the right locations... ########

$antreaInstallationFiles = @{
      "https://raw.githubusercontent.com/antrea-io/antrea/main/build/yamls/base/conf/antrea-cni.conflist" = "C:\etc\cni\net.d\10-antrea.conflist"
      "https://raw.githubusercontent.com/antrea-io/antrea/main/hack/windows/Install-OVS.ps1" =  "C:\k\antrea\Install-OVS.ps1"
      "https://raw.githubusercontent.com/antrea-io/antrea/main/hack/windows/helper.psm1" = "C:\k\antrea\helper.psm1"
      "https://github.com/antrea-io/antrea/releases/download/v1.1.0/antrea-agent-windows-x86_64.exe" = "C:\opt\cni\bin\antrea.exe"
      "https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-windows-amd64-v0.9.1.tgz" = "C:\k\antrea\bin"
      "https://dl.k8s.io/release/v1.21.0/bin/windows/amd64/kubectl.exe" = "C:/k/bin/kubectl.exe"
}

foreach ($theURL in $antreaInstallationFiles.keys) {
  Write-Output "Downloading $theFile if not available..."
  $outPath = $antreaInstallationFiles[$theURL]
  if (!(Test-Path $outPath)) {
     Write-Output("OMG OMG OMG OMG ---> $outPath")
     curl.exe -LO $theURL
     # special logic for the host-local plugin...
     if ($theURL -eq "https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-windows-amd64-v0.9.1.tgz" ){
        tar -xvzf cni-plugins-windows-amd64-v0.9.1.tgz
        cp ./host-local.exe "C:/opt/cni/bin/host-local.exe"
     } else {
       Write-Output("Finished getting $outPath, its in the right place :)")
     }
  }
}

