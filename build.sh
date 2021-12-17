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

build_binaries () {
	echo "building kube locally inside `pwd` from $1"
	startDir=`pwd`
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
	# TODO replace with https://github.com/kubernetes-sigs/sig-windows-tools/issues/152 at some point
	echo "Copying files to sync in ... $startDir"
	#win
	mkdir -p $startDir/sync/windows/bin
	cp -f ./_output/dockerized/bin/windows/amd64/kubelet.exe $startDir/sync/windows/bin
	cp -f ./_output/dockerized/bin/windows/amd64/kube-proxy.exe $startDir/sync/windows/bin
	cp -f ./_output/dockerized/bin/windows/amd64/kubeadm.exe $startDir/sync/windows/bin

	#linux
	mkdir -p $startDir/sync/linux/bin
	cp -f ./_output/dockerized/bin/linux/amd64/kubelet $startDir/sync/linux/bin
	cp -f ./_output/dockerized/bin/linux/amd64/kubectl $startDir/sync/linux/bin
	cp -f ./_output/dockerized/bin/linux/amd64/kubeadm $startDir/sync/linux/bin
	popd
}

cleanup () {
    echo "Cleaning up the kubernetes directory"
    pwd
    rm -rf ../kubernetes
}

echo "args $0 -- $1 - "
# check if theres an input for the path
if [[ ! -z "$1" ]] ;then
	echo "Directory kubernetes provided... building"
	build_binaries $1
	cleanup
else
	echo "missing path argument $1 , need a kubernetes/ path"
	exit 1
fi

