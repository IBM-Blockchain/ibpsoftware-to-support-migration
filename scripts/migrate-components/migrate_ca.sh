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


debug "Migrate CAs."
mkdir -p ./backups/misc

IBPCAS=$(kubectl get ibpca -n $NAMESPACE --no-headers | awk '{print $1}')
for ibpca in $IBPCAS; do
    debug "Migrating ibpca $ibpca."
    debug "Backing up cr spec."
    kubectl get ibpca -n $NAMESPACE $ibpca -o json > ./backups/misc/$ibpca-mod.json
    FABRIC_CA_VERSION=$(kubectl get ibpca -n $NAMESPACE ${ibpca} -o json | jq -r .spec.version | awk -F"-" '{print $1}')
    debug "Updating images in cr spec."
    # update images
    # TODO add logic for if overrides were passed and had digests - ignore
    # TODO add logic for if overrides were passed and had tags
    jq --arg caimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-ca" '.spec.images.caImage = $caimage' ./backups/misc/$ibpca-mod.json > ./backups/misc/$ibpca-temp.json
    cp ./backups/misc/$ibpca-temp.json ./backups/misc/$ibpca-mod.json

    jq --arg catag "${FABRIC_CA_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.caTag = $catag' ./backups/misc/$ibpca-mod.json > ./backups/misc/$ibpca-temp.json
    cp ./backups/misc/$ibpca-temp.json ./backups/misc/$ibpca-mod.json

    jq --arg cainitimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-init" '.spec.images.caInitImage = $cainitimage' ./backups/misc/$ibpca-mod.json > ./backups/misc/$ibpca-temp.json
    cp ./backups/misc/$ibpca-temp.json ./backups/misc/$ibpca-mod.json

    jq --arg cainittag "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.caInitTag = $cainittag' ./backups/misc/$ibpca-mod.json > ./backups/misc/$ibpca-temp.json
    cp ./backups/misc/$ibpca-temp.json ./backups/misc/$ibpca-mod.json

    jq --arg enrollerimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-enroller" '.spec.images.enrollerImage = $enrollerimage' ./backups/misc/$ibpca-mod.json > ./backups/misc/$ibpca-temp.json
    cp ./backups/misc/$ibpca-temp.json ./backups/misc/$ibpca-mod.json
    
    jq --arg enrollertag "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.enrollerTag = $enrollertag' ./backups/misc/$ibpca-mod.json > ./backups/misc/$ibpca-temp.json
    cp ./backups/misc/$ibpca-temp.json ./backups/misc/$ibpca-mod.json

    debug "Updating version in cr spec."
    #update spec.version
    jq --arg version "${FABRIC_CA_VERSION}-${FABRIC_CA_PATCH_VERSION}" '.spec.version = $version' ./backups/misc/$ibpca-mod.json > ./backups/misc/$ibpca-temp.json
    cp ./backups/misc/$ibpca-temp.json ./backups/misc/$ibpca-mod.json

    mv ./backups/misc/$ibpca-mod.json ./backups/misc/$ibpca.json
  
    debug "Deleting old service so new annotations are picked up."
    # delete service so new annotations are picked up
    kubectl delete -n $NAMESPACE service $ibpca --ignore-not-found=true

    debug "Applying updated cr spec."
    # apply updated console spec
    kubectl apply -f ./backups/misc/$ibpca.json
    
    debug "Successfully migrated ibpca $ibpca."
done

debug "Successfully migrated CAs."