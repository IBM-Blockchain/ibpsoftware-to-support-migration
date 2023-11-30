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
OPERATOR_NAME=$3
DOC_URL=$4

BASEDIR=$(cd "$(dirname "$0")/.."; pwd)
current_script=`basename "$0"`
MIN_OPERATOR_VERSION=2.5.3-20221207
. ${BASEDIR}/env.sh
${BASEDIR}/common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# import logging functions
source ${BASEDIR}/common/logger.sh


OPERATORTAG=$(kubectl get deployment -n $NAMESPACE ${OPERATOR_NAME} -o=jsonpath="{...image}"  | awk -F: '{print $NF}' | awk -F"-"  '{print $1"-"$2}' )
## In case of re-run the script after successful migration.
debug "Checking Support Offering already installed or not."
IS_SUPPORT_OFFERING=$(kubectl get deployments -n $NAMESPACE | grep ibm-hlfsupport-operator)
if [ ! -z "$IS_SUPPORT_OFFERING" ]; then
  error "Customer is already in IBM Support Offering. Please contact the support team in case of any issues."
  exit 1
fi

debug "Checking operator image tag."
ISVALIDVERSION=$(cat $BASEDIR/check-compatibility/compatible-versions/operator.txt | grep $OPERATORTAG)
if [ -z "$ISVALIDVERSION" ]; then
    error "Operator $OPERATOR_NAME is using image tag '$OPERATORTAG', which is not compatible for migration. Minimum Supported Version '$MIN_OPERATOR_VERSION'"
    customer_action "Please upgrade your network to the latest version before migrating: $DOC_URL"
    exit 1
fi
## IBP Version -X to Support Version X.
## TODO Need support for X -> X + 1
IMAGERELEASEDATET=$(echo $ISVALIDVERSION | awk -F"-" '{print $2}')
ISVALIDATE=$(cat $BASEDIR/env.sh | grep $IMAGERELEASEDATET)

if ! [[ $IMAGE_DATE =~ $IMAGERELEASEDATET ]]; then
    error "Please upgrade your IBP Components"
    exit 1
fi

debug "Operator image tag is compatible."