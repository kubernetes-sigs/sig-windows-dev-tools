##make sure docker is running
#Start-Service docker

##pull and tag the docker image, that is used by kubernetes
#docker image pull mcr.microsoft.com/windows/nanoserver:1809
#docker image tag mcr.microsoft.com/windows/nanoserver:1809 microsoft/nanoserver:latest

##
Write-Output "# create the kubernetes folder"
#!! if you want to use another version of Kubernetes than 1.20.4, change the url

New-Item -ItemType Directory -Force -Path C:\k

cd C:\k

#$ProgressPreference=SilentlyContinue
Write-Output "# downloading kubernetes binaries"
$ProgressPreference = 'SilentlyContinue' #this, -somehow- makes the download faster
iwr -ContentType "application/octet-stream" -outf kubernetes-node-windows-amd64.tar.gz "https://dl.k8s.io/v1.20.4/kubernetes-node-windows-amd64.tar.gz"

Write-Output "# unpacking kubernetes binaries"
tar -xkf kubernetes-node-windows-amd64.tar.gz -C C:\k

mv C:\k\kubernetes\node\bin\*.exe C:\k

##
Write-Output "# install the binaries"

$NetworkMode="overlay"

$ClusterCIDR="10.244.0.0/16"

$KubeDnsServiceIP="10.96.0.10"

$ServiceCIDR="10.96.0.0/12"

$InterfaceName="Ethernet"

$LogDir="C:\k\logs"

$BaseDir = "C:\k"

$NetworkMode = $NetworkMode.ToLower()

$NetworkName = "vxlan0"

$GithubSDNRepository = 'Microsoft/SDN'

$helper = "c:\k\helper.psm1"

if (!(Test-Path $helper))

{

   Start-BitsTransfer "https://raw.githubusercontent.com/$GithubSDNRepository/master/Kubernetes/windows/helper.psm1" -Destination c:\k\helper.psm1

}

ipmo $helper

$install = "c:\k\install.ps1"

if (!(Test-Path $install))

{

   Start-BitsTransfer "https://raw.githubusercontent.com/$GithubSDNRepository/master/Kubernetes/windows/install.ps1" -Destination c:\k\install.ps1

}

powershell $install -NetworkMode "$NetworkMode" -clusterCIDR "$ClusterCIDR" -KubeDnsServiceIP "$KubeDnsServiceIP" -serviceCIDR "$ServiceCIDR" -InterfaceName "'$InterfaceName'" -LogDir "$LogDir"

##
Write-Output "# copy config gile from synced folder, that was created by the linux master node"

Copy-Item "C:\sync\config" -Destination "C:\k" -Force

##
Write-Output "# register the node"

powershell $BaseDir\start-kubelet.ps1 -RegisterOnly -NetworkMode $NetworkMode

ipmo C:\k\hns.psm1

RegisterNode

##
Write-Output "# start kubernetes service and join the cluster"
#!! if you want to use another ip than 10.0.0.10 you have to change it here 2x

$KubeletSvc="kubelet"

$KubeProxySvc="kube-proxy"

$FlanneldSvc="flanneld2"

$Hostname=$(hostname).ToLower()

iwr -outf nssm.zip "https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip"

Expand-Archive nssm.zip

mv C:\k\nssm\nssm-2.24-101-g897c7ad\win64\*.exe C:\k

#
Write-Output "# register & start flanneld"

.\nssm.exe install $FlanneldSvc C:\flannel\flanneld.exe

.\nssm.exe set $FlanneldSvc AppParameters --kubeconfig-file=c:\k\config --iface=10.0.0.11 --ip-masq=1 --kube-subnet-mgr=1

.\nssm.exe set $FlanneldSvc AppEnvironmentExtra NODE_NAME=$Hostname

.\nssm.exe set $FlanneldSvc AppDirectory C:\flannel

.\nssm.exe start $FlanneldSvc

#
Write-Output "# register & start kubelet"

.\nssm.exe install $KubeletSvc "C:\k\kubelet.exe"

.\nssm.exe set $KubeletSvc AppParameters --hostname-override=$Hostname --v=6 --pod-infra-container-image=mcr.microsoft.com/k8s/core/pause:1.0.0 --resolv-conf=""  --enable-debugging-handlers --cluster-dns=$KubeDnsServiceIP --cluster-domain=cluster.local --kubeconfig=c:\k\config --hairpin-mode=promiscuous-bridge --image-pull-progress-deadline=20m --cgroups-per-qos=false  --log-dir=$LogDir --logtostderr=false --enforce-node-allocatable="" --network-plugin=cni --cni-bin-dir=c:\k\cni --cni-conf-dir=c:\k\cni\configuration Name {
      
   # One can evaluate expressions to get the node list
      # E.g: $AllNodes.Where("Role -eq Web").NodeName
   
      #node ("Node1","Node2","Node3")
      node ("winw1")

   {

         # Call Resource Provider
         # E.g: WindowsFeature, File

      WindowsFeature FriendlyName

      {

         Ensure = "Present"

         Name = "Feature Name"

      }

      File FriendlyName

      {

         Ensure = "Present"

         SourcePath = $SourcePath

         DestinationPath = $DestinationPath

         Type = "Directory"

         DependsOn = "[WindowsFeature]FriendlyName"

      }

   }

}

.\nssm.exe set $KubeletSvc AppDirectory C:\k

.\nssm.exe start $KubeletSvc

#
Write-Output "#register & start kube-proxy"

Write-Output "1"

.\nssm.exe install $KubeProxySvc C:\k\kube-proxy.exe

Write-Output "2"

.\nssm.exe set $KubeProxySvc AppDirectory C:\k

Write-Output "3"

GetSourceVip -ipAddress 10.0.0.10 -NetworkName $NetworkName

Write-Output "4"

$sourceVipJSON = Get-Content sourceVip.json | ConvertFrom-Json

Write-Output "5"

$sourceVip = $sourceVipJSON.ip4.ip.Split("/")[0]

Write-Output "6"

.\nssm.exe set $KubeProxySvc AppParameters --v=4 --proxy-mode=kernelspace --feature-gates="WinOverlay=true" --hostname-override=$Hostname --kubeconfig=c:\k\config --network-name=vxlan0 --source-vip=$sourceVip --enable-dsr=false --cluster-cidr=$ClusterCIDR --log-dir=$LogDir --logtostderr=false

Write-Output "7"

.\nssm.exe set $KubeProxySvc DependOnService $KubeletSvc

Write-Output "8"

.\nssm.exe start $KubeProxySvc

Get-Service kube*