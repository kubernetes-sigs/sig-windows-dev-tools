#!/bin/sh
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
    echo "building kube from $1"
    startDir=`pwd`
    pushd $1
	    if [[ -d ./_output/dockerized/bin/windows/amd64/ ]]; then
		echo "skipping compilation of windows bits... _output is present"
	    else
	    	./build/run.sh make kubelet KUBE_BUILD_PLATFORMS=windows/amd64
	    	./build/run.sh make kube-proxy KUBE_BUILD_PLATFORMS=windows/amd64
            fi
	    echo "Copying files to sync"
	    cp -r ./_output/dockerized/bin/windows/amd64/ $startDir/sync/bin
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

