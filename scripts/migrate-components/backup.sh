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
BACKUP_DIRECTORY=$2
NAMESPACE=$3

BASEDIR=$(cd "$(dirname "$0")/.."; pwd)
current_script=`basename "$0"`

. ${BASEDIR}/env.sh
${BASEDIR}/common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# import logging functions
. ${BASEDIR}/common/logger.sh

## backup crds ## 

mkdir -p $BACKUP_DIRECTORY/crds

debug "Backing up Custom Resource Definition for ibpconsole."
kubectl get crds ibpconsoles.ibp.com -o yaml > $BACKUP_DIRECTORY/crds/ibpconsole.yaml

debug "Backing up Custom Resource Definition for ibpcas."
kubectl get crds ibpcas.ibp.com -o yaml > $BACKUP_DIRECTORY/crds/ibpca.yaml

debug "Backing up Custom Resource Definition for ibporderers."
kubectl get crds ibporderers.ibp.com -o yaml > $BACKUP_DIRECTORY/crds/ibporderer.yaml

debug "Backing up Custom Resource Definition for ibppeers."
kubectl get crds ibppeers.ibp.com -o yaml > $BACKUP_DIRECTORY/crds/ibppeer.yaml

debug "List backup directory for crds."
ls -al $BACKUP_DIRECTORY/crds

## end backup crds ## 

## backup cr specs ## 
CRSPEC_BACKUP_DIRECTORY="$BACKUP_DIRECTORY/crspecs"
mkdir -p $CRSPEC_BACKUP_DIRECTORY

debug "Backing up Custom Resource Specs for ibpconsole."
mkdir -p $CRSPEC_BACKUP_DIRECTORY/console
IBPCONSOLES=$(kubectl get ibpconsole -n $NAMESPACE --no-headers | awk '{print $1}')
for ibpconsole in $IBPCONSOLES; do
    kubectl get ibpconsole -n $NAMESPACE $ibpconsole -o yaml > $CRSPEC_BACKUP_DIRECTORY/console/$ibpconsole.yaml
done

debug "Backing up Custom Resource Specs for ibpcas."
mkdir -p $CRSPEC_BACKUP_DIRECTORY/ca
IBPCAS=$(kubectl get ibpca -n $NAMESPACE --no-headers | awk '{print $1}')
for ibpca in $IBPCAS; do
    kubectl get ibpca -n $NAMESPACE $ibpca -o yaml > $CRSPEC_BACKUP_DIRECTORY/ca/$ibpca.yaml
done

debug "Backing up Custom Resource Specs for ibppeers."
mkdir -p $CRSPEC_BACKUP_DIRECTORY/peer
IBPPEERS=$(kubectl get ibppeer -n $NAMESPACE --no-headers | awk '{print $1}')
for ibppeer in $IBPPEERS; do
    kubectl get ibppeer -n $NAMESPACE $ibppeer -o yaml > $CRSPEC_BACKUP_DIRECTORY/peer/$ibppeer.yaml
done

debug "Backing up Custom Resource Specs for ibporderers."
mkdir -p $CRSPEC_BACKUP_DIRECTORY/orderer
IBPORDERERS=$(kubectl get ibporderer -n $NAMESPACE --no-headers | awk '{print $1}')
for ibporderer in $IBPORDERERS; do
    kubectl get ibporderer -n $NAMESPACE $ibporderer -o yaml > $CRSPEC_BACKUP_DIRECTORY/orderer/$ibporderer.yaml
done

debug "List backup directory for crspecs."
ls -alR $CRSPEC_BACKUP_DIRECTORY

## end backup cr specs ## 

## backup deployment specs ##
mkdir -p $BACKUP_DIRECTORY/deployments

debug "Backing up deployment specs."
DEPLOYMENTS=$(kubectl get deployment -n $NAMESPACE --no-headers | awk '{print $1}')
for deployment in $DEPLOYMENTS; do
    kubectl get deployment ${deployment} -n $NAMESPACE -o yaml > $BACKUP_DIRECTORY/deployments/$deployment.yaml
done

debug "List backup directory for deployment specs."
ls -al $BACKUP_DIRECTORY/deployments

## end backup deployment specs ##

## backup pods specs ##
mkdir -p $BACKUP_DIRECTORY/pods

debug "Backing up pods specs."
PODS=$(kubectl get pods -n $NAMESPACE --no-headers | grep -v "chaincode-execution" | awk '{print $1}')
for pod_name in $PODS; do
    kubectl get pods ${pod_name} -n $NAMESPACE -o yaml > $BACKUP_DIRECTORY/pods/$pod_name.yaml
done

debug "List backup directory for pods specs."
ls -al $BACKUP_DIRECTORY/pods

# current status of the pods
kubectl get po --no-headers | grep -v "chaincode-execution" | awk '{ print "Pod " $1 " status is " $3 }' >$BACKUP_DIRECTORY/pods/pods-status.txt
cat $BACKUP_DIRECTORY/pods/pods-status.txt

## end backup pods specs ##
# TODO any other backup goes here

debug "Backup completed."