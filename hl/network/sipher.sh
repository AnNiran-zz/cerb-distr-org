#htoi !/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script will orchestrate a sample end-to-end execution of the Hyperledger
# Fabric network.
#
# The end-to-end verification provisions a sample Fabric network consisting of
# two organizations, each maintaining two peers, and a “solo” ordering service.
#
# This verification makes use of two fundamental tools, which are necessary to
# create a functioning transactional network with digital signature validation
# and access control:
#
# * cryptogen - generates the x509 certificates used to identify and
#   authenticate the various components in the network.
# * configtxgen - generates the requisite configuration artifacts for orderer
#   bootstrap and channel creation.
#
# Each tool consumes a configuration yaml file, within which we specify the topology
# of our network (cryptogen) and the location of our certificates for various
# configuration operations (configtxgen).  Once the tools have been successfully run,
# we are able to launch our network.  More detail on the tools and the structure of
# the network will be provided later in this document.  For now, let's get going...

# prepending $PWD/../bin to PATH to ensure we are picking up the correct binaries
# this may be commented out to resolve installed version of tools if desired
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false

. scripts/connectionSteps.sh
. scripts/addNetworkData.sh
. scripts/removeNetworkData.sh
. scripts/connectToNetwork.sh


# Print the usage message
function printHelp() {
	echo
	echo "### Commands: ###"
	echo
	echo "sipher.sh <action>"
	echo "	configure-connection"
	echo "		Displays all the steps for obtaining network data, adding extra hosts, generating required certificates and genesis block and connecting organization"
	echo "		to running network"
	echo
	echo
	echo "	help"
	echo "		Displays this message"
	echo
	echo "	generate"
	echo "		Generates required certificates and organization channel artifacts"
	echo
	echo "	add-env"
	echo "		Adds environment data to Sipher configuration"
	echo "		To add Cerberus network organization and Ordering Service instances data to environment configuration:"
	echo "		-e cerb"
	echo "		To add all external (to Sipher) organizations data to environment configuration:"
	echo "		-e ext"
	echo "		To add Cerberus network organization, Ordering Service instances and all external (to Sipher) organizations to environment configuration:"
	echo "		-e network"
	echo "		To add a single external (to Sipher) organization data to environment configuration:"
	echo "		-e <organization-name>"
	echo
	echo "	remove-env"
	echo "		Removes environment data from Sipher configuration"
	echo "		To remove Cerberus network organization and Ordering Service instances data from environment configuration:"
	echo "		-e cerb"
	echo "		To remove all external (to Sipher) organizations data from Sipher environment configuration:"
	echo "		-e ext"
	echo "		To remove Cerberus network organization, Ordering Service instances and all external (to Sipher) organizations data from environment configuration:"
	echo "		-e network"
	echo "		To remove a single external (to Sipher) organizaion data from environment configuration:"
	echo "		-e <organization-name>"
	echo
	echo "	add-extra-hosts"
	echo "		Adds extra hosts to Sipher configuration files"
	echo "		To add extra hosts for Cerberus network and Ordering Service instances:"
	echo "		-e cerb"
	echo "		To add extra hosts for all external (to Sipher) organizations to configuration files:"
	echo "		-e ext"
	echo "		To add extra hosts for Cerberus network organization, Ordering Service instances and all external (to Sipher) organizations to configuration files:"
	echo "		-e network"
	echo "		To add extra hosts for a single external (to Sipher) organization to configuration files:"
	echo "		-e <organization-name>"
	echo
	echo "	remove-extra-hosts"
	echo "		Removes extra hosts from Sipher configuration files"
	echo "		To remove Cerberus network organization and Ordering Service instances extra hosts:"
	echo "		-e cerb"
	echo "		To remove extra hosts for all external (to Sipher) organizations:"
	echo "		-e ext"
	echo "		To remove extra hosts for Cerberus network organization, Ordering Service instances and all external (to Sipher) organizations:"
	echo "		-e network"
	echo "		To remove extra hosts for a single external (to Sipher) organization:"
	echo "		-e <organization-name>"
	echo
	echo


  echo "Usage: "
  echo "  sipherorg.sh <mode> [-c <channel name>] [-t <timeout>] [-d <delay>] [-f <docker-compose-file>] [-s <dbtype>] [-l <language>] [-o <consensus-type>] [-i <imagetag>] [-v]"
  echo "    <mode> - one of 'up', 'down', 'restart', 'generate' or 'upgrade'"
  echo "      - 'up' - bring up the network with docker-compose up"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo "    -c <channel name> - channel name to use (defaults to \"mychannel\")"
  echo "    -t <timeout> - CLI timeout duration in seconds (defaults to 10)"
  echo "    -d <delay> - delay duration in seconds (defaults to 3)"
  echo "    -f <docker-compose-file> - specify which docker-compose file use (defaults to docker-compose-cli.yaml)"
  echo "    -s <dbtype> - the database backend to use: goleveldb (default) or couchdb"
  echo "    -l <language> - the chaincode language: golang (default) or node"
  echo "    -o <consensus-type> - the consensus-type of the ordering service: solo (default) or kafka"
  echo "    -i <imagetag> - the tag to be used to launch the network (defaults to \"latest\")"
  echo "    -v - verbose mode"
}

# Ask user for confirmation to proceed
function askProceed() {
	echo "Continue? [Y/n] "
	read -p " " ans
	case "$ans" in
	y | Y | "")
		echo "proceeding ..."
		;;
	n | N)
		echo "exiting..."
		exit 1
		;;
	*)
		echo "invalid response"
		askProceed
		;;
	esac
}

