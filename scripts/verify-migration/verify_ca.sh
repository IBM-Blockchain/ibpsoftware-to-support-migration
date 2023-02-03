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
debug "Verifying CA custom resources."

for ca_name in $(kubectl -n ${NAMESPACE} get ibpcas.ibp.com --no-headers | awk '{print $1}')
do
    debug "Deleting old CA deployment."
    kubectl delete deploy ${ca_name} -n ${NAMESPACE} 
    sleep 10
    debug "Getting IBPCA $ca_name custom resource."
    kubectl -n ${NAMESPACE} get ibpcas.ibp.com ${ca_name} -o json > ./backups/misc/hlf-ca.json
    FABRIC_CA_VERSION=$(kubectl get ibpca -n $NAMESPACE ${ca_name} -o json | jq -r .spec.version | awk -F"-" '{print $1}')
    fabric_ca_ver_with_patch=$FABRIC_CA_VERSION-$FABRIC_CA_PATCH_VERSION
    ca_version=$(jq -r .spec.version ./backups/misc/hlf-ca.json)

    debug "Verifying IBPCA $ca_name fabric version."
    if [[ "$ca_version" != "$fabric_ca_ver_with_patch" ]]; then
        error "IBPCA ${ca_name} version is invalid\nExpected: $fabric_ca_ver_with_patch\nActual: $ca_version"
        exit 1
    fi
    debug "IBPCA $ca_name fabric version is valid."

    debug "Verifying IBPCA $ca_name images in deployment spec."
    # check if hlf-ca came up with latest images
    kubectl -n ${NAMESPACE} get deploy $ca_name -o=jsonpath={...image} | tr " " "\n" | sort | uniq | grep "ibm-hlfsupport-ca\|ibm-hlfsupport-init" > ./backups/misc/${ca_name}-images.txt

cat << EOF > ./backups/misc/${ca_name}-images-template.txt
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-ca:${FABRIC_CA_VERSION}-${IMAGE_DATE}-${ARCH}
${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-init:${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}
EOF
    diff ./backups/misc/${ca_name}-images.txt ./backups/misc/${ca_name}-images-template.txt >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        error "IBPCA ${ca_name} images tags don't match expected values\nExpected: $(cat ${BASEDIR}/backups/misc/${ca_name}-images-template.txt)\nActual: $(cat ${BASEDIR}/backups/misc/${ca_name}-images.txt)"
        exit 1
    fi
    debug "IBPCA $ca_name images in deployment spec are valid."

    debug "Verifying IBPCA $ca_name images in cr spec"
    # check if ca spec has the correct images section
    kubectl -n ${NAMESPACE} get ibpcas.ibp.com $ca_name -o json | jq .spec.images > ./backups/misc/${ca_name}-spec-images.json
cat << EOF > ./backups/misc/${ca_name}-spec-images-template.json
{
  "caImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-ca",
  "caInitImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-init",
  "caInitTag": "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}",
  "caTag": "${FABRIC_CA_VERSION}-${IMAGE_DATE}-${ARCH}",
  "enrollerImage": "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-enroller",
  "enrollerTag": "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}"
}
EOF
    # ignore hsm imag and tags
    jq 'del(.hsmTag, .hsmImage)' ./backups/misc/${ca_name}-spec-images.json > ./backups/misc/${ca_name}-spec-images1.json
    diff ./backups/misc/${ca_name}-spec-images1.json ./backups/misc/${ca_name}-spec-images-template.json >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        error "IBPCA ${ca_name} image tags don't match expected values\nExpected: $(cat ${BASEDIR}/backups/misc/${ca_name}-spec-images-template.json)\nActual: $(cat ${BASEDIR}/backups/misc/${ca_name}-spec-images1.json)"
        exit 1
    fi
    debug "IBPCA $ca_name images in cr spec are valid."

    debug "Successfully verified IBPCA ${ca_name} custom resource."
done

debug "Successfully verified CA custom resources."