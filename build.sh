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

    if [ -z "$1" ]
      then
        cd kubernetes
      else 
        # if the path has been provided cd into that path to find the kubernetes directory
        cd "$1"
    fi
    cd kubernetes
    echo "Building binaries"
    ./build/run.sh make kubelet KUBE_BUILD_PLATFORMS=windows/amd64
    ./build/run.sh make kube-proxy KUBE_BUILD_PLATFORMS=windows/amd64
    echo "Copying files to sync"
    cp -r ./_output/dockerized/bin/windows/amd64/ ../sync/bin
}

cleanup () {
    echo "Cleaning up the kubernetes directory"
    pwd
    rm -rf ../kubernetes
}


if [ -z "$1" ]
  then
     if [ -d "kubernetes" ] 
        then
            echo "Directory kubernetes exists." 
            build_binaries
            cleanup
        else
            echo "Directory kubernetes does not exists. Cloning ..."
            git clone https://github.com/kubernetes/kubernetes.git
            build_binaries
            cleanup
        fi
  else 
    build_binaries "$1" 
fi


