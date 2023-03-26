# software-to-support-migration

**Attention: Due to functional overlap, all customers currently running an IBM Blockchain Platform (IBP) software installation must migrate their networks to IBM Support for Hyperledger Fabric by April 30, 2023. Use this README document to set up and complete this migration.**

IBM Support for Hyperledger Fabric provides certified images of Hyperledger Fabric open source code, accelerators, and IBM support. This README document describes how to complete the migration, which will have **no impact on your existing data or blockchain network functionality**. General migration notices are available at https://www.ibm.com/docs/en/blockchain-platform/2.5.3?topic=how-migrating-support-hyperledger-fabric and https://www.ibm.com/docs/en/blockchain-platform/2.5.4?topic=how-migrating-support-hyperledger-fabric.

## Prerequisites

The following prerequisites are required for the migration:

- IBP S/W 2.5.3-20221207 or above.
- Fabric Version 2.2.9 or above.
- Fabric CA Version 1.5.5 or above.

**Attention: If your network does not meet all of the prerequisites above, you must upgrade your network before proceeding with the migration.**

### Required tools

The following tools are required to run the migration scripts:

- oc (openshift commandline)
- kubectl
- jq
- yq ( >= 4.30.x )
- docker

### Configure `kubectl` or `oc` context

Make sure you are pointing to the correct cluster where your network resides before running the scripts: 

- You must clone this repo on the machine or VM where you will execute the migration scripts.

- The local machine or VM must have privilege to access the cluster where your IBP instance is hosted.

### Compatible images

Your IBM Blockchain Software 2.5.3 OR 2.5.4 components must be using compatible images in order to migrate to IBM Support for Hyperledger Fabric. The tables below show compatible image tags for each component.

