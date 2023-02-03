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
WEBHOOK_NAMESPACE=ibm-hlfsupport-infra
BASEDIR=$(cd "$(dirname "$0")"; pwd)
current_script=`basename "$0"`

DEPLOY_TIMEOUT=${HEALTHCHECK_TIMEOUT:-"600s"}

. ${BASEDIR}/../env.sh
${BASEDIR}/../common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# import logging functions
. ${BASEDIR}/../common/logger.sh

debug "Creating webhook in namespace '$WEBHOOK_NAMESPACE'."

## create new WEBHOOK_NAMESPACE if not present already
kubectl get ns ${WEBHOOK_NAMESPACE} > /dev/null 2>&1
if [[ $? != 0 ]]; then
  debug "Creating namespace '$WEBHOOK_NAMESPACE'."
  kubectl create namespace ${WEBHOOK_NAMESPACE}
fi

## creating SCC
if [[ "$CLUSTERTYPE" == "OPENSHIFT" ]]; then
  ${BASEDIR}/create_update_scc.sh $current_script $WEBHOOK_NAMESPACE
fi

## creating rbac for webhook
${BASEDIR}/create_webhook_rbac.sh $current_script $WEBHOOK_NAMESPACE

debug "Creating new webhook deployment."
kubectl get deploy -n ${WEBHOOK_NAMESPACE} ibm-hlfsupport-webhook > /dev/null 2>&1
if [[ $? == 0 ]]; then
  kubectl delete deploy -n ${WEBHOOK_NAMESPACE} ibm-hlfsupport-webhook
  sleep 10
fi


cat <<EOF | kubectl apply -n ${WEBHOOK_NAMESPACE} -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "ibm-hlfsupport-webhook"
  labels:
    helm.sh/chart: "ibm-hlfsupport"
    app.kubernetes.io/name: "ibm-hlfsupport"
    app.kubernetes.io/instance: "ibm-hlfsupport-webhook"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/instance: "ibm-hlfsupport-webhook"
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        helm.sh/chart: "ibm-hlfsupport"
        app.kubernetes.io/name: "ibm-hlfsupport"
        app.kubernetes.io/instance: "ibm-hlfsupport-webhook"
      annotations:
        productName: "IBM Support for Hyperledger Fabric"
        productID: "5d5997a033594f149a534a09802d60f1"
        productVersion: "1.0.0"
        productChargedContainers: ""
        productMetric: "VIRTUAL_PROCESSOR_CORE"
    spec:
      serviceAccountName: webhook
      hostIPC: false
      hostNetwork: false
      hostPID: false
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
        - name: "ibm-hlfsupport-webhook"
          image: ${REGISTRY_URL}/ibm-hlfsupport-crdwebhook:${RELEASE_VERSION}-${IMAGE_DATE}-${ARCH}
          imagePullPolicy: Always
          securityContext:
            privileged: false
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            runAsUser: 1000
            capabilities:
              drop:
              - ALL
              add:
              - NET_BIND_SERVICE
          env:
            - name: "LICENSE"
              value: "accept"
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - name: server
              containerPort: 3000
          livenessProbe:
            httpGet:
              path: /healthz
              port: server
              scheme: HTTPS
            initialDelaySeconds: 30
            timeoutSeconds: 5
            failureThreshold: 6
          readinessProbe:
            httpGet:
              path: /healthz
              port: server
              scheme: HTTPS
            initialDelaySeconds: 26
            timeoutSeconds: 5
            periodSeconds: 5
          resources:
            requests:
              cpu: 0.1
              memory: "100Mi"
EOF

debug "Checking webhook deployment status."
## check deployment status
retry=5 # Number of times to retry and wait time period between tries for webhook deployment to be ready
while ! kubectl rollout status -w "deployment/ibm-hlfsupport-webhook" --namespace=${WEBHOOK_NAMESPACE} --timeout=${DEPLOY_TIMEOUT}; do
    sleep 10
    retries=$((retries - 1))
    if [[ $retries == 0 ]]; then
        error "FAIL: webhook deployment failed to comeup !!"
        exit 1
    fi
done
debug "Successfully deployed webhook in namespace '${WEBHOOK_NAMESPACE}'."

debug "Creating service for webhook."

cat <<EOF | kubectl apply -n ${WEBHOOK_NAMESPACE} -f -
apiVersion: v1
kind: Service
metadata:
  name: "ibm-hlfsupport-webhook"
  labels:
    type: "webhook"
    app.kubernetes.io/name: "ibm-hlfsupport"
    app.kubernetes.io/instance: "ibm-hlfsupport-webhook"
    helm.sh/chart: "ibm-hlfsupport"
spec:
  type: ClusterIP
  ports:
    - name: server
      port: 443
      targetPort: server
      protocol: TCP
  selector:
    app.kubernetes.io/instance: "ibm-hlfsupport-webhook"
EOF

debug "Successfully created service for webhook."

debug "Successfully created webhook."