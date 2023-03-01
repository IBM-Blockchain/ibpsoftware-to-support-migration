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

LOGGING_COMPONENT=$1
NAMESPACE=$2
DOC_URL=$3

current_script=`basename "$0"`
BASEDIR=$(cd "$(dirname "$0")/.."; pwd)

. ${BASEDIR}/env.sh
${BASEDIR}/common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# import logging functions
. ${BASEDIR}/common/logger.sh

MIN_FABRIC_VERSION=2.2.9
MIN_FABRIC_CA_VERSION=1.5.5

minPeerOrdererFabricVersion="[2-9]\.(2\.(9|1[0-5]))|([4-9]\.[4-9])|[3-9]\.[0-9]\.[3-9]" # 2.2.9+
minCAFabricVersion="[1-9]\.[5-9]\.[5-9]|[2-9]\.[0-9]\.[0-9]" # 1.5.5+

debug "Checking peer fabric versions."
IBPPEERS=$(kubectl get ibppeer -n $NAMESPACE --no-headers | awk '{print $1}')
for ibppeer in $IBPPEERS; do
    debug "Checking IBPPeer $ibppeer."

    SUPPORTED_FABRIC_VERSION=$(cat ${BASEDIR}/check-compatibility/compatible-versions/peer.txt | grep $IMAGE_DATE)
    VERSION_MSG=`echo $SUPPORTED_FABRIC_VERSION | sed  's/ / or /' | sed  's/'-$IMAGE_DATE'//' | sed  's/'-$IMAGE_DATE'//'`
    PEERSPEC=$(kubectl get ibppeer  -n $NAMESPACE ${ibppeer} -o json)
    PEER_PATCH_VERSION=$(echo $PEERSPEC | jq -r .spec.version | awk -F"-" '{print $2}')

    # Check fabric version in spec
    PEERVERSION=$(echo $PEERSPEC | jq -r .spec.version)
    if ! [[ $PEERVERSION =~ $minPeerOrdererFabricVersion ]]; then
        error "IBPPeer $ibppeer version is $PEERVERSION, required to be minimum of $VERSION_MSG."
        customer_action "Please upgrade your $ibppeer before migrating: $DOC_URL"
        exit 1
    fi

    #Check Fabric Version against Release Date
    PEER_VERSION=$PEERVERSION-$IMAGE_DATE
    if [[ $SUPPORTED_FABRIC_VERSION != *$PEER_VERSION* ]]; then
      error "IBPPeer $ibppeer version needs to be upgraded to a minimum of $VERSION_MSG."
      customer_action "Please upgrade your $ibppeer before migrating: $DOC_URL"
      exit 1
    fi
   
    # Check image tag
    PEERTAG=$(echo $PEERSPEC | jq -r .spec.images.peerTag)
    if grep -q "-" <<< $PEERTAG; then
        # Not a digest, need to remove architecture from image tag
        PEERTAG=$(echo $PEERTAG | awk -F"-" '{print $1"-"$2}')
    fi
    PEER_TAG=`echo $PEERTAG | sed  's/-/'-$PEER_PATCH_VERSION-'/'`
    ISVALIDPEERIMAGE=$(cat ${BASEDIR}/check-compatibility/compatible-versions/peer.txt | grep $PEER_TAG)
    if [ -z "$ISVALIDPEERIMAGE" ]; then
        error "IBPPeer $ibppeer using image tag $PEER_TAG, required to use compatible images"
        customer_action "Please upgrade your $ibppeer before migrating: $DOC_URL"
        exit 1
    fi

    debug "IBPPeer $ibppeer is compatible."
done
debug "Peer fabric versions are compatible."

