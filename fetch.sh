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

# kubernetes version can be passed as param, otherwise it will be read from variables_file

variables_file="sync/shared/variables.yaml"
version=${1:-`awk '/kubernetes_version/ {print \$2}' ${variables_file} | sed -e 's/^"//' -e 's/"$//' | head -1`}
kubernetes_latest_file=`curl -f https://storage.googleapis.com/k8s-release-dev/ci/latest-${version}.txt`

kubernetes_sha=$(echo ${kubernetes_latest_file} | cut -d "+" -f 2)
kubernetes_tag=$(echo ${kubernetes_latest_file} | cut -d "+" -f 1)

if [ ! -z ${kubernetes_sha} ]; then
  echo "Using Kubernetes version ${kubernetes_tag}-${kubernetes_sha} from upstream"
fi

if [[ -d "kubernetes" ]] ; then
  echo "kubernetes/ exists, not cloning..."
  pushd kubernetes
    git checkout $kubernetes_sha -f
  popd
else
  git clone https://github.com/kubernetes/kubernetes.git
  pushd kubernetes
    git checkout $kubernetes_sha
  popd
fi

