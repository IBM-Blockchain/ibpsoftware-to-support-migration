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

if [[ ! -z "${MISSING_ENV}" ]]; then
    echo -e "\n\n Please set all these missing ENV variables \n\n${MISSING_ENV}"
    exit 500
fi

if [[ "${CLUSTERTYPE}" == "OPENSHIFT" ]] || [[ "${CLUSTERTYPE}" == "K8S" ]]; then
   :
else
    echo "CLUSTERTYPE $CLUSTERTYPE not supported, should be OPENSHIFT or K8S";
    exit 501
fi