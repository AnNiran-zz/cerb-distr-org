#!/bin/bash

function getArch() {
 
	ARCH=$(uname -s | grep Darwin)
	if [ "$ARCH" == "Darwin" ]; then
		OPTS="-it"
	else
		OPTS="-i"
	fi
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
	source ~/.profile

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


