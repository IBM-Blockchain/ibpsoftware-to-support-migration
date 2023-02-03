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
FILE_PATH=$2

BASEDIR=$(cd "$(dirname "$0")/.."; pwd)
current_script=`basename "$0"`

. ${BASEDIR}/env.sh
${BASEDIR}/common/sanitize_env.sh
if [ "$?" != "0" ]; then
    exit 1
fi

# import logging functions
. ${BASEDIR}/common/logger.sh

debug "Generate versions with tags."
SUPPORTED_FABRIC_VERSION=$(cat ${BASEDIR}/check-compatibility/compatible-versions/peer.txt | grep $IMAGE_DATE)
TEMP_FABRIC_22X=$(echo $SUPPORTED_FABRIC_VERSION |awk -F" " '{print $1}')
TEMP_FABRIC_24x=$(echo $SUPPORTED_FABRIC_VERSION |awk -F" " '{print $2}')
FABRIC_22X=$(echo $TEMP_FABRIC_22X |awk -F"-" '{print $1}')
FABRIC_24x=$(echo $TEMP_FABRIC_24x |awk -F"-" '{print $1}')
cat << EOF > ${FILE_PATH}
{
    "ca": {
        "${FABRIC_CA_VERSION}-${FABRIC_CA_PATCH_VERSION}": {
            "default": true,
            "image": {
                "caImage": "ibm-hlfsupport-ca",
                "caInitImage": "ibm-hlfsupport-init",
                "caInitTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "caTag": "${FABRIC_CA_VERSION}-${IMAGE_DATE}",
                "enrollerImage": "ibm-hlfsupport-enroller",
                "enrollerTag": "${RELEASE_VERSION}-${IMAGE_DATE}"
            },
            "version": "${FABRIC_CA_VERSION}-${FABRIC_CA_PATCH_VERSION}"
        }
    },
    "orderer": {
        "${FABRIC_22X}-${FABRIC_PATCH_VERSION}": {
            "default": true,
            "image": {
                "enrollerImage": "ibm-hlfsupport-enroller",
                "enrollerTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "grpcwebImage": "ibm-hlfsupport-grpcweb",
                "grpcwebTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "ordererImage": "ibm-hlfsupport-orderer",
                "ordererInitImage": "ibm-hlfsupport-init",
                "ordererInitTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "ordererTag": "${FABRIC_22X}-${IMAGE_DATE}"
            },
            "version": "${FABRIC_22X}-${FABRIC_PATCH_VERSION}"
        },
        "${FABRIC_24x}-${FABRIC_PATCH_VERSION}": {
            "default": false,
            "image": {
                "enrollerImage": "ibm-hlfsupport-enroller",
                "enrollerTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "grpcwebImage": "ibm-hlfsupport-grpcweb",
                "grpcwebTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "ordererImage": "ibm-hlfsupport-orderer",
                "ordererInitImage": "ibm-hlfsupport-init",
                "ordererInitTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "ordererTag": "${FABRIC_24x}-${IMAGE_DATE}"
            },
            "version": "${FABRIC_24x}-${FABRIC_PATCH_VERSION}"
        }

    },
    "peer": {
        "${FABRIC_22X}-${FABRIC_PATCH_VERSION}": {
            "default": true,
            "image": {
                "builderImage": "ibm-hlfsupport-ccenv",
                "builderTag": "${FABRIC_22X}-${IMAGE_DATE}",
                "chaincodeLauncherImage": "ibm-hlfsupport-chaincode-launcher",
                "chaincodeLauncherTag": "${FABRIC_22X}-${IMAGE_DATE}",
                "couchdbImage": "ibm-hlfsupport-couchdb",
                "couchdbTag": "${COUCHDB_VERSION}-${IMAGE_DATE}",
                "dindImage": "ibm-hlfsupport-dind",
                "dindTag": "${FABRIC_22X}-${IMAGE_DATE}",
                "enrollerImage": "ibm-hlfsupport-enroller",
                "enrollerTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "goEnvImage": "ibm-hlfsupport-goenv",
                "goEnvTag": "${FABRIC_22X}-${IMAGE_DATE}",
                "grpcwebImage": "ibm-hlfsupport-grpcweb",
                "grpcwebTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "javaEnvImage": "ibm-hlfsupport-javaenv",
                "javaEnvTag": "${FABRIC_22X}-${IMAGE_DATE}",
                "nodeEnvImage": "ibm-hlfsupport-nodeenv",
                "nodeEnvTag": "${FABRIC_22X}-${IMAGE_DATE}",
                "peerImage": "ibm-hlfsupport-peer",
                "peerInitImage": "ibm-hlfsupport-init",
                "peerInitTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "peerTag": "${FABRIC_22X}-${IMAGE_DATE}"
            },
            "version": "${FABRIC_22X}-${FABRIC_PATCH_VERSION}"
        },
         "${FABRIC_24x}-${FABRIC_PATCH_VERSION}": {
            "default": false,
            "image": {
                "builderImage": "ibm-hlfsupport-ccenv",
                "builderTag": "${FABRIC_24x}-${IMAGE_DATE}",
                "chaincodeLauncherImage": "ibm-hlfsupport-chaincode-launcher",
                "chaincodeLauncherTag": "${FABRIC_24x}-${IMAGE_DATE}",
                "couchdbImage": "ibm-hlfsupport-couchdb",
                "couchdbTag": "${COUCHDB_VERSION}-${IMAGE_DATE}",
                "dindImage": "ibm-hlfsupport-dind",
                "dindTag": "${FABRIC_24x}-${IMAGE_DATE}",
                "enrollerImage": "ibm-hlfsupport-enroller",
                "enrollerTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "goEnvImage": "ibm-hlfsupport-goenv",
                "goEnvTag": "${FABRIC_24x}-${IMAGE_DATE}",
                "grpcwebImage": "ibm-hlfsupport-grpcweb",
                "grpcwebTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "javaEnvImage": "ibm-hlfsupport-javaenv",
                "javaEnvTag": "${FABRIC_24x}-${IMAGE_DATE}",
                "nodeEnvImage": "ibm-hlfsupport-nodeenv",
                "nodeEnvTag": "${FABRIC_24x}-${IMAGE_DATE}",
                "peerImage": "ibm-hlfsupport-peer",
                "peerInitImage": "ibm-hlfsupport-init",
                "peerInitTag": "${RELEASE_VERSION}-${IMAGE_DATE}",
                "peerTag": "${FABRIC_24x}-${IMAGE_DATE}"
            },
            "version": "${FABRIC_24x}-${FABRIC_PATCH_VERSION}"
        }

    }
}
EOF

debug "Successfully generated versions with tags."