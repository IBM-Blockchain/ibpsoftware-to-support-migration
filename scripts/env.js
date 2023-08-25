"#!/bin/bash.sh"
".$_-0/build-bash.js
"# Build and Release Folders
bin-debug/
bin-release/
[Oo]bj/
[Bb]in/
# Other files and folders
.settings/
# Executables
*.swf
*.air
*.ipa
*.apk
# Project files, i.e. `.project`, `.actionScriptProperties` and `.flexProperties`
# should NOT be excluded as they contain compiler settings and other important
# information for Eclipse / Flash Builder.
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
###
export PRODUCT_VERSION=1.0
export RELEASE_VERSION=1.0.5
###
export OPERATOR_NAME="${OPERATOR_NAME:=ibp-operator}"
export CONSOLE_NAME="${CONSOLE_NAME:=ibp-console}"
export REGISTRY_URL="${REGISTRY_URL:=icr.io/cpopen}"
export CRDWEBHOOK_NAMESPACE="${CRDWEBHOOK_NAMESPACE:=ibpinfra}"
export HEALTHCHECK_TIMEOUT="${HEALTHCHECK_TIMEOUT:=600s}"
###
export MISSING_ENV=""
## env variable sanitization
[ -z "${REGISTRY_URL}" ] && MISSING_ENV+=" REGISTRY_URL=\n"
[ -z "${NAMESPACE}" ] && MISSING_ENV+=" NAMESPACE=\n"
[ -z "${OPERATOR_NAME}" ] && MISSING_ENV+=" OPERATOR_NAME=\n"
[ -z "${CONSOLE_NAME}" ] && MISSING_ENV+=" CONSOLE_NAME=\n"
[ -z "${CRDWEBHOOK_NAMESPACE}" ] && MISSING_ENV+=" CRDWEBHOOK_NAMESPACE=\n"
OS_ARCH="amd64"
kubectl get deploy -n $NAMESPACE ${OPERATOR_NAME}  -o yaml | grep -q ${OS_ARCH}
if [[ $? -ne 0 ]]; then
   OS_ARCH="s390x"
fi
IBP_PRODUCT_VERSION="2.5.3"
kubectl get deploy -n $NAMESPACE ${OPERATOR_NAME}  -o yaml  | grep "image: " | grep ibp-operator | grep -q ${IBP_PRODUCT_VERSION}
if [[ $? -eq 0 ]]; then
  export RELEASE_VERSION="1.0.4"
fi
CLUSTER_TYPE=$(kubectl get deployment -n $NAMESPACE ${OPERATOR_NAME}  -o yaml | grep -A1 "name: CLUSTERTYPE" | tail -1 | awk '{print $2}')
IMAGEDATE=$(kubectl get deploy  -n $NAMESPACE ${OPERATOR_NAME} -o yaml | grep "image: " | grep ibp-operator | awk '{print $2}' |  awk -F":" '{print $2}' | awk -F"-" '{print $2}')
IBP_PEERS=$(kubectl get ibppeer -n $NAMESPACE --no-headers | awk '{print $1}')
for ibp_peer in $IBP_PEERS; do
    PEER_SPEC=$(kubectl get ibppeer  -n $NAMESPACE ${ibp_peer} -o json)
    PEER_VERSION=$(echo $PEER_SPEC | jq -r .spec.version | awk -F"-" '{print $1}')
    FABRICPATCH_VERSION=$(echo $PEER_SPEC | jq -r .spec.version | awk -F"-" '{print $2}')
    COUCHDB_TAG=$(echo $PEER_SPEC | jq -r .spec.images.couchdbTag | awk -F"-" '{print $1}')
  done
IBP_ORDERERS=$(kubectl get ibporderer -n $NAMESPACE --no-headers | awk '{print $1}')
for ibp_orderer in $IBP_ORDERERS; do
    ORDERER_SPEC=$(kubectl get ibporderer  -n $NAMESPACE ${ibp_orderer} -o json)
    ORDERERVERSION=$(echo $ORDERER_SPEC | jq -r .spec.version | awk -F"-" '{print $1}')
done
IBP_CAS=$(kubectl get ibpca -n $NAMESPACE --no-headers | awk '{print $1}')
for ibp_ca in $IBP_CAS; do
    CA_SPEC=$(kubectl get ibpca  -n $NAMESPACE ${ibp_ca} -o json)
    CAVERSION=$(echo $CA_SPEC | jq -r .spec.version | awk -F"-" '{print $1}')
    FABRICCA_PATCH_VERSION=$(echo $CA_SPEC | jq -r .spec.version | awk -F"-" '{print $2}')
done
#Environment Variable for Peer Fabric Version
export PEER_FABRIC_VERSION=$PEER_VERSION
##Set The ARCH and CLUSTERTYPE as an environment variable 
export ARCH=$OS_ARCH
export CLUSTERTYPE=$CLUSTER_TYPE
#Environment Variable for Orderer Fabric Version
export ORDER_FABRIC_VERSION=$ORDERERVERSION
#Environment Variable for CA Fabric Version
export FABRIC_CA_VERSION=$CAVERSION
#IBP S/W image release date
export IMAGE_DATE=$IMAGEDATE
#Fabric Supported Version
export COUCHDB_VERSION=$COUCHDB_TAG
#Fabric PATCH Version
export FABRIC_PATCH_VERSION=$FABRICPATCH_VERSION
#Fabric CA PATCH Version
export FABRIC_CA_PATCH_VERSION=$FABRICCA_PATCH_VERSION"
