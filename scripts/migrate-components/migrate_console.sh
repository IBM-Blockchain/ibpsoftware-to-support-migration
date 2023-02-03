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
current_script=`basename "$0"`
BASEDIR=$(cd "$(dirname "$0")"; pwd)

. ${BASEDIR}/../env.sh
${BASEDIR}/../common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# import logging functions
. ${BASEDIR}/../common/logger.sh

LOGGING_COMPONENT=$1
NAMESPACE=$2
CONSOLE_NAME=$3


mkdir -p ./backups/misc

debug "Migrate console $CONSOLE_NAME."

debug "Backing up console cr spec."
kubectl get -n $NAMESPACE ibpconsole ${CONSOLE_NAME} -o json > ./backups/misc/ibpconsole-mod.json


debug "Updating registry url in console cr spec."
# update registry url
jq --arg registryurl "${REGISTRY_URL}/ibm-hlfsupport" '.spec.registryURL = $registryurl' ./backups/misc/ibpconsole-mod.json > ./backups/misc/ibpconsole-temp.json
cp ./backups/misc/ibpconsole-temp.json ./backups/misc/ibpconsole-mod.json

debug "Removing versions from console cr spec."
# remove spec.version if exists
jq 'del(.spec.versions)' ./backups/misc/ibpconsole-mod.json > ./backups/misc/ibpconsole-temp.json
mv ./backups/misc/ibpconsole-temp.json ./backups/misc/ibpconsole.json

debug "Deleting old deployer configmap."
# delete deployer-cm & console deployment spec
kubectl delete -n $NAMESPACE cm ${CONSOLE_NAME}-deployer
debug "Deleting old console deployment."
kubectl delete -n $NAMESPACE deploy ${CONSOLE_NAME}

debug "Deleting old service so new annotations are picked up."
# delete service so new annotations are picked up
kubectl delete -n $NAMESPACE service ${CONSOLE_NAME}

debug "Applying updated console cr spec."
# apply updated console spec
kubectl apply -f ./backups/misc/ibpconsole.json

debug "Successfully migrated console $CONSOLE_NAME."