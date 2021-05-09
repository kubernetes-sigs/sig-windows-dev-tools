dism /online /get-features
curl.exe -LO https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/Install-Containerd.ps1
.\Install-Containerd.ps1
ctr.exe version
New-Item -ItemType Directory -Force -Path C:\k
cd C:\k
curl.exe -LO https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/PrepareNode.ps1
PowerShell .\PrepareNode.ps1 -KubernetesVersion v1.20.4 -ContainerRuntime containerD