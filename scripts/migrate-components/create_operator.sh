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


debug "Creating hlfsupport-based operator with 0 replicas."

cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ibm-hlfsupport-operator
  labels:
    release: "operator"
    helm.sh/chart: "ibm-hlfsupport"
    app.kubernetes.io/name: "ibm-hlfsupport"
    app.kubernetes.io/instance: "ibm-hlfsupport"
    app.kubernetes.io/managed-by: "ibm-hlfsupport-operator"
spec:
  replicas: 0
  strategy:
    type: "Recreate"
  selector:
    matchLabels:
      name: ibm-hlfsupport-operator
  template:
    metadata:
      labels:
        name: ibm-hlfsupport-operator
        release: "operator"
        helm.sh/chart: "ibm-hlfsupport"
        app.kubernetes.io/name: "ibm-hlfsupport"
        app.kubernetes.io/instance: "ibm-hlfsupport"
        app.kubernetes.io/managed-by: "ibm-hlfsupport-operator"  
      annotations:
        productName: "IBM Support for Hyperledger Fabric"
        productID: "5d5997a033594f149a534a09802d60f1"
        productVersion: "1.0.0"
        productChargedContainers: ""
        productMetric: "VIRTUAL_PROCESSOR_CORE"
    spec:
      hostIPC: false
      hostNetwork: false
      hostPID: false
      serviceAccountName: default
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values:
                - ${ARCH}
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 2000
      containers:
        - name: ibm-hlfsupport-operator
          image: ${REGISTRY_URL}/ibm-hlfsupport-operator:${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}
          command:
          - ibp-operator
          imagePullPolicy: Always
          securityContext:
            privileged: false
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: false
            runAsNonRoot: false
            runAsUser: 1001
            capabilities:
              drop:
              - ALL
              add:
              - CHOWN
              - FOWNER
          livenessProbe:
            tcpSocket:
              port: 8383
            initialDelaySeconds: 10
            timeoutSeconds: 5
            failureThreshold: 5
          readinessProbe:
            tcpSocket:
              port: 8383
            initialDelaySeconds: 10
            timeoutSeconds: 5
            periodSeconds: 5
          env:
            - name: WATCH_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: OPERATOR_NAME
              value: "ibm-hlfsupport-operator"
            - name: CLUSTERTYPE
              value: ${CLUSTERTYPE}
          resources:
            requests:
              cpu: 100m
              memory: 200Mi
            limits:
              cpu: 100m
              memory: 200Mi
EOF

debug "Successfully created hlfsupport-based operator with 0 replicas."