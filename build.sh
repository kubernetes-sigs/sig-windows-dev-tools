#!/bin/sh


build_binaries () {
    cd kubernetes
    echo "Building binaries"
    ./build/run.sh make kubelet KUBE_BUILD_PLATFORMS=windows/amd64
    ./build/run.sh make kube-proxy KUBE_BUILD_PLATFORMS=windows/amd64
    echo "Copying files to sync"
    cp -ar ./_output/dockerized/bin/windows/amd64/ ../sync/bin
}

cleanup () {
    echo "Cleaning up the kubernetes directory"
    pwd
    rm -rf ../kubernetes
}

if [ -d "kubernetes" ] 
then
    echo "Directory kubernetes exists." 
    build_binaries
    cleanup
else
    echo "Error: Directory kubernetes does not exists.Cloning...."
    git clone https://github.com/kubernetes/kubernetes.git
    build_binaries
    cleanup
fi


