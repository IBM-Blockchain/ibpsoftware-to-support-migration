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
CONSOLE_NAME=$3
DOC_URL=$4

BASEDIR=$(cd "$(dirname "$0")/.."; pwd)
current_script=`basename "$0"`

# import logging functions
. ${BASEDIR}/common/logger.sh

. ${BASEDIR}/env.sh
${BASEDIR}/common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

debug "Checking console image tag."
ISVALIDCONSOLENAME=$(kubectl get deployment ${CONSOLE_NAME} -n $NAMESPACE --no-headers | awk '{print $1}' );
if [ -z "$ISVALIDCONSOLENAME" ]; then
    error "Please Set Your Console Name as environment variable"
    exit 1
fi

for image in $(kubectl get deployment ${CONSOLE_NAME} -n $NAMESPACE -o=jsonpath="{...image}"); do
    imageName=$(echo $image | awk -F"/" '{print $NF}' | awk -F":" '{print $1}')
    imageTag=$(echo $image | awk -F: '{print $NF}' | awk -F"-"  '{print $1"-"$2}')
    if [ $imageName = "ibp-console" ]; then
        CONSOLETAG=$imageTag
        ISVALIDVERSION=$(cat $BASEDIR/check-compatibility/compatible-versions/console.txt | grep $CONSOLETAG)

        if [ -z "$ISVALIDVERSION" ]; then
            error "console $CONSOLE_NAME is using image tag $CONSOLETAG, which is not compatible for migration"
            customer_action "Please upgrade your console to the latest version before migrating: $DOC_URL"
            exit 1
        fi
    fi
done

debug "Console image tag is compatible."