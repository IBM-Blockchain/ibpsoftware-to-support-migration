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
BASEDIR=$(cd "$(dirname "$0")/.."; pwd)
current_script=`basename "$0"`

# import logging functions
. ${BASEDIR}/common/logger.sh

requiredOCPVersion="^.*4\.([0-9]{2,}|[0-9]?)?(\.[0-9]+.*)*$" ## 4.6+
requiredK8SMinorVersion=17 ## 1.17+
requiredK8SClientMinorVersion=16

function checkOCServerVersion() {
  currentServerVersion="$(oc version -o json | jq .openshiftVersion)"
  if ! [[ $currentServerVersion =~ $requiredOCPVersion ]]; then
    if [ "$currentServerVersion" = null ]; then
      error "Unsupported OpenShift version below 4.6 detected. Supported OpenShift versions are 4.6 and higher."
      customer_action "Please upgrade your cluster to a supported version."
    else
      error "Unsupported OpenShift version $currentServerVersion detected. Supported OpenShift versions are 4.6 and higher."
      customer_action "Please upgrade your cluster to a supported version."
    fi
    exit 1
  fi
}

function checkOCClientVersion() {
  currentClientVersion="$(oc version -o json | jq .clientVersion.gitVersion)"
  if ! [[ $currentClientVersion =~ $requiredOCPVersion ]]; then
    error "Unsupported oc cli version $currentClientVersion detected. Supported oc cli versions are 4.6 and higher."
    customer_action "Please upgrade your oc clie version to a supported version."
    exit 1
  fi
}

function checkK8ServerVersion() {
  currentMinorVersion=$(kubectl version -o json | jq -r .serverVersion.minor)
  if ! [[ $currentMinorVersion -ge $requiredK8SMinorVersion ]]; then
    if [ "$currentMinorVersion" = null ]; then
      error "Unsupported K8S version below 1.${requiredK8SMinorVersion} detected. Supported K8S versions are 1.${requiredK8SMinorVersion} and higher."
      customer_action "Please upgrade your cluster to a supported version."
    else
      error "Unsupported K8S version $currentServerVersion detected. Supported K8S versions are 1.${requiredK8SMinorVersion} and higher."
      customer_action "Please upgrade your cluster to a supported version."
    fi
    exit 1
  fi
}

function checkK8ClientVersion() {
  currentMinorVersion=$(kubectl version -o json | jq -r .clientVersion.minor)
  if ! [[ $currentMinorVersion -ge $requiredK8SClientMinorVersion ]]; then
    error "Unsupported kubectl cli version $currentClientVersion detected. Supported kubectl cli versions are 1.${requiredK8SMinorVersion} and higher."
    customer_action "Please upgrade your kubectl cli version to a supported version."
    exit 1
  fi
}

if [[ "${CLUSTERTYPE}" == "OPENSHIFT" ]]; then
    checkOCClientVersion
    checkOCServerVersion
elif [[ "${CLUSTERTYPE}" == "K8S" ]]; then
    checkK8ClientVersion
    checkK8ServerVersion
fi