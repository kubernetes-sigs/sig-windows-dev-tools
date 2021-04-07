$NetworkMode="overlay"

$ClusterCIDR="10.244.0.0/16"

$KubeDnsServiceIP="10.96.0.10"

$ServiceCIDR="10.96.0.0/12"

$InterfaceName="Ethernet"

$LogDir="C:\k\logs"

$BaseDir = "c:\k"

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