**Attention:** The migration scripts are not compatible with any non-standard deployment - [open a support ticket](https://www.ibm.com/mysupport) for help with a non-standard migration.

#### IBP Operator

|Release Date|Tag|
|---|---|
|2022 Dec 07|2.5.3-20221207|
|2023 Jan 04|2.5.3-20230104|
|2023 Jan 31|2.5.3-20230131|
|2023 Feb 28|2.5.3-20230228|
|2023 Mar 22|2.5.4-20230322|


#### IBP Console

|Release Date|Tag|
|---|---|
|2022 Dec 07|2.5.3-20221207|
|2023 Jan 04|2.5.3-20230104|
|2023 Jan 31|2.5.3-20230131|
|2023 Feb 28|2.5.3-20230228|
|2023 Mar 22|2.5.4-20230322|

#### IBP CA

|Release Date|Tag|
|---|---|
|2022 Dec 07|1.5.5-20221207|
|2023 Jan 04|1.5.5-20230104|
|2023 Jan 31|1.5.5-20230131|
|2023 Feb 28|1.5.5-20230228|
|2023 Mar 22|1.5.5-20230322|

#### IBP Orderer

|Release Date|Tag|
|---|---|
|2022 Dec 07|2.2.9-20221207|
|2022 Dec 07|2.4.7-20221207|
|2023 Jan 04|2.2.9-20230104|
|2023 Jan 04|2.4.7-20230104|
|2023 Jan 31|2.2.9-20230131|
|2023 Jan 31|2.4.7-20230131|
|2023 Feb 28|2.2.10-20230228|
|2023 Feb 28|2.4.8-20230228|
|2023 Mar 22|2.2.10-20230322|
|2023 Mar 22|2.4.8-20230322|

#### IBP Peer

|Release Date|Tag|
|---|---|
|2022 Dec 07|2.2.9-20221207|
|2022 Dec 07|2.4.7-20221207|
|2023 Jan 04|2.2.9-20230104|
|2023 Jan 04|2.4.7-20230104|
|2023 Jan 31|2.2.9-20230131|
|2023 Jan 31|2.4.7-20230131|
|2023 Mar 22|2.2.10-20230322|
|2023 Mar 22|2.4.8-20230322|


## Export environment variables

Export the following environment variables:

* **REGISTRY_URL** : Provide the entitled registry to be used (if not set, will use default value 'icr.io/cpopen')

    *example:* `export REGISTRY_URL=icr.io/cpopen`

* **NAMESPACE**: Namespace where the operator/console and Fabric components are deployed

   - Select the NameSpace where the IBP components are hosted:

        `kubectl get ns`

  - Set the namespace as an environment variable as in the following example: 

    *example:* `export NAMESPACE=fabric-blockchain-network`

* **OPERATOR_NAME**: Name of your IBP operator (if not set, will use default value `ibp-operator`)

    - Select the IBP operator name:

        `kubectl get deploy -n <namespace>`

    - Set the operator name as an environment variable as in the following example: 

    *example:* `export OPERATOR_NAME=my-operator-name`

* **CONSOLE_NAME**: Name of your IBP console (if not set, will use default value `ibp-console`)

  - Select the IBP Console name: 

        `kubectl get deploy -n <namespace>`

 - Set the console name as an environment variable as in the following example: 

     *example:* `export CONSOLE_NAME=my-console-name`

* **CRDWEBHOOK_NAMESPACE**: Namespace where your CRD conversion webhook is deployed (if not set, will use default value `ibpinfra`)

    - Select the namespace where your CRD conversion webhookis deployed: 

        `kubectl get ns`

    - Set the namespace as an environment variable as in the following example: 

     *example:* `export CRDWEBHOOK_NAMESPACE=ibpinfra`

* **HEALTHCHECK_TIMEOUT**: Length of time to wait for a deployment to come up when verifying migration (if not set, will use default value `600s`). Unit of time should be included.

     *example:* `export HEALTHCHECK_TIMEOUT=600s`

## Check compatibility only

To verify that your network is compatible for migration, invoke the **scripts/check-compatibility/check.sh** script:

**Usage:** `./scripts/check-compatibility/check.sh`
**Parameters:** none

## Usage

Migrate your IBM Blockchain Software 2.5.3 and 2.5.4 components to IBM Support for Hyperledger Fabric by invoking the **scripts/sw-to-support.sh** script:

**Usage:** `./scripts/sw-to-support.sh`
**Parameters:** none

## Related documentation

If necessary, use the following documentation to prepare your network for migration:

* For the latest IBM Blockchain Platform (IBP) 2.5.3 releases and fixpacks, click [here](https://www.ibm.com/docs/en/blockchain-platform/2.5.3?topic=help-release-notes).
* For the latest IBM Blockchain Platform (IBP) 2.5.4 releases and fixpacks, click [here](https://www.ibm.com/docs/en/blockchain-platform/2.5.4?topic=help-release-notes).
* For instructions on how to upgrade your IBP version 2.5.3 network to the latest fixpack, click [here](https://www.ibm.com/docs/en/blockchain-platform/2.5.3?topic=kubernetes-installing-253-fix-pack).
* For instructions on how to upgrade your IBP version 2.5.4 network to the latest fixpack, click [here](https://www.ibm.com/docs/en/blockchain-platform/2.5.4?topic=kubernetes-installing-254-fix-pack).
* For instructions on how to migrate your IBP instance from an older version to 2.5.3:
  * For Openshift clusters, click [here](https://www.ibm.com/docs/en/blockchain-platform/2.5.3?topic=platform-upgrading-your-deployment)
  * For Kubernetes clusters, click [here](https://www.ibm.com/docs/en/blockchain-platform/2.5.3?topic=kubernetes-upgrading-your-console-components)

* For instructions on how to migrate your IBP instance from an older version to 2.5.4:
  * For Openshift clusters, click [here](https://www.ibm.com/docs/en/blockchain-platform/2.5.4?topic=platform-upgrading-your-deployment)
  * For Kubernetes clusters, click [here](https://www.ibm.com/docs/en/blockchain-platform/2.5.4?topic=kubernetes-upgrading-your-console-components)

#### Version of migration scripts = 1.0.2
