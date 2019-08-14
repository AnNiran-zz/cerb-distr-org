#!/bin/bash
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

. sipherconnectcntw.sh
. scripts/connectionSteps.sh
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
	echo "	Operations running on remote host machines:"
	echo "	add-env-r"
	echo "		Adds Sipher environment data to remote machines"
	echo "		To add environment data to Cerberus network organization and Orderins Service instances remote hosts:"
	echo "		-e cerb"
	echo "		To add environment data to all external (to Sipher) organizations:"
	echo "		-e ext"
	echo "		To add environment data to Cerberus network organization, Ordering Service instances and all external (to Sipher) organizations hosts:"
	echo "		-e network"
	echo "		To add environment data to a specific external (to Sipher) organization:"
	echo "		-e <organization-name>"
	echo
	echo "	remove-env-r"
        echo "		Removes Sipher environment data from remote machines"
        echo "		To remove environment data from Cerberus network organization and Orderins Service instances remote hosts:"
        echo "		-e cerb"
        echo "		To remove environment data from all external (to Sipher) organizations:"
        echo "		-e ext"
        echo "		To remove environment data from Cerberus network organization, Ordering Service instances and all external (to Sipher) organizations hosts:"
        echo "		-e network"
        echo "		To remove environment data from a specific external (to Sipher) organization:"
        echo "		-e <organization-name>"
        echo
        echo "	update-env-r"
        echo "		Updates Sipher environment data on remote machines"
        echo "		To update environment data on Cerberus network organization and Orderins Service instances remote hosts:"
        echo "		-e cerb"
        echo "		To update environment data on all external (to Sipher) organizations:"
        echo "		-e ext"
        echo "		To update environment data on Cerberus network organization, Ordering Service instances and all external (to Sipher) organizations hosts:"
        echo "		-e network"
        echo "		To update environment data on a specific external (to Sipher) organization:"
        echo "		-e <organization-name>"
        echo
	echo "	add-extra-hosts-r"
        echo "		Adds Sipher extra hosts data to remote machines"
        echo "		To add extra hosts data to Cerberus network organization and Orderins Service instances remote hosts:"
        echo "		-e cerb"
        echo "		To add extra hosts data to all external (to Sipher) organizations:"
        echo "		-e ext"
        echo "		To add extra hosts data to Cerberus network organization, Ordering Service instances and all external (to Sipher) organizations hosts:"
        echo "		-e network"
        echo "		To add extra hosts data to a specific external (to Sipher) organization:"
        echo "		-e <organization-name>"
        echo
	echo "	remove-extra-hosts-r"
        echo "		Removes Sipher extra hosts data from remote machines"
        echo "		To remove extra hosts data from Cerberus network organization and Orderins Service instances remote hosts:"
        echo "		-e cerb"
        echo "		To remove extra hosts data from all external (to Sipher) organizations:"
        echo "		-e ext"
        echo "		To remove extra hosts data from Cerberus network organization, Ordering Service instances and all external (to Sipher) organizations hosts:"
        echo "		-e network"
        echo "		To remove extra hosts data from a specific external (to Sipher) organization:"
        echo "		-e <organization-name>"
        echo "	update-extra-hosts-r"
        echo "		Updates Sipher extra hosts data on remote machines"
        echo "		To update extra hosts data on Cerberus network organization and Orderins Service instances remote hosts:"
        echo "		-e cerb"
        echo "		To update extra hosts data on all external (to Sipher) organizations:"
        echo "		-e ext"
        echo "		To update extra hosts data on Cerberus network organization, Ordering Service instances and all external (to Sipher) organizations hosts:"
        echo "		-e network"
        echo "		To update extra hosts data on a specific external (to Sipher) organization:"
        echo "		-e <organization-name>"
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
  echo "    -l <language> - the chaincode language: golang (default) or node"
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

PERSON_ACCOUNTS_CHANNEL="persaccntschannel"
INSTITUTION_ACCOUNTS_CHANNEL="instaccntschannel"
INTEGRATION_ACCOUNTS_CHANNEL="integraccntschannel"

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

#######################################################################################################
# Remote operations
# Following starts scripts on remote host machines and perform actions on behalf of organizations hosts

# ./sipher.sh add-s-env
elif [ "${MODE}" == "add-env-r" ]; then
	EXPMODE="Add Sipher environment variables to remote hosts"

# ./sipher.sh remove-env-r
elif [ "${MODE}" == "remove-env-r" ]; then
	EXPMODE="Remove Sipher environment from remote machines"

# ./sipher.sh update-env-r
elif [ "${MODE}" == "update-env-r" ]; then
	EXPMODE="Update Sipher environment on remote machines"

# ./sipher.sh add-extra-hosts-r
elif [ "${MODE}" == "add-extra-hosts-r" ]; then
	EXPMODE="Add Sipher extra hosts data on remote machines"

