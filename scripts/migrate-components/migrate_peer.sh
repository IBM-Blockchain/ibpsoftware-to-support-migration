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


debug "Migrate peers."
mkdir -p ./backups/misc

IBPPEERS=$(kubectl get ibppeer -n $NAMESPACE --no-headers | awk '{print $1}')
for ibppeer in $IBPPEERS; do
    debug "Migrating ibppeer $ibppeer."
    debug "Backing up cr spec."
    PEER_FABRIC_VERSION=$(kubectl get ibppeer -n $NAMESPACE ${ibppeer} -o json | jq -r .spec.version | awk -F"-" '{print $1}')
    kubectl get ibppeer -n $NAMESPACE $ibppeer -o json > ./backups/misc/$ibppeer-mod.json
    
    debug "Updating images in cr spec."
    # update images
    jq --arg peerimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-peer" '.spec.images.peerImage = $peerimage' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json

    jq --arg peertag "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.peerTag = $peertag' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json

    jq --arg initimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-init" '.spec.images.peerInitImage = $initimage' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json

    jq --arg inittag "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.peerInitTag = $inittag' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json

    jq --arg enrollerimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-enroller" '.spec.images.enrollerImage = $enrollerimage' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json
    
    jq --arg enrollertag "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.enrollerTag = $enrollertag' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json

    jq --arg proxyimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-grpcweb" '.spec.images.grpcwebImage = $proxyimage' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json
    
    jq --arg proxytag "${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.grpcwebTag = $proxytag' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json

    jq --arg builderimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-ccenv" '.spec.images.builderImage = $builderimage' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json
    
    jq --arg buildertag "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.builderTag = $buildertag' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json

    jq --arg launcherimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-chaincode-launcher" '.spec.images.chaincodeLauncherImage = $launcherimage' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json
    
    jq --arg launchertag "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.chaincodeLauncherTag = $launchertag' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json

    jq --arg goenvimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-goenv" '.spec.images.goEnvImage = $goenvimage' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json
    
    jq --arg goenvtag "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.goEnvTag = $goenvtag' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json

    jq --arg nodeenvimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-nodeenv" '.spec.images.nodeEnvImage = $nodeenvimage' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json
    
    jq --arg nodeenvtag "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.nodeEnvTag = $nodeenvtag' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json

    jq --arg javaenvimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-javaenv" '.spec.images.javaEnvImage = $javaenvimage' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json
    
    jq --arg javaenvtag "${PEER_FABRIC_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.javaEnvTag = $javaenvtag' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json

    STATEDB=$(kubectl get ibppeer -n $NAMESPACE $ibppeer -o json | jq -r .spec.stateDb)
    echo "statedb is $STATEDB"
    if [[ "$STATEDB" == "couchdb" ]]; then
        jq --arg couchdbimage "${REGISTRY_URL}/ibm-hlfsupport/ibm-hlfsupport-couchdb" '.spec.images.couchdbImage = $couchdbimage' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
        cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json
        
        jq --arg couchdbtag "${COUCHDB_VERSION}-${IMAGE_DATE}-${ARCH}" '.spec.images.couchdbTag = $couchdbtag' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
        cp ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer-mod.json
    fi

    debug "Updating version in cr spec."
    # update spec.version
    jq --arg peerversion "${PEER_FABRIC_VERSION}-${FABRIC_PATCH_VERSION}" '.spec.version = $peerversion' ./backups/misc/$ibppeer-mod.json > ./backups/misc/$ibppeer-temp.json
    mv ./backups/misc/$ibppeer-temp.json ./backups/misc/$ibppeer.json

    debug "Deleting old service so new annotations are picked up."
    # delete service so new annotations are picked up
    kubectl delete -n $NAMESPACE service $ibppeer --ignore-not-found=true

    debug "Applying updated cr spec."
    # apply updated spec
    kubectl apply -f ./backups/misc/$ibppeer.json

    debug "Successfully migrated ibppeer $ibppeer."
done

debug "Successfully migrated peers."