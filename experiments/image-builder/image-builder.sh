#!/bin/bash

# Copyright 2021 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

[[ -n ${DEBUG:-} ]] && set -o xtrace

tmpfile=$(mktemp)

function clean {
    rm -f ${tmpfile}
}

function build_configuration {
 jq --null-input \
    --arg iso_url "${VBOX_WINDOWS_ISO}"             \
    --arg runtime "${VBOX_WINDOWS_RUNTIME}"         \
    --arg custom_role_names "${VBOX_WINDOWS_ROLES}" \
    '{"os_iso_url": $iso_url, "runtime": $runtime, "custom_role_names": $custom_role_names}' > ${tmpfile}
}

IMAGE_BUILDER_FOLDER="${IMAGE_BUILDER_FOLDER:-image-builder}"
IMAGE_BUILDER_BRANCH="${IMAGE_BUILDER_BRANCH:-master}"
IMAGE_BUILDER_REPO="${IMAGE_BUILDER_REPO:-https://github.com/kubernetes-sigs/image-builder.git}"

# Settings and building configuration file from environment variables
VBOX_WINDOWS_ISO="${VBOX_WINDOWS_ISO:-file:/tmp/windows.iso}"
VBOX_WINDOWS_RUNTIME="${VBOX_WINDOWS_RUNTIME:-containerd}"
VBOX_WINDOWS_ROLES=${VBOX_WINDOWS_CUSTOM_ROLES:-cni}

# Cloning the image-builder repository
[[ ! -d ${IMAGE_BUILDER_FOLDER} ]] && git clone ${IMAGE_BUILDER_REPO} ${IMAGE_BUILDER_FOLDER}

# Copy the propper autounattend.xml over to the cloned repository
cp ./overlays/autounattend.xml $IMAGE_BUILDER_FOLDER/packer/vbox/windows/windows-2019/autounattend.xml  

# Checkout the right repository
pushd ${IMAGE_BUILDER_FOLDER}/images/capi
    git checkout ${IMAGE_BUILDER_BRANCH}

    hack/ensure-jq.sh
    build_configuration
    
    # Build local virtualbox artifact
    PACKER_VAR_FILES="${tmpfile}" make build-node-vbox-local-windows-2019
popd

clean
