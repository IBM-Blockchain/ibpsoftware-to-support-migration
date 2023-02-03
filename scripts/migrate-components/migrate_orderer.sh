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

debug "Migrate orderers."
mkdir -p ./backups/misc

IBPORDERERS=$(kubectl get ibporderer -n $NAMESPACE --no-headers | awk '{print $1}')
for ibporderer in $IBPORDERERS; do
    debug "Migrating ibporderer $ibporderer."
    debug "Backing up cr spec."
    kubectl get ibporderer -n $NAMESPACE $ibporderer -o json > ./backups/misc/$ibporderer-mod.json
    ORDER_FABRIC_VERSION=$(kubectl get ibporderer -n $NAMESPACE ${ibporderer} -o json | jq -r .spec.version | awk -F"-" '{print $1}')
    debug "Updating images in cr spec."
    # update images
    # TODO add logic for if overrides were passed and had digests - ignore
    # TODO add logic for if overrides were passed and had tags
    jq --arg ordererimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-orderer" '.spec.images.ordererImage = $ordererimage' ./backups/misc/$ibporderer-mod.json > ./backups/misc/$ibporderer-temp.json
    cp ./backups/misc/$ibporderer-temp.json ./backups/misc/$ibporderer-mod.json

    jq --arg orderertag "${ORDER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.ordererTag = $orderertag' ./backups/misc/$ibporderer-mod.json > ./backups/misc/$ibporderer-temp.json
    cp ./backups/misc/$ibporderer-temp.json ./backups/misc/$ibporderer-mod.json

    jq --arg initimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-init" '.spec.images.ordererInitImage = $initimage' ./backups/misc/$ibporderer-mod.json > ./backups/misc/$ibporderer-temp.json
    cp ./backups/misc/$ibporderer-temp.json ./backups/misc/$ibporderer-mod.json

    jq --arg inittag "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.ordererInitTag = $inittag' ./backups/misc/$ibporderer-mod.json > ./backups/misc/$ibporderer-temp.json
    cp ./backups/misc/$ibporderer-temp.json ./backups/misc/$ibporderer-mod.json

    jq --arg enrollerimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-enroller" '.spec.images.enrollerImage = $enrollerimage' ./backups/misc/$ibporderer-mod.json > ./backups/misc/$ibporderer-temp.json
    cp ./backups/misc/$ibporderer-temp.json ./backups/misc/$ibporderer-mod.json
    
    jq --arg enrollertag "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.enrollerTag = $enrollertag' ./backups/misc/$ibporderer-mod.json > ./backups/misc/$ibporderer-temp.json
    cp ./backups/misc/$ibporderer-temp.json ./backups/misc/$ibporderer-mod.json

    jq --arg proxyimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-grpcweb" '.spec.images.grpcwebImage = $proxyimage' ./backups/misc/$ibporderer-mod.json > ./backups/misc/$ibporderer-temp.json
    cp ./backups/misc/$ibporderer-temp.json ./backups/misc/$ibporderer-mod.json
    
    jq --arg proxytag "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.grpcwebTag = $proxytag' ./backups/misc/$ibporderer-mod.json > ./backups/misc/$ibporderer-temp.json
    cp ./backups/misc/$ibporderer-temp.json ./backups/misc/$ibporderer-mod.json

    debug "Updating version in cr spec."
    # Update spec.version
    jq --arg ordererversion "${ORDER_FABRIC_VERSION}-${FABRIC_PATCH_VERSION}" '.spec.version = $ordererversion' ./backups/misc/$ibporderer-mod.json > ./backups/misc/$ibporderer-temp.json
    mv ./backups/misc/$ibporderer-temp.json ./backups/misc/$ibporderer.json

    debug "Deleting old service so new annotations are picked up."
    # delete service so new annotations are picked up
    kubectl delete -n $NAMESPACE service $ibporderer --ignore-not-found=true

    debug "Applying updated cr spec."
    # apply updated spec
    kubectl apply -f ./backups/misc/$ibporderer.json

    debug "Successfully migrated ibporderer $ibporderer."
done

debug "Successfully migrated orderers."