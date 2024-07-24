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

BASEDIR=$(cd "$(dirname "$0")"; pwd)
current_script=`basename "$0"`

. ${BASEDIR}/../env.sh
${BASEDIR}/../common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

OPERATORTAG=$(kubectl get deployment -n $NAMESPACE ${OPERATOR_NAME} -o=jsonpath="{...image}" | awk -F: '{print $NF}' | awk -F"-"  '{print $1"-"$2}' )
ISVALIDVERSION=$(cat $BASEDIR/compatible-versions/operator.txt | grep $OPERATORTAG)
DOC_URL="https://www.ibm.com/docs/en/blockchain-platform/2.5.3?topic=kubernetes-upgrading-your-console-components"
if [[ ! -z "$ISVALIDVERSION" ]]; then
   DOC_URL="https://www.ibm.com/docs/en/blockchain-platform/2.5.3?topic=kubernetes-installing-253-fix-pack"
fi


# import logging functions
. ${BASEDIR}/../common/logger.sh

debug "Checking compatibility for migration."

# verify jq is installed
${BASEDIR}/../common/check_jq.sh
if [ "$?" != "0" ]; then
	echo "$current_script :: jq not installed, please see readme for required tools"
    exit 601
fi

# Verify ibp-operator tag/digest >= 2.5.3-May release
${BASEDIR}/check-operator.sh "check.sh" $NAMESPACE $OPERATOR_NAME $DOC_URL
if [ "$?" != "0" ]; then
        error "error in check-operator script"
        exit 101
fi

# Verify ibp-console versions, tag/digest >= 2.5.3-May release
${BASEDIR}/check-console.sh "check.sh" $NAMESPACE $CONSOLE_NAME $DOC_URL
if [ "$?" != "0" ]; then
	error "error in check-console script"
    exit 102
fi

# Verify fabric versions, spec.versions to be 2.2.5 or higher for peer/orderer
# Verify fabric-ca versions, spec.versions to be 1.5.3 or higher for ca
${BASEDIR}/check-fabric-versions.sh "check.sh" $NAMESPACE $DOC_URL
if [ "$?" != "0" ]; then
	error "error in check-fabric-versions script"
    exit 103
fi

debug "Successfully checked for compatibility - network is compatible for migration"
exit 0
