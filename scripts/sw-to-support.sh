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

## pre-req:
BASEDIR=$(cd "$(dirname "$0")"; pwd)
current_script=`basename "$0"`

. ${BASEDIR}/env.sh
${BASEDIR}/common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# verify cluster version
${BASEDIR}/common/check_cluster_version.sh ${current_script} ${NAMESPACE}
if [ "$?" != "0" ]; then
	echo "$current_script :: error in cluster version verification"
    exit 600
fi

# verify jq is installed
${BASEDIR}/common/check_jq.sh
if [ "$?" != "0" ]; then
	echo "$current_script :: jq not installed, please see readme for required tools"
    exit 601
fi

# stage 1 check compatibility for migration
${BASEDIR}/check-compatibility/check.sh
code=$?
if [ "$code" != "0" ]; then
	echo "$current_script :: error in checking compatibility for migration"
    exit $code
fi

# stage 2 migrate components
${BASEDIR}/migrate-components/migrate.sh
code=$?
if [ "$code" != "0" ]; then
	echo "$current_script :: error in migrating components"
    exit $code
fi

# stage 3 verify
${BASEDIR}/verify-migration/verify.sh
code=$?
if [ "$code" != "0" ]; then
	echo "$current_script :: error in verifying migration"
    exit $code
fi
