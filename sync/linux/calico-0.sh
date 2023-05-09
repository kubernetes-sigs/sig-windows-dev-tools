#!/bin/bash
echo "running calico installer now with pod_cidr $1"

if [[ "$1" == "" || "$2" == ""  ]]; then
    cat << EOF
    Missing args.
    You need to send pod_cidr and calico version i.e.
    ./calico-0.sh.sh  100.244.0.0/16 3.25.0
    Normally these are in your variables.yml, and piped in by Vagrant.
    So, check that you didn't break the Vagrantfile :)
EOF
  exit 1
fi

pod_cidr=${1}
calico_version=${2}

sleep 2
export KUBECONFIG=/home/vagrant/.kube/config
KUBECONFIG=/home/vagrant/.kube/config


kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-


kubectl create ns calico-system
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v${calico_version}/manifests/tigera-operator.yaml

wget https://raw.githubusercontent.com/projectcalico/calico/v${calico_version}/manifests/custom-resources.yaml -O tigera-custom-resource.yaml
sed -i "s|cidr: 192.168.0.0/16|cidr: ${pod_cidr}|g" tigera-custom-resource.yaml
kubectl create -f tigera-custom-resource.yaml
kubectl patch installation default --type=merge -p '{"spec": {"calicoNetwork": {"bgp": "Disabled"}}}'

echo "waiting 20s for calico pods..."
sleep 20

wget https://raw.githubusercontent.com/projectcalico/calico/v${calico_version}/manifests/calico-windows-vxlan.yaml -O calico-windows.yaml
k8s_service_host=$(kubectl get endpoints kubernetes -n default -o jsonpath='{.subsets[0].addresses[0].ip}')
k8s_service_port=$(kubectl get endpoints kubernetes -n default -o jsonpath='{.subsets[0].ports[0].port}')
sed -i "s|KUBERNETES_SERVICE_HOST: \"\"|KUBERNETES_SERVICE_HOST: \"$k8s_service_host\"|g" calico-windows.yaml
sed -i "s|KUBERNETES_SERVICE_PORT: \"\"|KUBERNETES_SERVICE_PORT: \"$k8s_service_port\"|g" calico-windows.yaml
# TODO - (damei) find a better way to update the configmap
sed -i "s|FELIX_HEALTHENABLED: \"true\"|FELIX_HEALTHENABLED: \"true\"\n  KUBE_NETWORK: \"Calico.*\"|g" calico-windows.yaml
sed -i "s|FELIX_HEALTHENABLED: \"true\"|FELIX_HEALTHENABLED: \"true\"\n  VXLAN_VNI: \"4096\"|g" calico-windows.yaml
sed -i "s|FELIX_HEALTHENABLED: \"true\"|FELIX_HEALTHENABLED: \"true\"\n  VXLAN_MAC_PREFIX: \"0E-2A\"|g" calico-windows.yaml
sed -i "s|FELIX_HEALTHENABLED: \"true\"|FELIX_HEALTHENABLED: \"true\"\n  CALICO_DATASTORE_TYPE: \"kubernetes\"|g" calico-windows.yaml
sed -i "s|FELIX_HEALTHENABLED: \"true\"|FELIX_HEALTHENABLED: \"true\"\n  FELIX_LOGSEVERITYSCREEN: \"debug\"|g" calico-windows.yaml
sed -i "s|FELIX_HEALTHENABLED: \"true\"|FELIX_HEALTHENABLED: \"true\"\n  CALICO_K8S_NODE_REF: \"winw1\"|g" calico-windows.yaml
sed -i "s|FELIX_HEALTHENABLED: \"true\"|FELIX_HEALTHENABLED: \"true\"\n  CNI_IPAM_TYPE: \"calico-ipam\"|g" calico-windows.yaml
sed -i "s|FELIX_HEALTHENABLED: \"true\"|FELIX_HEALTHENABLED: \"true\"\n  KUBECONFIG: \"C:/etc/kubernetes/kubelet.conf\"|g" calico-windows.yaml
kubectl create -f calico-windows.yaml

curl -L https://github.com/projectcalico/calico/releases/download/v${calico_version}/calicoctl-linux-amd64 -o calicoctl
chmod +x ./calicoctl
./calicoctl ipam configure --strictaffinity=true

kubectl get pods -n calico-system