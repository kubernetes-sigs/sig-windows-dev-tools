#!/bin/sh
echo "running calico installer now...."
sleep 2
export KUBECONFIG=/home/vagrant/.kube/config
KUBECONFIG=/home/vagrant/.kube/config

kubectl create -f /var/sync/forked/calico.yaml
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-

echo "waiting 20s for calico pods..."
sleep 20
# kubectl patch installation default --type=merge -p '{"spec": {"calicoNetwork": {"bgp": "Disabled"}}}'

kubectl get pods -n kube-system

curl -o calicoctl -L "https://github.com/projectcalico/calico/releases/download/v3.23.2/calicoctl-linux-amd64"
chmod 755 calicoctl
./calicoctl ipam configure --strictaffinity=true

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: calico-node-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: calico-node
type: kubernetes.io/service-account-token
EOF
