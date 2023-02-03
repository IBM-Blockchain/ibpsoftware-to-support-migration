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

function debug() {
    message=$1
    if [ -z $LOGGING_COMPONENT ]; then
        echo -e "$current_script :: [DEBUG] $message"
    else
        echo -e "$LOGGING_COMPONENT :: $current_script :: [DEBUG] $message"
    fi
}

function customer_action() {
    message=$1
    if [ -z $LOGGING_COMPONENT ]; then
        echo -e "$current_script :: [CUSTOMER ACTION] $message"
    else
        echo -e "$LOGGING_COMPONENT :: $current_script :: [CUSTOMER ACTION] $message"
    fi
}

function error() {
    message=$1
    if [ -z $LOGGING_COMPONENT ]; then
        echo -e "$current_script :: [ERROR] $message"
    else
        echo -e "$LOGGING_COMPONENT :: $current_script :: [ERROR] $message"
    fi
}