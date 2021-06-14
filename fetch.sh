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
variables_file="sync/shared/variables.yaml"

# kubernetes version can be passed as param, else it will be read from variables_file, if that doesnt exists it uses the default "1.21.0"
kubernetes_version=${1}
if [ -z "$kubernetes_version" ]; then
  if [ -f variables_file ]; then
    $kubernetes_version=$(awk '/kubernetes_version_build/ {print $2}' $variables_file | sed -e 's/^"//' -e 's/"$//'); #read param ffrom file
  else 
    $kubernetes="1.21.1"
  fi
fi

echo "Using $KUBERNETESVERSION as the Kubernetes version"

if [[ -d "kubernetes" ]] ; then
	echo "kubernetes/ exists, not cloning..."
else
  echo "clone kubernetes..."
  git clone https://github.com/kubernetes/kubernetes.git --branch v$KUBERNETESVERSION
fi

# BELOW THIS LINE ADD YOUR CUSTOM BUILD LOGIC #########
# FOR EXAMPLE
# pushd kubernetes
# git fetch origin refs/pull/97812/head:antonio
# git checkout -b antonio
# rm -rf _output
# pop