function getArch() {

	ARCH=$(uname -s | grep Darwin)
	if [ "$ARCH" == "Darwin" ]; then
		OPTS="-it"
	else
		OPTS="-i"
	fi
}

# Obtain CONTAINER_IDS and remove them
# TODO Might want to make this optional - could clear other containers
function clearContainers() {
	CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-*.*.personaccountscc.*/) {print $1}')
	if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
		echo "---- No containers available for deletion ----"
	else
		docker rm -f $CONTAINER_IDS
	fi

	CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-*.*.institutionaccountscc.*/) {print $1}')
	if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
		echo "---- No containers available for deletion ----"
	else
		docker rm -f $CONTAINER_IDS
	fi

	CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-*.*.integrationaccountscc.*/) {print $1}')
	if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
		echo "---- No containers available for deletion ----"
	else
		docker rm -f $CONTAINER_IDS
	fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# TODO list generated image naming patterns
function removeUnwantedImages() {
	DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-*pr.*.personaccountscc.*/) {print $3}')
	if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
		echo "---- No images available for deletion ----"
	else
		docker rmi -f $DOCKER_IMAGE_IDS
	fi

	DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-*pr.*.institutionaccountscc.*/) {print $3}')
	if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
		echo "---- No images available for deletion ----"
	else
		docker rmi -f $DOCKER_IMAGE_IDS
	fi

	DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-*pr.*.integrationaccountscc.*/) {print $3}')
	if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
		echo "---- No images available for deletion ----"
	else
		docker rmi -f $DOCKER_IMAGE_IDS
	fi
}

# Versions of fabric known not to work with this release of cerberus-network
BLACKLISTED_VERSIONS="^1\.0\. ^1\.1\.0-preview ^1\.1\.0-alpha"

# Do some basic sanity checking to make sure that the appropriate versions of fabric
# binaries/images are available.  In the future, additional checking for the presence
# of go or other items could be added.
function checkPrereqs() {
	source .env

	# Note, we check configtxlator externally because it does not require a config file, and peer in the
	# docker image because of FAB-8551 that makes configtxlator return 'development version' in docker
	LOCAL_VERSION=$(configtxlator version | sed -ne 's/ Version: //p')
	DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)

	echo "LOCAL_VERSION=$LOCAL_VERSION"
	echo "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

	if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
		echo "=================== WARNING ==================="
		echo "  Local fabric binaries and docker images are  "
		echo "  out of  sync. This may cause problems.       "
		echo "==============================================="
	fi

	for UNSUPPORTED_VERSION in $BLACKLISTED_VERSIONS; do
		echo "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
		if [ $? -eq 0 ]; then
			echo "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
			exit 1
		fi

		echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
		if [ $? -eq 0 ]; then
			echo "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
			exit 1
		fi
	done
}

function addCerberusEnvData() {	

	# read network data inside network-config/ folder
	getArch
	CURRENT_DIR=$PWD

	OS_CONFIG_FILE=network-config/os-data.json
	if [ ! -f "$OS_CONFIG_FILE" ]; then
		echo
		echo "ERROR: $OS_CONFIG_FILE file not found. Cannot proceed with parsing Ordering Service instances network configuration"
		exit 1
	fi

	CERBERUSORG_CONFIG_FILE=network-config/cerberusorg-data.json
	if [ ! -f "$CERBERUSORG_CONFIG_FILE" ]; then
		echo
		echo "ERROR: $CERBERUSORG_CONFIG_FILE file not found. Cannot proceed with parsing Cerberus Organization network configuration"
		exit 1
	fi

	source .env

	addOsEnvData
	addCerberusOrgEnvData
}

