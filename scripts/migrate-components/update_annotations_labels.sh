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


debug "Applying new labels and annotations to all deployment specs."
# apply new labels and annotations to deployment spec
kubectl label --overwrite deploy -n $NAMESPACE --all app.kubernetes.io/managed-by=ibm-hlfsupport-operator
if [ "$?" != "0" ]; then
    error "error in adding label 'app.kubernetes.io/managed-by=ibm-hlfsupport-operator'"
    exit 1
fi

kubectl label --overwrite deploy -n $NAMESPACE --all app.kubernetes.io/name=ibm-hlfsupport
if [ "$?" != "0" ]; then
    error "error in adding label 'app.kubernetes.io/name=ibm-hlfsupport'"
    exit 1
fi
kubectl label --overwrite deploy -n $NAMESPACE --all creator=ibm-hlfsupport
if [ "$?" != "0" ]; then
    error "error in adding label 'creator=ibm-hlfsupport'"
    exit 1
fi

kubectl label --overwrite deploy -n $NAMESPACE --all helm.sh/chart=ibm-hlfsupport
if [ "$?" != "0" ]; then
    error "error in adding label 'helm.sh/chart=ibm-hlfsupport'"
    exit 1
fi

kubectl label --overwrite deploy -n $NAMESPACE --all release=operator
if [ "$?" != "0" ]; then
    error "error in adding label 'release=operator'"
    exit 1
fi

for crspec in ibpca ibppeer ibporderer
do
    comp_name=$(echo ${crspec} | sed 's/ibp//')
    for deployment in $(kubectl get ${crspec} -n $NAMESPACE --no-headers | awk '{print $1}')
    do
        if [[ $crspec == "ibporderer" ]]; then
            # check if this crspec is for parent orderer
            kubectl get deployment ${deployment} > /dev/null 2>&1 | grep -q node
            if [[ $? != 0 ]]; then
                continue;
            fi
        fi
        kubectl label --overwrite deploy ${deployment} -n $NAMESPACE app.kubernetes.io/instance=ibm-hlfsupport-${comp_name}
        if [ "$?" != "0" ]; then
            error "error in adding label 'app.kubernetes.io/instance=ibm-hlfsupport-${comp_name}' to deployment $deployment"
            exit 1
        fi
    done
done

# update annotations for all deployments
kubectl annotate --overwrite deploy -n $NAMESPACE --all productID="5d5997a033594f149a534a09802d60f1"
if [ "$?" != "0" ]; then
    error "error in adding annotation 'productID=\"5d5997a033594f149a534a09802d60f1\"'"
    exit 1
fi

kubectl annotate --overwrite deploy -n $NAMESPACE --all productName="IBM Support for Hyperledger Fabric"
if [ "$?" != "0" ]; then
    error "error in adding annotation 'productName=\"IBM Support for Hyperledger Fabric\"'"
    exit 1
fi

kubectl annotate --overwrite deploy -n $NAMESPACE --all productVersion="1.0.0"
if [ "$?" != "0" ]; then
    error "error in adding annotation 'productVersion=\"1.0.0\"'"
    exit 1
fi

debug "Successfully applied new labels and annotations to all deployment specs."
exit 0
