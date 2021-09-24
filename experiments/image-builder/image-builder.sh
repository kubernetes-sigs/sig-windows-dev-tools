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
OVERLAYS_FOLDER=${ROOT_OVERLAYS:-${PWD}/overlays}

IMAGE_BUILDER_FOLDER="${IMAGE_BUILDER_FOLDER:-image-builder}"
IMAGE_BUILDER_BRANCH="${IMAGE_BUILDER_BRANCH:-master}"
IMAGE_BUILDER_REPO="${IMAGE_BUILDER_REPO:-https://github.com/kubernetes-sigs/image-builder.git}"
CAPI_IMAGES_PATH=${IMAGE_BUILDER_FOLDER}/images/capi

# Settings and building configuration file from environment variables
VBOX_WINDOWS_ISO="${VBOX_WINDOWS_ISO:-file:/tmp/windows.iso}"
VBOX_WINDOWS_RUNTIME="${VBOX_WINDOWS_RUNTIME:-containerd}"
VBOX_WINDOWS_ROLES=${VBOX_WINDOWS_CUSTOM_ROLES:-cni}

function clean {
    rm -f ${tmpfile}
}

function build_configuration {
 jq --null-input \
    --arg iso_url "${VBOX_WINDOWS_ISO}"             \
    --arg runtime "${VBOX_WINDOWS_RUNTIME}"         \
    --arg custom_role_names "${VBOX_WINDOWS_ROLES}" \
    '{"os_iso_url": $iso_url, "runtime": $runtime, "ansible_extra_vars": "custom_role=true", "custom_role_names": $custom_role_names}' > ${tmpfile}
}

function copy_overlay_files {
    # Overlay copy
    cp -r ${OVERLAYS_FOLDER}/ansible/roles/cni ./ansible/windows/roles/
    cp ${OVERLAYS_FOLDER}/autounattend.xml ./packer/vbox/windows/windows-2019/autounattend.xml  
    cp ${OVERLAYS_FOLDER}/vm-guest-tools.ps1 ./packer/vbox/windows/vm-guest-tools.ps1
    cp ${OVERLAYS_FOLDER}/packer-windows.json ./packer/vbox/packer-windows.json
}

# Cloning the image-builder repository
[[ ! -d ${IMAGE_BUILDER_FOLDER} ]] && git clone ${IMAGE_BUILDER_REPO} ${IMAGE_BUILDER_FOLDER}


# Build local virtualbox artifact
pushd ${CAPI_IMAGES_PATH}
    hack/ensure-jq.sh
    git checkout ${IMAGE_BUILDER_BRANCH}

    build_configuration
    copy_overlay_files

    make clean-vbox
    PACKER_VAR_FILES="${tmpfile}" make build-node-vbox-local-windows-2019
popd

clean
