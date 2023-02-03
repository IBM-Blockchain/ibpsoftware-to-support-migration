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
CONSOLE_NAME=$3


mkdir -p ./backups/misc

retries=3
debug "Verifying Console custom resource."

CONSOLE_NAME=$(kubectl -n ${NAMESPACE} get ibpconsole --no-headers | awk '{print $1}')

debug "Getting $CONSOLE_NAME-deployer configmap"
kubectl -n ${NAMESPACE} get cm $CONSOLE_NAME-deployer -o json | jq -r .data.\"settings.yaml\" | yq eval -o=json | jq -r . > ./backups/misc/hlf-versions.json

# check if versions got added
ca_exists=$(jq .versions.ca ./backups/misc/hlf-versions.json)
peer_exists=$(jq .versions.peer ./backups/misc/hlf-versions.json)
orderer_exists=$(jq .versions.orderer ./backups/misc/hlf-versions.json)

debug "Verifying whether versions added to the configmap $CONSOLE_NAME-deployer"
if [[ "${ca_exists}" == "null" ]]; then
    error "Fails to update ca versions in console spec"
    exit 1
fi
if [[ "${peer_exists}" == "null" ]]; then
    error "Fails to update peer versions in console spec"
    exit 1
fi
if [[ "${orderer_exists}" == "null" ]]; then
    error "Fails to update orderer versions in console spec"
    exit 1
fi
debug "Default hlf versions added to the $CONSOLE_NAME-deployer configmap"

fabric_ca_ver_with_patch=$FABRIC_CA_VERSION-$FABRIC_CA_PATCH_VERSION
fabric_ver_with_patch=$PEER_FABRIC_VERSION-$FABRIC_PATCH_VERSION

ca_version=$(jq -r .versions.ca.\"$fabric_ca_ver_with_patch\".version ./backups/misc/hlf-versions.json)
peer_version=$(jq -r .versions.peer.\"$fabric_ver_with_patch\".version ./backups/misc/hlf-versions.json)
orderer_version=$(jq -r .versions.orderer.\"$fabric_ver_with_patch\".version ./backups/misc/hlf-versions.json)

debug "Verifying whether fabric components are at valid version."
if [[ "$ca_version" != "$fabric_ca_ver_with_patch" ]]; then
    error "fabric ca version in console spec is invalid\nExpected: $fabric_ca_ver_with_patch\nActual: $ca_version"
    exit 1
fi
if [[ "$peer_version" != "$fabric_ver_with_patch" ]]; then
    error "fabric peer version in console spec is invalid\nExpected: $fabric_ver_with_patch\nActual: $peer_version"
    exit 1
fi
if [[ "$orderer_version" != "$fabric_ver_with_patch" ]]; then
    error "fabric orderer version in console spec is invalid\nExpected: $fabric_ver_with_patch\nActual: $orderer_version"
    exit 1
fi

debug "Verifying IBPConsole $CONSOLE_NAME deployment images."
# check if hlf-console came up with latest images
kubectl -n $NAMESPACE get deploy $CONSOLE_NAME -o=jsonpath={...image} | tr " " "\n" | sort | uniq > ./backups/misc/console-images.txt

debug "Successfully verified Console custom resource."
