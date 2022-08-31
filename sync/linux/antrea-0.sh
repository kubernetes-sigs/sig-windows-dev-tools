#!/bin/bash
export KUBECONFIG=/home/vagrant/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl apply -f https://github.com/antrea-io/antrea/releases/download/v1.8.0/antrea.yml

sleep 20
