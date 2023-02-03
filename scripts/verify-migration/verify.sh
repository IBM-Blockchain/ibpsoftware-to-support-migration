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

MISSING_ENV=""

BASEDIR=$(cd "$(dirname "$0")"; pwd)
current_script=`basename "$0"`

. ${BASEDIR}/../env.sh
${BASEDIR}/../common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# import logging functions
. ${BASEDIR}/../common/logger.sh

debug "Verifying migration."

sleep 30

# verify if all components are running after migration
${BASEDIR}/verify_deployments.sh ${current_script} ${NAMESPACE}
if [ "$?" != "0" ]; then
	error "deployment verification failed"
    customer_action "Please contact support for assistance in troubleshooting the failed verification process. Keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 301
fi

# verify console
${BASEDIR}/verify_console.sh ${current_script} ${NAMESPACE} ${CONSOLE_NAME}
if [ "$?" != "0" ]; then
	error "error in console verification"
    customer_action "Please contact support for assistance in troubleshooting the failed verification process. Keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 302
fi

# verify peer
${BASEDIR}/verify_peer.sh ${current_script} ${NAMESPACE}
if [ "$?" != "0" ]; then
	error "error in peer verification"
    customer_action "Please contact support for assistance in troubleshooting the failed verification process. Keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 303
fi

# verify ca
${BASEDIR}/verify_ca.sh ${current_script} ${NAMESPACE}
if [ "$?" != "0" ]; then
	echo "$current_script :: error in ca verification"
    customer_action "Please contact support for assistance in troubleshooting the failed verification process. Keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 304
fi

# verify orderer
${BASEDIR}/verify_orderer.sh ${current_script} ${NAMESPACE}
if [ "$?" != "0" ]; then
	error "error in orderer verification"
    customer_action "Please contact support for assistance in troubleshooting the failed verification process. Keep the contents of the $BASEDIR/backups directory. Do NOT delete the $BASEDIR/backups directory."
    exit 305
fi

debug "Successfully verified migration."
exit 0