debug "Checking orderer fabric versions."
IBPORDERERS=$(kubectl get ibporderer -n $NAMESPACE --no-headers | awk '{print $1}')
for ibporderer in $IBPORDERERS; do

    debug "Checking IBPOrderer $ibporderer."
    SUPPORTED_FABRIC_VERSION=$(cat ${BASEDIR}/check-compatibility/compatible-versions/orderer.txt | grep $IMAGE_DATE)
    VERSION_MSG=`echo $SUPPORTED_FABRIC_VERSION | sed  's/ / or /' | sed  's/'-$IMAGE_DATE'//' | sed  's/'-$IMAGE_DATE'//'`
    ORDERERSPEC=$(kubectl get ibporderer  -n $NAMESPACE ${ibporderer} -o json)
    parent_exists=$(echo $ORDERERSPEC | jq .metadata.labels.parent)

    #skip the orderer if this is a parent node
    if [[ "$parent_exists" == "null" ]];then
        debug "Skipping $ibporderer because it is a parent node"
        continue
    fi

    # Check fabric version in spec
    ORDERERVERSION=$(echo $ORDERERSPEC | jq -r .spec.version)
    ORDERER_PATCH_VERSION=$(echo $ORDERERSPEC | jq -r .spec.version | awk -F"-" '{print $2}')
 
    if ! [[ $ORDERERVERSION =~ $minPeerOrdererFabricVersion ]]; then
        error "IBPOrderer $ibporderer version is $ORDERERVERSION, required to be minimum of $VERSION_MSG."
        customer_action "Please upgrade your $ibporderer before migrating: $DOC_URL"
        exit 1
    fi

    #Check Fabric Version against Release Date
    ORDERERVERSION=$ORDERERVERSION-$IMAGE_DATE
    if [[ $SUPPORTED_FABRIC_VERSION != *$ORDERERVERSION* ]]; then
      error "IBPPeer $ibporderer version needs to be upgraded to a minimum of $VERSION_MSG."
      customer_action "Please upgrade your $ibporderer before migrating: $DOC_URL"
      exit 1
    fi

    ORDERERTAG=$(echo $ORDERERSPEC | jq -r .spec.images.ordererTag)
    if grep -q "-" <<< $ORDERERTAG; then
        # Not a digest, need to remove architecture from image tag
        ORDERERTAG=$(echo $ORDERERTAG | awk -F"-" '{print $1"-"$2}')
    fi

    ORDERER_TAG=`echo $ORDERERTAG | sed  's/-/'-$ORDERER_PATCH_VERSION-'/'`
    ISVALIDORDERERIMAGE=$(cat ${BASEDIR}/check-compatibility/compatible-versions/orderer.txt | grep $ORDERER_TAG)
    if [ -z "$ISVALIDORDERERIMAGE" ]; then
        error "IBPOrderer $ibporderer using image tag $ORDERER_TAG, required to use compatible images"
        customer_action "Please upgrade your $ibporderer before migrating: $DOC_URL"
        exit 1
    fi

    debug "IBPOrderer $ibporderer is compatible."
done
debug "Orderer fabric versions are compatible."

debug "Checking CA fabric versions."
IBPCAS=$(kubectl get ibpca -n $NAMESPACE --no-headers | awk '{print $1}')
for ibpca in $IBPCAS; do
    debug "Checking IBPCA $ibpca."
    CASPEC=$(kubectl get ibpca  -n $NAMESPACE ${ibpca} -o json)
    CAVERSION=$(echo $CASPEC | jq -r .spec.version)
    CA_PATCH_VERSION=$(echo $CASPEC | jq -r .spec.version | awk -F"-" '{print $2}')
    if ! [[ $CAVERSION =~ $minCAFabricVersion ]]; then
        error "IBPCA $ibpca version is $CAVERSION, required to be minimum at $MIN_FABRIC_CA_VERSION or above."
        customer_action "Please upgrade your $ibpca  before migrating: $DOC_URL"
        exit 1
    fi

    #Check Fabric Version against Release Date
    SUPPORTED_CA_VERSION=$(cat ${BASEDIR}/check-compatibility/compatible-versions/ca.txt | grep $IMAGE_DATE)
    VERSION_MSG=`echo $SUPPORTED_CA_VERSION | sed  's/'-$IMAGE_DATE'//'`
    CA_VERSION=$CAVERSION-$IMAGE_DATE
   if [[ $SUPPORTED_CA_VERSION != *$CA_VERSION* ]]; then
         error "The $ibpca CA version needs to be upgraded to a minimum of $VERSION_MSG."
         customer_action "Please upgrade your $ibpca  before migrating: $DOC_URL"
         exit 1
    fi

    CATAG=$(echo $CASPEC | jq -r .spec.images.caTag)
    if grep -q "-" <<< $CATAG; then
        # Not a digest, need to remove architecture from image tag
        CATAG=$(echo $CATAG | awk -F"-" '{print $1"-"$2}')
    fi
    CA_TAG=`echo $CATAG | sed  's/-/'-$CA_PATCH_VERSION-'/'`
    ISVALIDCAIMAGE=$(cat ${BASEDIR}/check-compatibility/compatible-versions/ca.txt | grep $CA_TAG)
    if [ -z "$ISVALIDCAIMAGE" ]; then
        error "IBPCA $ibpca using image tag $CA_TAG, required to use compatible images"
        customer_action "Please upgrade your $ibpca before migrating: $DOC_URL"
        exit 1
    fi

    debug "IBPCA $ibpca is compatible."
done
debug "CA fabric versions are compatible."