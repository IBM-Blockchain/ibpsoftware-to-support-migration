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
WEBHOOK_NAMESPACE=$2

BASEDIR=$(cd "$(dirname "$0")/.."; pwd)
current_script=`basename "$0"`

. ${BASEDIR}/env.sh
${BASEDIR}/common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# import logging functions
. ${BASEDIR}/common/logger.sh

debug "Creating rbac for crd-webhook."

cat <<EOF | kubectl apply -n ${WEBHOOK_NAMESPACE} -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: webhook
  namespace: ${WEBHOOK_NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: webhook
rules:
- apiGroups:
  - "*"
  resources:
  - secrets
  verbs:
  - "*"
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${WEBHOOK_NAMESPACE}
subjects:
- kind: ServiceAccount
  name: webhook
  namespace: ${WEBHOOK_NAMESPACE}
roleRef:
  kind: Role
  name: webhook
  apiGroup: rbac.authorization.k8s.io
EOF

debug "Successfully created rbac for crd-webhook."