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

DEPLOY_TIMEOUT=${HEALTHCHECK_TIMEOUT:-"600s"}

retries=3
debug "Verifying all deployments."
for deployment in $(kubectl -n $NAMESPACE get deploy --no-headers | grep -v ${OPERATOR_NAME} | awk '{print $1}')
do
    while ! kubectl rollout status -w "deployment/${deployment}" --namespace=${NAMESPACE} --timeout=${DEPLOY_TIMEOUT}; do
        sleep 10
        retries=$((retries - 1))
        if [[ $retries == 0 ]]; then
            error "FAIL: timed out waiting for ${deployment} deployment to come up !!"
            customer_action "Please re-run the verification script: ./${BASEDIR}/verify-migration/verify.sh"
            exit 1
        fi
    done
done
debug "Successfully verified all deployments."