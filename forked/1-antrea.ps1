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

# Create Folders
# TODO just add this to the path somehow?
# NVM its already on the f'ng path
# $kubectl="C:/k/bin/kubectl.exe"

$folders = @('C:\k\antrea','C:\var\log\antrea','C:\k\antrea\bin', 'C:\var\log\kube-proxy', 'C:\opt\cni\bin', 'C:\etc\cni\net.d')
foreach ($f in $folders) {
  New-Item -ItemType Directory -Force -Path $f
}

# Add Windows Defender Options
$avexceptions = @('c:\program files\containerd\ctr.exe', 'c:\program files\containerd\containerd.exe' )
foreach ($e in $avexceptions) {
    Add-MpPreference -ExclusionProcess $e
}

# Get HostIP and set in kubeadm-flags.env
[Environment]::SetEnvironmentVariable("NODE_NAME", (hostname).ToLower())
$env:HostIP = (
  Get-NetIPConfiguration |
  Where-Object {
      $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -ne "Disconnected"
  }
).IPv4Address.IPAddress
$file = 'C:\var\lib\kubelet\kubeadm-flags.env'
$newstr ="--node-ip=" + $env:HostIP
$raw = Get-Content -Path $file -TotalCount 1
$raw = $raw -replace ".$"
$new = "$($raw) $($newstr)`""
Set-Content $file $new
$KubeConfigFile='C:\etc\kubernetes\kubelet.conf'

# Setup kubo-proxy config file
$KubeProxyConfig="C:\k\antrea\etc\kube-proxy.conf"
$KubeAPIServer=$(kubectl --kubeconfig=$KubeConfigFile config view -o jsonpath='{.clusters[0].cluster.server}')
$KubeProxyTOKEN=$(kubectl --kubeconfig=$KubeConfigFile get secrets -n kube-system -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='kube-proxy-windows')].data.token}")
$KubeProxyTOKEN=$([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($KubeProxyTOKEN)))

# This writes out a kubeconfig file... i think !
kubectl config --kubeconfig=$KubeProxyConfig set-cluster kubernetes --server=$KubeAPIServer --insecure-skip-tls-verify

# Now we set the defaults up...
kubectl config --kubeconfig=$KubeProxyConfig set-credentials kube-proxy-windows --token=$KubeProxyTOKEN
kubectl config --kubeconfig=$KubeProxyConfig set-context kube-proxy-windows@kubernetes --cluster=kubernetes --user=kube-proxy-windows
kubectl config --kubeconfig=$KubeProxyConfig use-context kube-proxy-windows@kubernetes

# Wait for antrea-agent token to be ready
$AntreaToken=$null
$LoopCount=5
do {
  $LoopCount=$LoopCount-1
  if ($LoopCount -eq 0) {
      break
  }
  Write-Output "Trying to set antrea token ~ via getting secrets from kubeconfig file"
  Write-Output $LoopCount
  sleep 120
  $AntreaToken=$(kubectl --kubeconfig=$KubeConfigFile get secrets -n kube-system -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='antrea-agent')].data.token}")
} while ($AntreaToken -eq $null)
# Download kube-proxy in advance to avoid download failure in Install-AntreaAgent.
# This is only a workaround because we don't have kube-proxy.exe packed into Windows
# OVA, Install-AntreaAgent will check whether the file exists, if not, it will curl
# a new one, but there maybe something wrong in that function, curl may fail to get
# kube-proxy.exe, to avoid the failure case, we download it here.  Another thing,
# kube-proxy.exe of version v1.21.0 is not working, please see:
#        https://github.com/kubernetes/kubernetes/issues/101500
# we have to use v1.21.1 instead although version of our Kubernetes is v1.21.0.
if (Test-Path "C:/k/kube-proxy.exe") {
  # Delete v1.21.0 if it exists.
  $KubeProxyVer = $(C:/k/kube-proxy.exe --version)
  if ($KubeProxyVer.startswith('Kubernetes v1.21.0')) {
      rm -Force C:/k/kube-proxy.exe
  }
}
if (!(Test-Path "C:/k/kube-proxy.exe")) {
  curl.exe -sLo C:/k/kube-proxy.exe https://dl.k8s.io/v1.21.1/bin/windows/amd64/kube-proxy.exe --ssl-no-revoke
}
# Install antrea-agent & ovs
Import-Module c:/k/antrea/helper.psm1
& Install-AntreaAgent -KubernetesVersion "v1.21.1" -KubernetesHome "c:/k" -KubeConfig "C:/etc/kubernetes/kubelet.conf" -AntreaVersion "v0.13.2" -AntreaHome "c:/k/antrea"
New-KubeProxyServiceInterface
& c:/k/antrea/Install-OVS.ps1 -ImportCertificate $false -LocalFile c:/k/antrea/ovs-win64.zip
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
# Setup Services
$nssm = (Get-Command nssm).Source
& $nssm set Kubelet start SERVICE_AUTO_START
& nssm install kube-proxy "c:/k/kube-proxy.exe" "--proxy-mode=userspace --kubeconfig=$KubeProxyConfig --log-dir=c:/var/log/kube-proxy --logtostderr=false --alsologtostderr"
& nssm install antrea-agent "c:/k/antrea/bin/antrea-agent.exe" "--config=c:/k/antrea/etc/antrea-agent.conf --logtostderr=false --log_dir=c:/var/log/antrea --alsologtostderr --log_file_max_size=100 --log_file_max_num=4"
& nssm set antrea-agent DependOnService kube-proxy ovs-vswitchd
& nssm set antrea-agent Start SERVICE_DELAYED_START
# Start Services
start-service kubelet
start-service kube-proxy
start-service antrea-agent