# ./sipher.sh remove-extra-hosts-r
elif [ "${MODE}" == "remove-extra-hosts-r" ]; then
	EXPMODE="Remove Sipher extra hosts from remote machines"

# ./sipher.sh update-extra-hosts-r
elif [ "${MODE}" == "update-extra-hosts-r" ]; then
	EXPMODE="Update Sipher extra hosts on remote machines"

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
		# add cerberus env data
		bash scripts/addCerberusEnvData.sh

	elif [ "${ENTITY}" == "ext" ]; then
		# add all external organizaitons env data
		for file in external-orgs/*-data.json; do
                        bash scripts/addExternalOrgEnvData.sh $file
                done

	elif [ "${ENTITY}" == "network" ]; then
		# add cerberus env data
		bash scripts/addCerberusEnvData.sh

		# add all external organizaitons env data
		for file in external-orgs/*-data.json; do
                        bash scripts/addExternalOrgEnvData.sh $file
                done

	else
		# add external organization env data
		orgConfigFile="external-orgs/${ENTITY}-data.json"
		
		bash scripts/addExternalOrgEnvData.sh $orgConfigFile
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
		# remove cerberus env data
		bash scripts/removeCerberusEnvData.sh

	elif [ "${ENTITY}" == "ext" ]; then
		# remove all external organizations environment data
		for file in external-orgs/*-data.json; do
			bash scripts/removeExternalOrgEnvData.sh $file
		done		

	elif [ "${ENTITY}" == "network" ]; then
                # remove cerberus env data
                bash scripts/removeCerberusEnvData.sh

		# remove all external organizations environment data
                for file in external-orgs/*-data.json; do
                        bash scripts/removeExternalOrgEnvData.sh $file
                done

	else 
		# remove external organization environment data
		orgConfigFile="external-orgs/${ENTITY}-data.json"
		
		bash scripts/removeExternalOrgEnvData.sh $orgConfigFile
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
		# add cerberus extra hosts
		bash scripts/addCerberusExtraHosts.sh

	elif [ "${ENTITY}" == "ext" ]; then
		# add all external organization extra hosts
		for file in external-orgs/*-data.json; do
			bash scripts/addExternalOrgExtraHosts.sh $file
		done

	elif [ "${ENTITY}" == "network" ]; then
		# add cerberus extra hosts
		bash scripts/addCerberusExtraHosts.sh

                # add all external organization extra hosts
                for file in external-orgs/*-data.json; do
                        bash scripts/addExternalOrgExtraHosts.sh $file
                done

	else
		# add external organization extra hosts
		orgConfigFile="external-orgs/${ENTITY}-data.json"

		bash scripts/addExternalOrgExtraHosts.sh $orgConfigFile
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
		# remove cerberus extra hosts
		bash scripts/removeCerberusExtraHosts.sh

	elif [ "${ENTITY}" == "ext" ]; then
		# remove all external organizations extra hosts
		for file in external-orgs/*-data.json; do
			bash scripts/removeExternalOrgExtraHosts.sh $file
		done

	elif [ "${ENTITY}" == "network" ]; then
                # remove cerberus extra hosts
                bash scripts/removeCerberusExtraHosts.sh

                # remove all external organizations extra hosts
                for file in external-orgs/*-data.json; do
                        bash scripts/removeExternalOrgExtraHosts.sh $file
                done

	else
		# remove external organization extra hosts
		orgConfigFile="external-orgs/${ENTITY}-data.json"

		bash scripts/removeExternalOrgExtraHosts $orgConfigFile
	fi

###################################################################
# Remote operations
# Following starts scripts on remote host machines and perform actions on behalf of organizations hosts

# ./sipher.sh add-s-env
elif [ "${MODE}" == "add-env-r" ]; then

	# check if entity value is provided
	if [ -z "$ENTITY" ]; then
		echo "Please provide entity name with '-e' option tag"
		printHelp
		exit 1
	fi

	if [ "${ENTITY}" == "cerb" ]; then
		# add Sipher environment data to cerberus network machines
		bash scripts/addSipherDataToCerberus.sh "env"

	elif [ "${ENTITY}" == "ext" ]; then
		# add Sipher environment data to all external organizations machines
		for file in external-orgs/*-data.json; do
			bash scripts/addSipherDataToExternalOrg.sh $file "env"
		done

	elif [ "${ENTITY}" == "network" ]; then
		# add Sipher environment data to cerberus network machines
                bash scripts/addSipherDataToCerberus.sh "env"

		# add Sipher environment data to all external organizations machines
                for file in external-orgs/*-data.json; do
                        bash scripts/addSipherDataToExternalOrg.sh $file "env"
                done

	else
		# add Sipher environment data to external organization machines
		orgConfigFile="external-orgs/${ENTITY}-data.json"

		bash scripts/addSipherDataToExternalOrg.sh $orgConfigFile "env"
	fi

elif [ "${MODE}" == "remove-env-r" ]; then
	
	# check if entity value is provided
        if [ -z "$ENTITY" ]; then
                echo "Please provide entity name with '-e' option tag"
                printHelp
                exit 1
        fi

        if [ "${ENTITY}" == "cerb" ]; then
                # remove Sipher environment data from cerberus network remote hosts
                bash scripts/removeSipherDataFromCerberus.sh "env"
	
	elif [ "${ENTITY}" == "ext" ]; then
		# remove Sipher environment data from external organizations remote hosts
		for file in external-orgs/*-data.json; do
			bash scripts/removeSipherDataFromExternalOrg.sh $file "env"
		done

	elif [ "${ENTITY}" == "network" ]; then
		 # remove Sipher environment data from cerberus network remote hosts
                bash scripts/removeSipherDataFromCerberus.sh "env"

		# remove Sipher environment data from external organizations remote hosts
                for file in external-orgs/*-data.json; do
                        bash scripts/removeSipherDataFromExternalOrg.sh $file "env"
                done

	else
		# remove Sipher environment data from specific organization remote hosts
		orgConfigFile="external-orgs/${ENTITY}-data.json"

		bash scripts/removeSipherDataFromExternalOrg.sh $orgConfigFile "env"		
	fi

elif [ "${MODE}" == "update-env-r" ]; then

	# check if entity value is provided
        if [ -z "$ENTITY" ]; then
                echo "Please provide entity name with '-e' option tag"
                printHelp
                exit 1
        fi

	if [ "${ENTITY}" == "cerb" ]; then
                # update Sipher environment data on cerberus network remote hosts
                bash scripts/removeSipherDataFromCerberus.sh "env"
		bash scripts/addSipherDataToCerberus.sh "env"

        elif [ "${ENTITY}" == "ext" ]; then
                # update Sipher environment data on external organizations remote hosts
                for file in external-orgs/*-data.json; do
                        bash scripts/removeSipherDataFromExternalOrg.sh $file "env"
			bash scripts/addSipherDataToExternalOrg.sh $file "env"
                done

        elif [ "${ENTITY}" == "network" ]; then
                 # update Sipher environment data on cerberus network remote hosts
                bash scripts/removeSipherDataFromCerberus.sh "env"

                # update Sipher environment data on external organizations remote hosts
                for file in external-orgs/*-data.json; do
                        bash scripts/removeSipherDataFromExternalOrg.sh $file "env"
			bash scripts/addSipherDataToExternalOrg.sh $file "env"
                done

        else
                # update Sipher environment data on specific organization remote hosts
                orgConfigFile="external-orgs/${ENTITY}-data.json"               

                bash scripts/removeSipherDataFromExternalOrg.sh $orgConfigFile "env"
		bash scripts/addSipherDataToExternalOrg.sh $file "env"           
        fi


elif [ "${MODE}" == "add-extra-hosts-r" ]; then

	# check if entity value is provided
        if [ -z "$ENTITY" ]; then
                echo "Please provide entity name with '-e' option tag"
                printHelp
                exit 1
        fi

	
        if [ "${ENTITY}" == "cerb" ]; then
                # add Sipher environment data to cerberus network machines
                bash scripts/addSipherDataToCerberus.sh "extrahosts"

        elif [ "${ENTITY}" == "ext" ]; then
                # add Sipher environment data to all external organizations machines
                for file in external-orgs/*-data.json; do
                        bash scripts/addSipherDataToExternalOrg.sh $file "extrahosts"
                done

        elif [ "${ENTITY}" == "network" ]; then
                # add Sipher environment data to cerberus network machines
                bash scripts/addSipherDataToCerberus.sh "extrahosts"

                # add Sipher environment data to all external organizations machines
                for file in external-orgs/*-data.json; do
                        bash scripts/addSipherDataToExternalOrg.sh $file "extrahosts"
                done

        else
                # add Sipher environment data to external organization machines
                orgConfigFile="external-orgs/${ENTITY}-data.json"

                bash scripts/addSipherDataToExternalOrg.sh $orgConfigFile "extrahosts"
        fi

elif [ "${MODE}" == "remove-extra-hosts-r" ]; then

        # check if entity value is provided
        if [ -z "$ENTITY" ]; then
                echo "Please provide entity name with '-e' option tag"
                printHelp
                exit 1
        fi

	# to be developed

elif [ "${MODE}" == "update-extra-hosts-r" ]; then

        # check if entity value is provided
        if [ -z "$ENTITY" ]; then
                echo "Please provide entity name with '-e' option tag"
                printHelp
                exit 1
        fi

	# to be developed

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

	bash scripts/startSipherContainers.sh



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

