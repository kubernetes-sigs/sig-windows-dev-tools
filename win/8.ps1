$KubeletSvc="kubelet"

$KubeProxySvc="kube-proxy"

$FlanneldSvc="flanneld2"

$Hostname=$(hostname).ToLower()


iwr -outf nssm.zip https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip

Expand-Archive nssm.zip

mv C:\k\nssm\nssm-2.24-101-g897c7ad\win64\*.exe C:\k


# register & start flanneld

.\nssm.exe install $FlanneldSvc C:\flannel\flanneld.exe

.\nssm.exe set $FlanneldSvc AppParameters --kubeconfig-file=c:\k\config --iface=10.0.0.11 --ip-masq=1 --kube-subnet-mgr=1

.\nssm.exe set $FlanneldSvc AppEnvironmentExtra NODE_NAME=$Hostname

.\nssm.exe set $FlanneldSvc AppDirectory C:\flannel

.\nssm.exe start $FlanneldSvc


# register & start kubelet

.\nssm.exe install $KubeletSvc C:\k\kubelet.exe

.\nssm.exe set $KubeletSvc AppParameters --hostname-override=$Hostname --v=6 --pod-infra-container-image=mcr.microsoft.com/k8s/core/pause:1.0.0 --resolv-conf=""  --enable-debugging-handlers --cluster-dns=$KubeDnsServiceIP --cluster-domain=cluster.local --kubeconfig=c:\k\config --hairpin-mode=promiscuous-bridge --image-pull-progress-deadline=20m --cgroups-per-qos=false  --log-dir=$LogDir --logtostderr=false --enforce-node-allocatable="" --network-plugin=cni --cni-bin-dir=c:\k\cni --cni-conf-dir=c:\k\cni\config

.\nssm.exe set $KubeletSvc AppDirectory C:\k

.\nssm.exe start $KubeletSvc


# register & start kube-proxy

.\nssm.exe install $KubeProxySvc C:\k\kube-proxy.exe

.\nssm.exe set $KubeProxySvc AppDirectory c:\k

GetSourceVip -ipAddress 10.0.0.11 -NetworkName $NetworkName

$sourceVipJSON = Get-Content sourceVip.json | ConvertFrom-Json

$sourceVip = $sourceVipJSON.ip4.ip.Split("/")[0]

.\nssm.exe set $KubeProxySvc AppParameters --v=4 --proxy-mode=kernelspace --feature-gates="WinOverlay=true" --hostname-override=$Hostname --kubeconfig=c:\k\config --network-name=vxlan0 --source-vip=$sourceVip --enable-dsr=false --cluster-cidr=$ClusterCIDR --log-dir=$LogDir --logtostderr=false

.\nssm.exe set $KubeProxySvc DependOnService $KubeletSvc

.\nssm.exe start $KubeProxySvc