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
debug "Verifying Orderer custom resources."

for orderer_name in $(kubectl -n ${NAMESPACE} get ibporderers.ibp.com --no-headers | awk '{print $1}' | grep node)
do
    debug "Getting IBPOrderer $orderer_name custom resource."
    kubectl -n ${NAMESPACE} get ibporderers.ibp.com ${orderer_name} -o json > ./backups/misc/hlf-orderer-${orderer_name}.json
    ORDER_FABRIC_VERSION=$(kubectl get ibporderer -n $NAMESPACE ${orderer_name} -o json | jq -r .spec.version | awk -F"-" '{print $1}')
    fabric_ver_with_patch=$ORDER_FABRIC_VERSION-$FABRIC_PATCH_VERSION
    orderer_version=$(jq -r .spec.version ./backups/misc/hlf-orderer-${orderer_name}.json)

    debug "Verifying IBPOrderer $orderer_name fabric version."
    if [[ "$orderer_version" != "$fabric_ver_with_patch" ]]; then
        error "orderer ${orderer_name} version is invalid\nExpected: $fabric_ver_with_patch\nActual: $orderer_version"
        exit 1
    fi
    debug "IBPOrderer $orderer_name fabric version is valid."

    debug "Verifying IBPOrderer $orderer_name images in deployment spec."
    # check if hlf-orderer came up with latest images
    check_images="ibm-hlfsupport-grpcweb\|ibm-hlfsupport-init\|ibm-hlfsupport-orderer"
    kubectl -n ${NAMESPACE} get deploy $orderer_name -o=jsonpath={...image} | tr " " "\n" | sort | uniq | grep ${check_images}> ./backups/misc/${orderer_name}-images.txt

cat << EOF > ./backups/misc/${orderer_name}-images-template.txt
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-grpcweb:${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-init:${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-orderer:${ORDER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}
EOF
    diff ./backups/misc/${orderer_name}-images.txt ./backups/misc/${orderer_name}-images-template.txt >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        error "IBPOrderer ${orderer_name} image tags don't match expected values\nExpected: $(cat ${BASEDIR}/backups/misc/${orderer_name}-images-template.txt)\nActual: $(cat ${BASEDIR}/backups/misc/${orderer_name}-images.txt)"
        exit 1
    fi
    debug "IBPOrderer $orderer_name images in deployment spec are valid."

    debug "Verifying IBPOrderer $orderer_name images in cr spec."
    # check if orderer spec has the correct images section
    kubectl -n ${NAMESPACE} get ibporderers.ibp.com $orderer_name -o json | jq .spec.images > ./backups/misc/${orderer_name}-spec-images.json
cat << EOF > ./backups/misc/${orderer_name}-spec-images-template.json
{
  "grpcwebImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-grpcweb",
  "grpcwebTag": "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}",
  "ordererImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-orderer",
  "ordererInitImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-init",
  "ordererInitTag": "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}",
  "ordererTag": "${ORDER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}"
}
EOF

    jq 'del(.enrollerTag, .enrollerImage, .hsmImage, .hsmTag)' ./backups/misc/${orderer_name}-spec-images.json > ./backups/misc/${orderer_name}-spec-images1.json
    diff ./backups/misc/${orderer_name}-spec-images1.json ./backups/misc/${orderer_name}-spec-images-template.json >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        error "IBPOrderer ${orderer_name} image tags don't match expected values\nExpected: $(cat ${BASEDIR}/backups/misc/${orderer_name}-spec-images-template.json)\nActual: $(cat ${BASEDIR}/backups/misc/${orderer_name}-spec-images1.json)"
        exit 1
    fi
    debug "IBPOrderer $orderer_name images in cr spec are valid."
    
    debug "Successfully verified IBPOrderer ${orderer_name} custom resource."
done

debug "Successfully verified Orderer custom resources."