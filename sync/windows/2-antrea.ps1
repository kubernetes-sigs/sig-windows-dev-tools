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

Set-PSDebug -Trace 1

mkdir -Force C:\var\log\kpng

# Remove kube-proxy dependency from antrea Agent
nssm.exe set antrea-agent DependOnService -kube-proxy
nssm.exe stop kube-proxy

$KubeProxyConfig="C:/k/antrea/etc/kube-proxy.conf"

# Install kpng.exe as a service
$nssm = (Get-Command nssm).Source

& nssm install kpng "C:/forked/kpng.exe" "kube to-api --kubeconfig=$KubeProxyConfig"
& nssm set kpng Start SERVICE_DELAYED_AUTO_START
& nssm set kpng AppStdout C:\var\log\kpng\kpng.INFO.log
& nssm set kpng AppStderr C:\var\log\kpng\kpng.ERR.log

# Install winuserspace.exe backend as a service
& nssm install winuserspace "C:/forked/winuserspace.exe" "-v=4"
& nssm set winuserspace DependOnService kpng
& nssm set winuserspace Start SERVICE_DELAYED_AUTO_START
& nssm set winuserspace AppStdout C:\var\log\kpng\winuserspace.INFO.log
& nssm set winuserspace AppStderr C:\var\log\kpng\winuserspace.ERR.log

nssm start kpng
nssm start winuserspace
