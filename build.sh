#!/bin/bash
: '
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
'
set -e

START_DIR=`pwd`
BUILD_FROM_SOURCE=0
VARIABLES_FILE="sync/shared/variables.yaml"

download_binaries () {
    for bin in kubelet kube-proxy kubeadm kubectl
    do
        # windows binaries
        curl "https://storage.googleapis.com/k8s-release-dev/ci/${KUBERNETES_VERSION}/bin/windows/amd64/${bin}.exe" -o $START_DIR/sync/windows/bin/${bin}.exe
        # linux binaries
        curl "https://storage.googleapis.com/k8s-release-dev/ci/${KUBERNETES_VERSION}/bin/linux/amd64/${bin}" -o $START_DIR/sync/linux/bin/${bin}; chmod +x $START_DIR/sync/linux/bin/${bin}
    done
}

build_binaries () {
	echo "building kube locally inside `pwd` from $1"
    echo "changing into directory $1 to start the build"
	pushd $1
	if [[ -d ./_output/dockerized/bin/windows/amd64/ ]]; then
	echo "skipping compilation of windows bits... _output is present"
	else
		echo "running docker build ~ checking memory, make sure its > 4G!!!"
		if [[ `docker system info | grep Memory | cut -d' ' -f 4 |cut -d'.' -f 1` -gt 4 ]] || [[ `docker system info | grep memFree | cut -d' ' -f 4 |cut -d'.' -f 1` -gt 4000000000 ]]; then
			echo "Proceeding with build, docker daemon memory is ok"
		else
			echo "Insufficient LOCAL memory to build k8s before the vagrant builder starts"
			exit 1
		fi

		# use the kubernetes/build/run script to build specific targets...
		./build/run.sh make kubelet KUBE_BUILD_PLATFORMS=windows/amd64
		./build/run.sh make kube-proxy KUBE_BUILD_PLATFORMS=windows/amd64
		./build/run.sh make kubeadm KUBE_BUILD_PLATFORMS=windows/amd64

		./build/run.sh make kubelet KUBE_BUILD_PLATFORMS=linux/amd64
		./build/run.sh make kubectl KUBE_BUILD_PLATFORMS=linux/amd64
		./build/run.sh make kubeadm KUBE_BUILD_PLATFORMS=linux/amd64
	fi
}

copy_to_sync () {
	# TODO replace with https://github.com/kubernetes-sigs/sig-windows-tools/issues/152 at some point
	echo "Copying files to sync in ... $START_DIR"

	# Windows binaries
	cp -f ./_output/dockerized/bin/windows/amd64/kubelet.exe $START_DIR/sync/windows/bin
	cp -f ./_output/dockerized/bin/windows/amd64/kube-proxy.exe $START_DIR/sync/windows/bin
	cp -f ./_output/dockerized/bin/windows/amd64/kubeadm.exe $START_DIR/sync/windows/bin

	# Linux binaries
	cp -f ./_output/dockerized/bin/linux/amd64/kubelet $START_DIR/sync/linux/bin
	cp -f ./_output/dockerized/bin/linux/amd64/kubectl $START_DIR/sync/linux/bin
	cp -f ./_output/dockerized/bin/linux/amd64/kubeadm $START_DIR/sync/linux/bin
	popd
}

cleanup () {
    echo "Cleaning up the kubernetes directory"
    pwd
    rm -rf ../kubernetes
}

# Check if variable is set
if [ -z $1 ]; then
    echo "No path passed to the script, exiting."
    exit 1
fi

# Test if it should be build from source
[[ 
  $(awk '/build_from_source/ {print $2}' ${VARIABLES_FILE} | sed -e 's/^"//' -e 's/"$//' | head -1) =~ "true" 
]] && BUILD_FROM_SOURCE=1

version=`awk '/kubernetes_version/ {print $2}' ${VARIABLES_FILE} | sed -e 's/^"//' -e 's/"$//' | head -1`
KUBERNETES_VERSION=`curl -f https://storage.googleapis.com/k8s-release-dev/ci/latest-${version}.txt`

mkdir -p $START_DIR/sync/windows/bin
mkdir -p $START_DIR/sync/linux/bin

# check if theres an input for the path
if [[ $BUILD_FROM_SOURCE -eq 1 ]] ;then
	echo "Directory Kubernetes provided... building"
	build_binaries $1
    copy_to_sync
	cleanup
else
    download_binaries
fi
