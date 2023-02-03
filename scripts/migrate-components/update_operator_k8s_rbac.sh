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

debug "Updating rbac."

cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ${NAMESPACE}
  labels:
    release: "operator"
    helm.sh/chart: "ibm-hlfsupport"
    app.kubernetes.io/name: "ibm-hlfsupport"
    app.kubernetes.io/instance: "ibm-hlfsupport"
    app.kubernetes.io/managed-by: "ibm-hlfsupport-operator"
rules:
- apiGroups:
  - extensions
  resourceNames:
  - ibm-hlfsupport-psp
  resources:
  - podsecuritypolicies
  verbs:
  - use
- apiGroups:
  - apiextensions.k8s.io
  resources:
  - persistentvolumeclaims
  - persistentvolumes
  verbs:
  - get
  - list
  - create
  - update
  - patch
  - watch
  - delete
  - deletecollection
- apiGroups:
  - apiextensions.k8s.io
  resources:
  - customresourcedefinitions
  verbs:
  - get
- apiGroups:
  - route.openshift.io
  resources:
  - routes
  - routes/custom-host
  verbs:
  - get
  - list
  - create
  - update
  - patch
  - watch
  - delete
  - deletecollection
- apiGroups:
  - ""
  resources:
  - pods
  - pods/log
  - persistentvolumeclaims
  - persistentvolumes
  - services
  - endpoints
  - events
  - configmaps
  - secrets
  - nodes
  - serviceaccounts
  verbs:
  - get
  - list
  - create
  - update
  - patch
  - watch
  - delete
  - deletecollection
- apiGroups:
  - "batch"
  resources:
  - jobs
  verbs:
  - get
  - list
  - create
  - update
  - patch
  - watch
  - delete
  - deletecollection
- apiGroups:
  - "authorization.openshift.io"
  - "rbac.authorization.k8s.io"
  resources:
  - roles
  - rolebindings
  verbs:
  - get
  - list
  - create
  - update
  - patch
  - watch
  - delete
  - deletecollection
  - bind
  - escalate
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - get
- apiGroups:
  - apps
  resources:
  - deployments
  - daemonsets
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - create
  - update
  - patch
  - watch
  - delete
  - deletecollection
- apiGroups:
  - monitoring.coreos.com
  resources:
  - servicemonitors
  verbs:
  - get
  - create
- apiGroups:
  - apps
  resourceNames:
  - ibm-hlfsupport-operator
  resources:
  - deployments/finalizers
  verbs:
  - update
- apiGroups:
  - ibp.com
  resources:
  - ibpcas.ibp.com
  - ibppeers.ibp.com
  - ibporderers.ibp.com
  - ibpconsoles.ibp.com
  - ibpcas
  - ibppeers
  - ibporderers
  - ibpconsoles
  - ibpcas/finalizers
  - ibppeers/finalizers
  - ibporderers/finalizers
  - ibpconsoles/finalizers
  - ibpcas/status
  - ibppeers/status
  - ibporderers/status
  - ibpconsoles/status
  verbs:
  - get
  - list
  - create
  - update
  - patch
  - watch
  - delete
  - deletecollection
- apiGroups:
  - extensions
  - networking.k8s.io
  - config.openshift.io
  resources:
  - ingresses
  - networkpolicies
  verbs:
  - get
  - list
  - create
  - update
  - patch
  - watch
  - delete
  - deletecollection
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${NAMESPACE}
  labels:
    release: "operator"
    helm.sh/chart: "ibm-hlfsupport"
    app.kubernetes.io/name: "ibm-hlfsupport"
    app.kubernetes.io/instance: "ibm-hlfsupport"
    app.kubernetes.io/managed-by: "ibm-hlfsupport-operator"
subjects:
- kind: ServiceAccount
  name: default
  namespace: ${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: ${NAMESPACE}
  apiGroup: rbac.authorization.k8s.io
EOF

debug "Successfully updated rbac."