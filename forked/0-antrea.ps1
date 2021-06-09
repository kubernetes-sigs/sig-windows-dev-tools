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

foreach ($theFile in $antreaInstallationFiles) {
  Write-Output "Downloading $theFile if not available..."
  $outPath = $antreaInstallationFiles[$theFile]
  if (!(Test-Path $outPath)) {
     Write-Output("OMG OMG OMG OMG ---> $outPath")
     Start-Sleep -s 15

     curl.exe -LO $theFile
     # special logic for the host-local plugin...
     if ($theFile -eq "https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-windows-amd64-v0.9.1.tgz" ){
        tar -xvzf cni-plugins-windows-amd64-v0.9.1.tgz
        cp ./host-local.exe "C:/opt/cni/bin/host-local.exe"
     }
     else {
         cp $theFile $antreaInstallationFiles[$theFile] -Force
     }
  }
}

