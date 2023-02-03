#!/bin/bash

#
# Copyright contributors to the Migration
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
# 	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

BASEDIR=$(cd "$(dirname "$0")/.."; pwd)
current_script=`basename "$0"`

. ${BASEDIR}/env.sh
${BASEDIR}/common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# import logging functions
. ${BASEDIR}/common/logger.sh

LOGGING_COMPONENT=$1
NAMESPACE=$2


mkdir -p ./backups/misc

retries=3
debug "Verifying Peer custom resources."

for peer_name in $(kubectl -n ${NAMESPACE} get ibppeers.ibp.com --no-headers | awk '{print $1}')
do
    debug "Getting IBPPeer $peer_name custom resource."
    PEER_FABRIC_VERSION=$(kubectl get ibppeer -n $NAMESPACE ${peer_name} -o json | jq -r .spec.version | awk -F"-" '{print $1}')
    kubectl -n ${NAMESPACE} get ibppeers.ibp.com ${peer_name} -o json > ./backups/misc/hlf-peer.json

    fabric_ver_with_patch=$PEER_FABRIC_VERSION-$FABRIC_PATCH_VERSION
    peer_version=$(jq -r .spec.version ./backups/misc/hlf-peer.json)

    debug "Verifying IBPPeer $peer_name fabric version"
    if [[ "$peer_version" != "$fabric_ver_with_patch" ]]; then
        error "IBPPeer ${peer_name} version is invalid\nExpected: $fabric_ver_with_patch\nActual: $peer_version"
        exit 1
    fi
    debug "IBPPeer $peer_name fabric version is valid."

    check_images="ibm-hlfsupport-chaincode-launcher\|ibm-hlfsupport-grpcweb\|ibm-hlfsupport-init\|ibm-hlfsupport-peer"
    statedb=$(jq -r .spec.stateDb ./backups/misc/hlf-peer.json)

if [[ "${statedb}" = "leveldb" ]]; then
cat << EOF > ./backups/misc/${peer_name}-images-template.txt
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-chaincode-launcher:${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-grpcweb:${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-init:${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-peer:${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}
EOF
else
cat << EOF > ./backups/misc/${peer_name}-images-template.txt
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-chaincode-launcher:${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-couchdb:${COUCHDB_VERSION}-${IMAGE_DATE}-${ARCH}
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-grpcweb:${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-init:${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-peer:${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}
EOF
    check_images="ibm-hlfsupport-chaincode-launcher\|ibm-hlfsupport-grpcweb\|ibm-hlfsupport-init\|ibm-hlfsupport-peer\|ibm-hlfsupport-couchdb"
fi

    debug "Verifying IBPPeer $peer_name images in deployment spec."
    # check if hlf-peer came up with latest images
    kubectl -n ${NAMESPACE} get deploy $peer_name -o=jsonpath={...image} | tr " " "\n" | sort | uniq | grep ${check_images} > ./backups/misc/${peer_name}-images.txt

    diff ./backups/misc/${peer_name}-images.txt ./backups/misc/${peer_name}-images-template.txt >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        error "IBPPeer ${peer_name} image tags don't match expected values\nExpected: $(cat ${BASEDIR}/backups/misc/${peer_name}-images-template.txt)\nActual: $(cat ${BASEDIR}/backups/misc/${peer_name}-images.txt)"
        exit 1
    fi
    debug "IBPPeer $peer_name images in deployment spec are valid."

    debug "Verifying IBPPeer $peer_name images in cr spec."
    # check if peer spec has the correct images section
    kubectl -n ${NAMESPACE} get ibppeers.ibp.com $peer_name -o json | jq .spec.images > ./backups/misc/${peer_name}-spec-images.json

cat << EOF > ./backups/misc/${peer_name}-spec-images-template.json
{
  "builderImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-ccenv",
  "builderTag": "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}",
  "chaincodeLauncherImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-chaincode-launcher",
  "chaincodeLauncherTag": "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}",
  "couchdbImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-couchdb",
  "couchdbTag": "${COUCHDB_VERSION}-${IMAGE_DATE}-${ARCH}",
  "enrollerImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-enroller",
  "enrollerTag": "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}",
  "goEnvImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-goenv",
  "goEnvTag": "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}",
  "grpcwebImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-grpcweb",
  "grpcwebTag": "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}",
  "javaEnvImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-javaenv",
  "javaEnvTag": "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}",
  "nodeEnvImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-nodeenv",
  "nodeEnvTag": "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}",
  "peerImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-peer",
  "peerInitImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-init",
  "peerInitTag": "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}",
  "peerTag": "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}"
}
EOF
    if [[ "${statedb}" = "leveldb" ]]; then
        jq 'del(.dindTag, .dindImage, .couchdbTag, .couchdbImage, .hsmImage, .hsmTag)' ./backups/misc/${peer_name}-spec-images.json > ./backups/misc/${peer_name}-spec-images1.json
        jq 'del(.dindTag, .dindImage, .couchdbTag, .couchdbImage, .hsmImage, .hsmTag)' ./backups/misc/${peer_name}-spec-images-template.json  > ./backups/misc/${peer_name}-spec-images-template1.json
    else
        jq 'del(.dindTag, .dindImage, .hsmImage, .hsmTag)' ./backups/misc/${peer_name}-spec-images.json > ./backups/misc/${peer_name}-spec-images1.json
        jq 'del(.dindTag, .dindImage, .hsmImage, .hsmTag)' ./backups/misc/${peer_name}-spec-images-template.json  > ./backups/misc/${peer_name}-spec-images-template1.json
    fi
    diff ./backups/misc/${peer_name}-spec-images1.json ./backups/misc/${peer_name}-spec-images-template1.json >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        error "IBPPeer ${peer_name} image tags don't match expected values\nExpected: $(cat ${BASEDIR}/backups/misc/${peer_name}-spec-images-template1.json)\nActual: $(cat ${BASEDIR}/backups/misc/${peer_name}-spec-images1.json)"
        exit 1
    fi
    debug "IBPPeer $peer_name images in cr spec are valid."

    debug "Succeffully verified IBPPeer spec ${peer_name} images and versions."
done

debug "Successfully verified peer custom resources"