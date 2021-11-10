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

plugin=./wine2e.yaml
downloadURL=https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.54.0/sonobuoy_0.54.0_linux_amd64.tar.gz
wget $downloadURL
tar -xzf ./sonobuoy_0.54.0_linux_amd64.tar.gz
chmod +x ./sonobuoy
rm ./sonobuoy_*.tar.gz

# Notes:
# - sonobuoy will use the same kubectl that kubectl uses on the control plane. Assumed this will be run from there.
# - Hardcoding the kubernetes version since, as of this testing, we were on an alpha release that didn't have an upstream k8s conformance image
# - Choosing a single, tiny, Windows test which just executes quickly. Can expand as desired.
# - Using the 'main' image of sonobuoy; can be removed once we know it works with the latest tag
./sonobuoy run --wait -p $plugin \
--config ./sonobuoyconfig.json \
--aggregator-node-selector kubernetes.io/os:linux \
--kubernetes-version=v1.22.0 \
--level=trace

./sonobuoy retrieve -f out.tar.gz
./sonobuoy results out.tar.gz
numfailed=$(./sonobuoy results out.tar.gz | grep Failed | cut -d':' -f2 | awk '{$1=$1};1')
if [ "$numfailed" != "0" ]; then
  echo "Failed a non-zero number of tests; exit 1"
  exit 1
fi
exit 0