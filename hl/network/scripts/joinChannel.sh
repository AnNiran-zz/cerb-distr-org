#!/bin/bash

echo
echo " ========= Connect Sipher to Cerberus Network channels ========="
echo

PERSON_ACCOUNTS_CHANNEL=$1
INSTITUTION_ACCOUNTS_CHANNEL=$2
INTEGRATION_ACCOUNTS_CHANNELS=$3
channelConnection=$4

. scripts/utils.sh

if [ "${channelOption}" == "person" ]; then
	echo "Fetching channel config block for Person Accounts channel from orderer ..."

	

elif [ "${channelOption}" == "institution" ]; then 
	echo "Fetching channel config block for Institution Accounts channel from orderer ..."


elif [ "${channelOption}" == "integration" ]; then
	echo "Fetching channel config block for Integration Accounts channel from orderer ..."


elif [ "${channelOption}" == "all" ]; then
	echo "Fetching channel config block for Person Accounts channel from orderer ..."



	echo "Fetching channel config block for Institution Accounts channel from orderer ..."



	echo "Fetching channel config block for Integration Accounts channel from orderer ..."



else
	echo "Unknown channel connection options"
	exit 1
fi

