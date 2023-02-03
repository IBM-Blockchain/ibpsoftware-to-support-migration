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
REGISTRY_URL=$2
REGISTRY_USERNAME=$3 
REGISTRY_TOKEN=$4

BASEDIR=$(cd "$(dirname "$0")/.."; pwd)
current_script=`basename "$0"`

. ${BASEDIR}/env.sh
${BASEDIR}/common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# import logging functions
. ${BASEDIR}/common/logger.sh

if [ -z "${REGISTRY_URL}" ] || [ -z "${REGISTRY_USERNAME}" ] || [ -z "${REGISTRY_TOKEN}" ]; then
    error "credentials must not be empty !!"
    exit 1
fi

debug "Validating credentials."

docker login ${REGISTRY_URL} -u ${REGISTRY_USERNAME} -p ${REGISTRY_TOKEN}
res=$?
if [ $res != 0 ]; then
    error "unable to login with the credentials."
    exit 1
fi

## check with docker pull to inspect credentials
docker pull ${REGISTRY_URL}/ibm-hlfsupport-crdwebhook:${PRODUCT_VERSION}-${IMAGE_DATE}-${ARCH}
res=$?
if [ $res != 0 ]; then
    docker logout ${REGISTRY_URL}
    error "Unable to pull the images with the credentials."
    exit 1
fi

docker logout ${REGISTRY_URL}
debug "Successfuly validated credentials."
