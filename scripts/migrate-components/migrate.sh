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
LOGGING_COMPONENT=""
BASEDIR=$(cd "$(dirname "$0")"; pwd)
current_script=`basename "$0"`

. ${BASEDIR}/../env.sh
${BASEDIR}/../common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# import logging functions
. ${BASEDIR}/../common/logger.sh

debug "Starting migration."

# backup data before running migration steps
${BASEDIR}/backup.sh $current_script "backups" $NAMESPACE
if [ "$?" != "0" ]; then
    error "error in backup script"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 201
fi

debug "Scaling down IBP operator to 0 replicas."
## Scaling down operator
kubectl -n ${NAMESPACE} scale --replicas=0 deploy ${OPERATOR_NAME}
if [ "$?" != "0" ]; then
    error "error in scaling down IBP operator"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 202
fi

debug "Scaling down IBP webhook to 0 replicas."
## Scaling down webhook
kubectl -n ${CRDWEBHOOK_NAMESPACE} scale --replicas=0 deploy ibp-webhook
if [ "$?" != "0" ]; then
    error "error in scaling down IBP webhook"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 203
fi

## Updating SCC
if [[ "$CLUSTERTYPE" == "OPENSHIFT" ]]; then
    ${BASEDIR}/create_update_scc.sh $current_script $NAMESPACE
    if [ "$?" != "0" ]; then
        error "error in updating scc"
        customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
        exit 221
    fi
fi

# create new webhook deployment with new images and imagepullsecret
${BASEDIR}/create_webhook.sh $current_script
if [ "$?" != "0" ]; then
    error "error in bringing up crd-webhook"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 231
fi

# update/convert crds to v1 spec (vs v1beta1)
${BASEDIR}/convert_crds_to_v1.sh $current_script
if [ "$?" != "0" ]; then
    error "error in converting crds to v1"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 241
fi

## Updating Clusterrole based on clustertype ( ocp vs k8s )
if [[ "${CLUSTERTYPE}" == "OPENSHIFT" ]]; then
    ${BASEDIR}/update_operator_ocp_rbac.sh $current_script $NAMESPACE
    if [ "$?" != "0" ]; then
        error "error in updating rbac"
        customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
        exit 242
    fi
else
    ${BASEDIR}/update_operator_k8s_rbac.sh $current_script $NAMESPACE
    if [ "$?" != "0" ]; then
        error "error in updating rbac"
        customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
        exit 242
    fi
fi

# create ibm-hlfsupport operator with 0 replicas
${BASEDIR}/create_operator.sh $current_script $NAMESPACE
if [ "$?" != "0" ]; then
    error "error in creating ibm-hlfsupport operator"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 251
fi

${BASEDIR}/migrate_console.sh $current_script $NAMESPACE $CONSOLE_NAME
if [ "$?" != "0" ]; then
    error "error in console migration"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 261
fi

${BASEDIR}/migrate_ca.sh $current_script $NAMESPACE
if [ "$?" != "0" ]; then
    error "error in ca migration"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 262
fi

${BASEDIR}/migrate_orderer.sh $current_script $NAMESPACE
if [ "$?" != "0" ]; then
    error "error in orderer migration"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 263
fi

${BASEDIR}/migrate_peer.sh $current_script $NAMESPACE
if [ "$?" != "0" ]; then
    error "error in peer migration"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 264
fi

${BASEDIR}/update_annotations_labels.sh $current_script $NAMESPACE
if [ "$?" != "0" ]; then
    error "error on updating annotation labels"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 271
fi

debug "Scaling new ibm-hlfsupport operator up to 1 replica."
# bring up the operator
kubectl -n ${NAMESPACE} scale deploy/ibm-hlfsupport-operator --replicas=1
if [ "$?" != "0" ]; then
    error "error on scaling up new ibm-hlfsupport operator"
    customer_action "Please contact support for assistance in migrating your network and keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 281
fi

debug "Migration completed."
exit 0