# adds external organization environment data
function addExternalOrgEnvData() {
	
	# read data inside external-orgs folder
	getArch
	CURRENT_DIR=$PWD

	if [ "${EXTERNAL_ORG}" == "all" ]; then
		# add environment data for all organizations
		for file in external-orgs/*-data.json; do

			addExternalOrganizationEnvData $file
		done
	else
		# add environment data for a specific organization
		ORG_CONFIG_FILE="external-orgs/${EXTERNAL_ORG}-data.json"
		if [ ! -f "$ORG_CONFIG_FILE" ]; then
			echo
			echo "ERROR: $ORG_CONFIG_FILE file not found. Cannot proceed with parsing ${EXTERNAL_ORG^} configuration"
			exit 1
		fi

		addExternalOrganizationEnvData $ORG_CONFIG_FILE
	fi
}

function removeCerberusEnvData() {

	# read network data inside network-config/ folder
	getArch
	CURRENT_DIR=$PWD

	OS_CONFIG_FILE=network-config/os-data.json
	if [ ! -f "$OS_CONFIG_FILE" ]; then
		echo
		echo "ERROR: $OS_CONFIG_FILE file not found. Cannot proceed with parsing Ordering Service instances network configuration"
		exit 1
	fi

	CERBERUSORG_CONFIG_FILE=network-config/cerberusorg-data.json
	if [ ! -f "$CERBERUSORG_CONFIG_FILE" ]; then
		echo
		echo "ERROR: $CERBERUSORG_CONFIG_FILE file not found. Cannot proceed with parsing Cerberus Organization network configuration"
		exit 1
	fi

	source .env
	
	removeOsEnvData
	removeCerberusOrgEnvData
}

function checkCerberusEnv() {

	# read network data inside network-config/ folder
	getArch
	CURRENT_DIR=$PWD

	OS_CONFIG_FILE=network-config/os-data.json
	if [ ! -f "$OS_CONFIG_FILE" ]; then
		echo
		echo "ERROR: $OS_CONFIG_FILE file not found. Cannot proceed with parsing network configuration"
		exit 1
	fi

	CERBERUSORG_CONFIG_FILE=network-config/cerberusorg-data.json
	if [ ! -f "$CERBERUSORG_CONFIG_FILE" ]; then
		echo
		echo "ERROR: $CERBERUSORG_CONFIG_FILE file not found. Cannot proceed with parsing Cerberus Organization network configuration"
		exit 1
	fi

	osinstances=$(jq -r '.os[] | "\(.instances)"' $OS_CONFIG_FILE)

	source .env

	# check if needed variables are set
	for osinstance in $(echo "${osinstances}" | jq -r '.[] | @base64'); do
		_jq(){
			# check if os label environment variable is set
			osLabelValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${1})\"")
			osLabelValueStripped=$(echo $osLabelValue | sed 's/"//g')	
			osLabelVar="${osLabelValueStripped^^}_LABEL"

			if [ -z "${!osLabelVar}" ]; then
				echo "Required network environment data is not present. Obtaining ... "
				addOsEnvData
			fi
		}
 		echo $(_jq '.label')
	done

	# check if cerberus org label environment variable is set
	orgLabelValue=$(jq -r '.label' $CERBERUSORG_CONFIG_FILE)
	orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')
	orgLabelVar="${orgLabelValueStripped^^}_LABEL"

	if [ -z "${!orgLabelVar}" ]; then
		echo "Required network environment data is not present. Obtaining ... "
		addCerberusOrgEnvData
		source .env
	fi
}


function checkExternalOrgEnvData() {

	ORG_CONFIG_FILE=$1

	# read network data inside network-config/ folder
	getArch 
	CURRENT_DIR=$PWD

	if [ ! -f "$ORG_CONFIG_FILE" ]; then
		echo
		echo "ERROR: $ORG_CONFIG_FILE file not found. Cannot proceed with parsing ${EXTERNAL_ORG^} configuration"
		exit 1
	fi

	source .env
	
	# check if environment variables for organization are set
	orgLabelValue=$(jq -r '.label' $ORG_CONFIG_FILE)
	orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')
	orgLabelVar="${orgLabelValueStripped^^}_ORG_LABEL"

	if [ -z "${!orgLabelVar}" ]; then
		echo "Required organization environment data is missing. Obtaining ... "
		addExternalOrganizationEnvData $ORG_CONFIG_FILE
		source .env
	fi
}

function removeExternalOrgEnvData() {

	# read data inside external-orgs folder
	getArch
	CURRENT_DIR=$PWD

	if [ "${EXTERNAL_ORG}" == "all" ]; then
		# remove environment data for all organizations
		for file in external-orgs/*-data.json; do
			
			removeExternalOrganizationEnvData $file
		done
	else
		# remove environment data for a specific organization
		ORG_CONFIG_FILE="external-orgs/${EXTERNAL_ORG}-data.json"

		if [ ! -f "$ORG_CONFIG_FILE" ]; then
			echo
			echo "ERROR: $ORG_CONFIG_FILE file not found. Cannot proceed with parsing ${EXTERNAL_ORG^} configuration"
			exit 1
		fi

		removeExternalOrganizationEnvData $ORG_CONFIG_FILE
	fi
}


function addExternalOrgExtraHosts() {

	# read data inside external-orgs folder
	getArch
	CURRENT_DIR=$PWD

	if [ "${EXTERNAL_ORG}" == "all" ]; then	
		for file in external-orgs/*-data.json; do

			# check if environment data is set, if not - set it
			checkExternalOrgEnvData $file

			# add external organization extra hosts to configuration
			addExternalOrganizationExtraHosts $file
		done
	else
	
		# add environment data for a specific organization
		ORG_CONFIG_FILE="external-orgs/${EXTERNAL_ORG}-data.json"
 
		if [ ! -f "$ORG_CONFIG_FILE" ]; then
			echo
			echo "ERROR: $ORG_CONFIG_FILE file not found. Cannot proceed with parsing ${EXTERNAL_ORG^} configuration"
			exit 1
		fi

		# check if exnvironment data is set, if not - set it
		checkExternalOrgEnvData $ORG_CONFIG_FILE

		# add external data organization extra hosts to configuration
		addExternalOrganizationExtraHosts $ORG_CONFIG_FILE
	fi
}

function removeExternalOrgExtraHosts() {

	# read data inside external-orgs folder
	getArch 
	CURRENT_DIR=$PWD

 	if [ "${EXTERNAL_ORG}" == "all" ]; then
		# remove environment data for all organizations
		for file in external-orgs/*-data.json; do

			removeExternalOrganizationExtraHosts $file
		done
	else
		# remove environment data for a specific organization
		ORG_CONFIG_FILE="external-orgs/${EXTERNAL_ORG}-data.json"

		if [ ! -f "$ORG_CONFIG_FILE" ]; then
			echo
			echo "ERROR: $ORG_CONFIG_FILE file not found. Cannot proceed with parsing ${EXTERNAL_ORG^} configuration"
			exit 1
		fi
	
		removeExternalOrganizationExtraHosts $ORG_CONFIG_FILE
	fi
}


# configuration
function replacePrivateKey() {
	# sed on MacOSX does not support -i flag with a null extension. We will use
	# 't' for our back-up's extension and delete it at the end of the function
	getArch
	# Copy the template to the file that will be modified to add the private key
	cp $COMPOSE_FILE_SIPHER_CA_TEMPLATE $COMPOSE_FILE_SIPHER_CA

	# The next steps will replace the template's contents with the
	# actual values of the private key file names for the two CAs.
	CURRENT_DIR=$PWD
	cd crypto-config/peerOrganizations/sipher.cerberus.net/ca/
	PRIV_KEY=$(ls *_sk)
	cd "$CURRENT_DIR"
	sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" $COMPOSE_FILE_SIPHER_CA

	if [ "$ARCH" == "Darwin" ]; then
		rm /sipher-config/sipher-ca.yamlt
	fi
}

# We will use the cryptogen tool to generate the cryptographic material (x509 certs)
# for our various network entities.  The certificates are based on a standard PKI
# implementation where validation is achieved by reaching a common trust anchor.
#
# Cryptogen consumes a file - ``crypto-config.yaml`` - that contains the network
# topology and allows us to generate a library of certificates for both the
# Organizations and the components that belong to those Organizations.  Each
# Organization is provisioned a unique root certificate (``ca-cert``), that binds
# specific components (peers and orderers) to that Org.  Transactions and communications
# within Fabric are signed by an entity's private key (``keystore``), and then verified
# specific components (peers and orderers) to that Org.  Transactions and communications
# within Fabric are signed by an entity's private key (``keystore``), and then verified
# by means of a public key (``signcerts``).  You will notice a "count" variable within
# this file.  We use this to specify the number of peers per Organization; in our
# case it's two peers per Org.  The rest of this template is extremely
# self-explanatory.
#
# After we run the tool, the certs will be parked in a folder titled ``crypto-config``.

# Generates Org certs using cryptogen tool
function generateCerts() {
	which cryptogen
	if [ "$?" -ne 0 ]; then
		echo "cryptogen tool not found. exiting"
		exit 1
	fi
	echo
	echo "##########################################################"
	echo "##### Generate certificates using cryptogen tool #########"
	echo "##########################################################"

	if [ -d "crypto-config" ]; then
		rm -Rf crypto-config
	fi
	set -x
	cryptogen generate --config=./crypto-config.yaml
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate certificates..."
		exit 1
	fi
	echo
}

# The `configtxgen tool is used to create four artifacts: orderer **bootstrap
# block**, fabric **channel configuration transaction**, and two **anchor
# peer transactions** - one for each Peer Org.
#
# The orderer block is the genesis block for the ordering service, and the
# channel transaction file is broadcast to the orderer at channel creation
# time.  The anchor peer transactions, as the name might suggest, specify each
# Org's anchor peer on this channel.
#
# Configtxgen consumes a file - ``configtx.yaml`` - that contains the definitions
# for the sample network. There are three members - one Orderer Org (``OrdererOrg``)
# and two Peer Orgs (``Org1`` & ``Org2``) each managing and maintaining two peer nodes.
# This file also specifies a consortium - ``SampleConsortium`` - consisting of our
# two Peer Orgs.  Pay specific attention to the "Profiles" section at the top of
# this file.  You will notice that we have two unique headers. One for the orderer genesis
# block - ``TwoOrgsOrdererGenesis`` - and one for our channel - ``TwoOrgsChannel``.
# These headers are important, as we will pass them in as arguments when we create
# our artifacts.  This file also contains two additional specifications that are worth
# noting.  Firstly, we specify the anchor peers for each Peer Org
# (``peer0.org1.example.com`` & ``peer0.org2.example.com``).  Secondly, we point to
# the location of the MSP directory for each member, in turn allowing us to store the
# root certificates for each Org in the orderer genesis block.  This is a critical
# concept. Now any network entity communicating with the ordering service can have
# its digital signature verified.
#
# This function will generate the crypto material and our four configuration
# artifacts, and subsequently output these files into the ``channel-artifacts``
# folder.
#
# If you receive the following warning, it can be safely ignored:
#
# [bccsp] GetDefault -> WARN 001 Before using BCCSP, please call InitFactories(). Falling back to bootBCCSP.
#
# You can ignore the logs regarding intermediate certs, we are not using them in
# this crypto implementation.

# Generate orderer genesis block, channel configuration transaction and
# anchor peer update transactions
function generateChannelsArtifacts() {

	which configtxgen
	if [ "$?" -ne 0 ]; then
		echo "configtxgen tool not found. exiting"
		exit 1
	fi

	echo "###########################################################"
	echo "#########  Generating Sipher config material ##############"
	echo "###########################################################"

	set -x
	configtxgen -printOrg SipherMSP > channel-artifacts/sipher-channel-artifacts.json
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate Sipher config materials "
		exit 1
	fi
}

function test() {
	# copy orderer organizations folder from os host
	ordererPath=$CERBERUS_OS_IP:/home/anniran/server/go/src/cerberus-os/hl/network/crypto-config/ordererOrganizations

	which sshpass
	if [ "$?" -ne 0 ]; then
		echo "sshpass tool not found"
		exit 1
	fi
  
	sshpass -p "${CERBERUS_OS_PASSWORD}" scp -r $CERBERUS_OS_USERNAME@$ordererPath crypto-config/
	echo
}

function generateOrgConfiguration() {

	checkPrereqs
	# generate artifacts if they don't exist
	if [ ! -d "crypto-config" ]; then
		generateCerts
		replacePrivateKey
		generateChannelsArtifacts
	fi		
}

function addEnvDataToNetworkRemotely() {
	
	checkCerberusOsOrgEnvForSsh

	# set sipher data remotely
	which sshpass
	if [ "$?" -ne 0 ]; then
		echo "sshpass tool not found"
		exit 1
	fi

	if sshpass -p "${CERBERUS_OS_PASSWORD}" ssh $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP '[ ! -f /home/anniran/server/go/src/cerberus-os/hl/network/external-orgs/sipher-data.json ]'; then
		deliverOrgConfigurationFileToCerberus
	fi

	scriptLocation=$CERBERUS_OS_HOSTPATH/hl/network/cerberusntw.sh

	sshpass -p "${CERBERUS_OS_PASSWORD}" ssh $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP "cd $CERBERUS_OS_HOSTPATH/hl/network && ./cerberusntw.sh add-org-env -n sipher"
	if [ "$?" -ne 0 ]; then
		echo "ERROR: Cannot add Sipher environment data to network."
		exit 1
	fi

	echo "Sipher environment data added remotely to Cerberus network records"
}

function removeEnvDataFromNetworkRemotely() {

	checkCerberusOsOrgEnvForSsh

	# unset sipher data remotely
	which sshpass
	if [ "$?" -ne 0 ]; then
		echo "sshpass tool not found"
		exit 1
	fi

	scriptLocation=$CERBERUS_OS_HOSTPATH/hl/network/cerberusntw.sh

	sshpass -p "${CERBERUS_OS_PASSWORD}" ssh $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP "cd $CERBERUS_OS_HOSTPATH/hl/network && ./cerberusntw.sh remove-org-env -n sipher"
	if [ "$?" -ne 0 ]; then
		echo "ERROR: Cannot add Sipher environment data to network."	
		exit 1
	fi

	echo "Sipher environment data removed remotely from Cerberus network records"

}

function addInherentHostsToNetworkRemotely() {

	checkCerberusOsOrgEnvForSsh

	# unset sipher data remotely
	which sshpass
	if [ "$?" -ne 0 ]; then
		echo "sshpass tool not found"
		exit 1
	fi

	if sshpass -p "${CERBERUS_OS_PASSWORD}" ssh $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP '[ ! -f /home/anniran/server/go/src/cerberus-os/hl/network/external-orgs/sipher-data.json ]'; then
		deliverOrgConfigurationFileToCerberus
	fi

	scriptLocation=$CERBERUS_OS_HOSTPATH/hl/network/cerberusntw.sh
   
	sshpass -p "${CERBERUS_OS_PASSWORD}" ssh $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP "cd $CERBERUS_OS_HOSTPATH/hl/network && ./cerberusntw.sh add-org-hosts -n sipher"
	if [ "$?" -ne 0 ]; then
		echo "ERROR: Cannot add Sipher hosts to network configuration files "
		exit 1
	fi
    
	echo "Sipher containers hosts data successfully added to Cerberus OS and organization"
}

function removeInherentHostsFromNetworkRemotely() {

	checkCerberusOsOrgEnvForSsh

	# unset sipher data remotely
	which sshpass
	if [ "$?" -ne 0 ]; then
		echo "sshpass tool not found"
		exit 1
	fi      

	scriptLocation=$CERBERUS_OS_HOSTPATH/hl/network/cerberusntw.sh

	sshpass -p "${CERBERUS_OS_PASSWORD}" ssh $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP "cd $CERBERUS_OS_HOSTPATH/hl/network && ./cerberusntw.sh remove-org-hosts -n sipher"
	if [ "$?" -ne 0 ]; then
		echo "ERROR: Cannot add Sipher hosts to network configuration files "
		exit 1
	fi

	echo "Sipher containers hosts data successfully added to Cerberus OS and organization"

}

function deliverOrgConfigurationFileToCerberus() {
    
	# deliver sipher-data.json file to network
	destination=$CERBERUS_OS_IP:/home/anniran/server/go/src/cerberus-os/hl/network/external-orgs
    
	which sshpass
	if [ "$?" -ne 0 ]; then
	       echo "sshpass not found"
	       exit 1
	fi
    
	sshpass -p "${CERBERUS_OS_PASSWORD}" scp sipher-config/sipher-data.json $CERBERUS_OS_USERNAME@$destination
	if [ "$?" -ne 0 ]; then
		echo "ERROR: Cannot copy Sipher configuration file to network hosts"
		exit 1
	fi

	echo "Sipher configuration file successfully copied to network hosts"    
}

function deliverOrgChannelArtifacts() {

	source .env

	which sshpass
	if [ "$?" -ne 0 ]; then
		echo "sshpass tool not found"
		exit 1
	fi

	# deliver channel config files
	destination=/home/$CERBERUS_OS_USERNAME/server/go/src/cerberus-os/hl/network/external-orgs/sipher-artifacts

	if sshpass -p "${CERBERUS_OS_PASSWORD}" ssh $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP '[ ! -d /home/anniran/server/go/src/cerberus-os/hl/network/external-orgs/sipher-artifacts ]'; then
		sshpass -p "${CERBERUS_OS_PASSWORD}" ssh $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP "mkdir $destination"
	fi

	sshpass -p "${CERBERUS_OS_PASSWORD}" scp configtx.yaml $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP:$destination/
	sshpass -p "${CERBERUS_OS_PASSWORD}" scp crypto-config.yaml $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP:$destination/
	sshpass -p "${CERBERUS_OS_PASSWORD}" scp channel-artifacts/sipher-channel-artifacts.json $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP:$destination/
	sshpass -p "${CERBERUS_OS_PASSWORD}" scp channel-artifacts/sipher-channel-artifacts.json $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP:/home/$CERBERUS_OS_USERNAME/server/go/src/cerberus-os/hl/network/channel-artifacts
	echo "========= Delivered Sipher artifacts to Cerberus Network filesystem ========="
}

function connectToNetwork() {

	source .env

	# check if sipher-channel-artifacts.json file is present locally
	if [ ! -f channel-artifacts/sipher-channel-artifacts.json ]; then
		echo "Sipher channel artifacts configuration file is not present"
		echo "Run './sipher.sh generate' to generate required configurations and be able to proceed"
		echo "Run './sipher.sh configure-connection' and follow the required steps to connect organization to Cerberus network"

		exit 1
	fi

	channels=$(echo $CHANNELS_LIST | tr "," "\n")
	
	for channel in $channels; do
		if [ "$channel" == "pers" ]; then
			echo "Adding Sipher to PersonAccounts channel is selected"
			echo
		elif [ "$channel" == "inst" ]; then
			echo "Adding Sipher to InstitutionAccounts channel is selected"
			echo
		elif [ "$channel" == "int" ]; then			
			echo "Adding Sipher to IntegrationAccounts channel is selected"
			echo
		else 
			echo "Channel name: $channel unknown"
			exit 1
		fi
	done

	if [ "$NETWORK_CONNECTION_MODE" == "sol" ]; then
	
		connectToNetworkSipherOrg

	elif [ "$NETWORK_CONNECTION_MODE" == "net" ]; then
		
		connectToNetworkCerberusOrg

	else
		echo "Unknown network connection mode"
		exit 1
	fi
}

# Generate the needed certificates, the genesis block and start the network.
function organizationUp() {
	
	channelOption=$1

	checkPrereqs

	# generate artifacts if they don't exist
	if [ ! -d "crypto-config" ]; then
		generateCerts
		replacePrivateKey
		generateChannelsArtifacts
	fi

	# add hosts
	addRemoteHosts

	# 
	deliverOrgChannelArtifacts

	# connect to channels
	# channel options:
	# all
	# person
	# institution
	# integration
	# none - ?
	connectToNetwork

	# bring up containers
	#IMAGE_TAG=$IMAGETAG docker-compose -f $COMPOSE_FILE_SIPHER_CA -f $COMPOSE_FILE_SIPHER  up -d 1>&1
	#if [ $? -ne 0 ]; then
	#	echo "ERROR !!!! Unable to start network"
		#exit 1
	#fi

	# join channels
	#docker exec cli.sipher.cerberus.net ./scripts/joinChannel.sh $PERSON_ACCOUNTS_CHANNEL $INSTITUTION_ACCOUNTS_CHANNEL $INTEGRATION_ACCOUNTS_CHANNEL $channelOption 

	#docker exec cli.sipher.cerberus.net scripts/script.sh $PERSON_ACCOUNTS_CHANNEL $ORGANIZATION_ACCOUNTS_CHANNEL $INTEGRATION_ACCOUNTS_CHANNEL $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE
	#if [ $? -ne 0 ]; then
		#echo "ERROR !!!! Test failed"
		#exit 1
	#fi
	echo "finished up function"
}


# add disconnect for each channel and from all channels 

function organizationDown() {
	# stop org3 containers also in addition to org1 and org2, in case we were running sample to add org3
	# stop kafka and zookeeper containers in case we're running with kafka consensus-type
	docker-compose -f $COMPOSE_FILE_SIPHER_CA -f $COMPOSE_FILE_SIPHER down --volumes --remove-orphans

	# Don't remove the generated artifacts -- note, the ledgers are always removed
	if [ "$MODE" != "restart" ]; then
		# Bring down the network, deleting the volumes
		# Delete any ledger backups
		docker run -v $PWD:/tmp/cerberus-network --rm hyperledger/fabric-tools:$IMAGETAG rm -Rf /tmp/cerberus-network/ledgers-backup
		#Cleanup the chaincode containers
		clearContainers
		#Cleanup images
		removeUnwantedImages
		# remove orderer block and other channel configuration transactions and certs
		rm -rf channel-artifacts/*.block channel-artifacts/*.tx channel-artifacts/*.json crypto-config
		# remove the docker-compose yaml file that was customized to the example
		rm -f $COMPOSE_FILE_SIPHER_CA
	fi
}
 

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform, e.g., darwin-amd64 or linux-amd64
OS_ARCH=$(echo "$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
CLI_TIMEOUT=10
# default for delay between commands
CLI_DELAY=20

PERSON_ACCOUNTS_CHANNEL="pachannel"
ORGANIZATION_ACCOUNTS_CHANNEL="oachannel"
INTEGRATION_ACCOUNTS_CHANNEL="iachannel"

# use this as the default docker-compose yaml definition
COMPOSE_FILE=docker-compose-cli.yaml
#
# sipher docker compose files
COMPOSE_FILE_SIPHER_CA=sipher-config/sipher-ca.yaml
COMPOSE_FILE_SIPHER_CA_TEMPLATE=base/sipher-ca-template.yaml
COMPOSE_FILE_SIPHER=sipher-config/sipher-org.yaml
#
# use golang as the default language for chaincode
LANGUAGE=golang
LIST=''
# default image tag
IMAGETAG="latest"
# default consensus type
CONSENSUS_TYPE="kafka"

CHANNEL_NAME=''
NETWORK_CONNECTION_MODE=''
EXTERNAL_ORG=''
ENTITY=''

# Parse commandline args
if [ "$1" = "-m" ]; then # supports old usage, muscle memory is powerful!
  shift
fi
MODE=$1
shift

# ./sipher.sh help
if [ "$MODE" == "help" ]; then
	EXPMODE="Display help usage message"



elif [ "$MODE" == "up" ]; then
  EXPMODE="Starting"
elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping"
elif [ "$MODE" == "restart" ]; then
  EXPMODE="Restarting"


# ./sipher.sh configure-connection
elif [ "${MODE}" == "configure-connection" ]; then
	EXPMODE="Display connection cofiguration steps for Sipher organization"

# ./sipher.sh generate
elif [ "${MODE}" == "generate" ]; then
	EXPMODE="Generating certificates and genesis block"

# ./sipher.sh add-env
elif [ "${MODE}" == "add-env" ]; then
	EXPMODE="Adding entity data to environment configuration"

# ./sipher.sh remove-env
elif [ "${MODE}" == "remove-env" ]; then
	EXPMODE="Removing entity data from environment configuration"

# ./sipher.sh add-extra-hosts
elif [ "${MODE}" == "add-extra-hosts" ]; then
	EXPMODE="Adding extra hosts to Sipher configuration files"

# ./sipher.sh remove-extra-hosts
elif [ "${MODE}" == "remove-extra-hosts" ]; then
	EXPMODE="Removing extra hosts from Sipher configuration files"





######################################################################################################
# ./sipher.sh add-sipher-env-to-network
elif [ "${MODE}" == "add-sipher-env-to-network" ]; then
	EXPMODE="Adding Sipher environment data to network remotely"

# ./sipher.sh remove-sipher-env-from-network
elif [ "${MODE}" == "remove-sipher-env-from-network" ]; then
	EXPMODE="Removing Sipher environment data from network remotely"

# ./sipher.sh add-network-hosts
elif [ "${MODE}" == "add-network-hosts" ]; then
	EXPMODE="Adding Cerberus OS and organization hosts to Sipher containers"

# ./sipher.sh remove-network-hosts
elif [ "${MODE}" == "remove-network-hosts" ]; then
	EXPMODE="Removing Cerberus OS and organization hosts from Sipher containers"

# ./sipher.sh add-inherent-hosts-to-network
elif [ "${MODE}" == "add-inherent-hosts-to-network" ]; then
	EXPMODE="Adding Sipher hosts to Cerberus OS and organization containers configuration"

# ./sipher.sh remove-inherent-hosts-network
elif [ "${MODE}" == "remove-inherent-hosts-network" ]; then
	EXPMODE="Removing Sipher hosts from Cerberus OS and organization containers configuration"
########################################################################################################

elif [ "${MODE}" == "connect-to-network" ]; then
	EXPMODE="Connecting Sipher to network channel/channels"




elif [ "${MODE}" == "test" ]; then
	EXPMODE="Testing"



elif [ "${MODE}" == "connect" ]; then
	EXPMODE="Connecting Sihper to Cerberus network"



elif [ "$MODE" == "connect" ]; then
  EXPMODE="Connecting Sipher to network"
elif [ "$MODE" == "disconnect" ]; then
  EXPMODE="Disconnecting Sipher from network"
else
  printHelp
  exit 1
fi

while getopts "h?c:t:d:e:f:n:o:s:l:i:v" opt; do
	case "$opt" in
  	h | \?)
		printHelp
		exit 0
		;;
	c)
		CHANNEL_NAME=$OPTARG
		;;
	t)
		CLI_TIMEOUT=$OPTARG
		;;
	d)
		CLI_DELAY=$OPTARG
		;;
	e)
		ENTITY=$OPTARG
		;;
	f)
		COMPOSE_FILE=$OPTARG
		;;
	n)
		NETWORK_CONNECTION_MODE=$OPTARG
		;;
	o)
		EXTERNAL_ORG=$OPTARG
		;;
	s)
		IF_COUCHDB=$OPTARG
		;;
	l)
		CHANNELS_LIST=$OPTARG
		;;
	i)
		IMAGETAG=$(go env GOARCH)"-"$OPTARG
		;;
	v)
		VERBOSE=true
		;;
	esac
done


# Announce what was requested
#echo "${EXPMODE} Sipher Org with CLI timeout of '${CLI_TIMEOUT}' seconds and CLI delay of '${CLI_DELAY}' seconds"
echo "${EXPMODE}"

# ask for confirmation to proceed
askProceed

if [ "${MODE}" == "help" ]; then
	printHelp

#Create the network using docker compose
elif [ "${MODE}" == "up" ]; then
	# check if channel option is provided
	if [ -z "$CHANNEL_NAME" ]; then
		echo "Please provide a channel name to connect with '-c' option tag"
		printHelp
		exit 1
	fi
	organizationUp $CHANNEL_NAME

elif [ "${MODE}" == "down" ]; then ## Clear the network
	organizationDown






# ./sipher.sh configure-connection
elif [ "${MODE}" == "configure-connection" ]; then
	source .env
	echo $CERBERUS_NETWORK_LOCAL_PATH
	printConnectionSteps

# ./sipher.sh generate
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
	generateOrgConfiguration

# ./sipher.sh add-env
elif [ "${MODE}" == "add-env" ]; then

	# check if entity value is provided
	if [ -z "$ENTITY" ]; then
		echo "Please provide entity name with '-e' option tag"
		printHelp
		exit 1
	fi

	if [ "${ENTITY}" == "cerb" ]; then
		addCerberusEnvData

	elif [ "${ENTITY}" == "ext" ]; then
		EXTERNAL_ORG="all"
		addExternalOrgEnvData

	elif [ "${ENTITY}" == "network" ]; then
		addCerberusEnvData

		EXTERNAL_ORG="all"
		addExternalOrgEnvData
	else
		EXTERNAL_ORG=$ENTITY
		addExternalOrgEnvData
	fi

# ./sipher.sh remove-env
elif [ "${MODE}" == "remove-env" ]; then

	# check if entity value is provided
	if [ -z "$ENTITY" ]; then
		echo "Please provide entity name with '-e' option tag"
		printHelp
		exit 1
	fi

	if [ "${ENTITY}" == "cerb" ]; then
		removeCerberusEnvData

	elif [ "${ENTITY}" == "ext" ]; then
		EXTERNAL_ORG="all"
		removeExternalOrgEnvData

	elif [ "${ENTITY}" == "network" ]; then
		removeCerberusEnvData

		EXTERNAL_ORG="all"
		removeExternalOrgEnvData

	else 
		EXTERNAL_ORG=$ENTITY
		removeExternalOrgEnvData
	fi

# ./sipher.sh add-extra-hosts
elif [ "${MODE}" == "add-extra-hosts" ]; then

	# check if entity value is provided
	if [ -z "$ENTITY" ]; then
		echo "Please provide entity name with '-e' option tag"
		printHelp
		exit 1
	fi

	if [ "${ENTITY}" == "cerb" ]; then
		checkCerberusEnv
		
		addCerberusExtraHosts

	elif [ "${ENTITY}" == "ext" ]; then
		EXTERNAL_ORG="all"
		addExternalOrgExtraHosts

	elif [ "${ENTITY}" == "network" ]; then
		checkCerberusEnv

		addCerberusExtraHosts

		EXTERNAL_ORG="all"
		addExternalOrgExtraHosts
	else
		EXTERNAL_ORG=$ENTITY
		addExternalOrgExtraHosts
	fi

# ./sipher.sh remove-extra-hosts
elif [ "${MODE}" == "remove-extra-hosts" ]; then

	# check if entity value is provided
	if [ -z "$ENTITY" ]; then
		echo "Please provide entity name with '-e' option tag"
		printHelp
		exit 1
	fi

	if [ "${ENTITY}" == "cerb" ]; then
		removeCerberusExtraHosts

	elif [ "${ENTITY}" == "ext" ]; then
		EXTERNAL_ORG="all"
		removeExternalOrgExtraHosts

	elif [ "${ENTITY}" == "network" ]; then
		removeCerberusExtraHosts

		EXTERNAL_ORG="all"
		removeExternalOrgExtraHosts
	else
		EXTERNAL_ORG=$ENTITY
		removeExternalOrgExtraHosts
	fi


###########################################################################################
# functions that call remote scripts

# ./sipher.sh add-sipher-env-to-network
elif [ "${MODE}" == "add-sipher-env-to-network" ]; then
	addEnvDataToNetworkRemotely

# remove sipher nevironment data from network remotely -> remove-senvfromnet-remotely	
# ./sipher.sh remove-senvfromnet-remotely
elif [ "${MODE}" == "remove-sipher-env-from-network" ]; then
	removeEnvDataFromNetworkRemotely

# ./sipher.sh add-inherent-hosts-to-network
elif [ "${MODE}" == "add-inherent-hosts-to-network" ]; then
	addInherentHostsToNetworkRemotely


# ./sipher.sh remove-inherent-hosts-network
elif [ "${MODE}" == "remove-inherent-hosts-network" ]; then
	removeInherentHostsFromNetworkRemotely

#############################################################################################

elif [ "${MODE}" == "connect-to-network" ]; then

	# check if channel name is provided
	if [ -z "$CHANNELS_LIST" ]; then
		echo "Please provide a list of channels names to connect to with '-l' option tag"
		echo "If you want to connect to more than one channel, please provide channel names separated with a comma and without space"
		echo "Examples: "
		echo "./sipher.sh connect-to-channel -l pers -n sol"
		echo "./sipher.sh connect-to-channel -l pers,inst -n net"
		echo "./sipher.sh connect-to-channel -l pers,inst,int -n net"
		printHelp
		exit 1
	fi

	if [ -z "$NETWORK_CONNECTION_MODE" ]; then
		echo "Please provide network connection mode value"
		echo "sol - for connecting to network channels indepently via Sipher organization"
		echo "net - for connecting to network channels via cerberus network organization"
		echo "Examples:"
		echo "sipher.sh connect-to-channel -l pers,inst -n sol"
		echo "sipher.sh connect-to-channel -l inst,int -n net"
		exit 1
	fi

	connectToNetwork






elif [ "${MODE}" == "test" ]; then

	echo "this is a test"



elif [ "${MODE}" == "connect" ]; then

	# check if channel option is provided
	if [ -z "$CHANNEL_NAME" ]; then
		echo "Please provide a channel name to connect with '-c' option tag"
		printHelp
		exit 1
	fi

	connectToChannel $CHANNEL_NAME





elif [ "${MODE}" == "restart" ]; then ## Restart the network
  #organizationDown
  organizationUp
elif [ "$MODE" == "connect" ]; then
  connectToNetwork
elif [ "$MODE" == "disconnect" ]; then
  disconnectFromNetwork
else
  printHelp
  exit 1
fi

