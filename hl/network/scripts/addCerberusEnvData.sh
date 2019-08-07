#!/bin/bash

function addEnvVariable() {
	newValue=$1
	varName=$2
	currentValue=$3

	if [ -z "$currentValue" ]; then
		echo "${varName}=${newValue}">>.env
		echo "### $varName obtained"
		echo ""
	elif [ "$currentValue" != "$newValue" ]; then
		unset $varName
		sed -i -e "/${varName}/d" .env

		echo "${varName}=${newValue}">>.env
		echo "### ${varName} value updated"
		echo ""
	else
		echo "${varName} already set"
		echo ""
	fi

	source .env
}

ARCH=$(uname -s | grep Darwin)
if [ "$ARCH" == "Darwin" ]; then
	OPTS="-it"
else
	OPTS="-i"
fi
  
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

source ~/.profile
source .env

osinstances=$(jq -r '.os[] | "\(.instances)"' $OS_CONFIG_FILE)

for osinstance in $(echo "${osinstances}" | jq -r '.[] | @base64'); do
	_jq(){
		# obtain new environment variables values
		osLabelValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${1})\"")
		osLabelValueStripped=$(echo $osLabelValue | sed 's/"//g')
		osLabelVar="${osLabelValueStripped^^}_LABEL"

		osContainerValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${2})\"")
		osContainerValueStripped=$(echo $osContainerValue | sed 's/"//g')
		osContainerVar="${osLabelValueStripped^^}_CONTAINER"
 
		osHostValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${3})\"")
		osHostValueStripped=$(echo $osHostValue | sed 's/"//g')
		osHostVar="${osLabelValueStripped^^}_HOST"

		osUsernameValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${4})\"")
		osUsernameValueStripped=$(echo $osUsernameValue | sed 's/"//g')
		osUsernameVar="${osLabelValueStripped^^}_USERNAME"

		osPasswordValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${5})\"")
		osPasswordValueStripped=$(echo $osPasswordValue | sed 's/"//g')
		osPasswordVar="${osLabelValueStripped^^}_PASSWORD"

		osPathValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${6})\"")
		osPathValueStripped=$(echo $osPathValue | sed 's/"//g')
		osPathVar="${osLabelValueStripped^^}_PATH"

		addEnvVariable $osLabelValueStripped "${osLabelValueStripped^^}_LABEL" "${!osLabelVar}"
		addEnvVariable $osContainerValueStripped "${osLabelValueStripped^^}_CONTAINER" "${!osContainerVar}"
		addEnvVariable $osHostValueStripped "${osLabelValueStripped^^}_HOST" "${!osHostVar}"
		addEnvVariable $osUsernameValueStripped "${osLabelValueStripped^^}_USERNAME" "${!osUsernameVar}"
		addEnvVariable $osPasswordValueStripped "${osLabelValueStripped^^}_PASSWORD" "${!osPasswordVar}"
		addEnvVariable $osPathValueStripped "${osLabelValueStripped^^}_PATH" "${!osPathVar}"
	}
	echo $(_jq '.label' '.container' '.host' '.username' '.password' '.path')
done

source .env

echo "### Cerberusntw Ordering service environment data successfully added to Sipher configuration"

orgLabelValue=$(jq -r '.label' $CERBERUSORG_CONFIG_FILE)
orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')
orgLabelVar="${orgLabelValueStripped^^}_LABEL"

# add organization label
addEnvVariable $orgLabelValueStripped "${orgLabelValueStripped^^}_LABEL" "${!orgLabelVar}"

orgContainers=$(jq -r '.containers[]' $CERBERUSORG_CONFIG_FILE)

for orgContainer in $(echo "${orgContainers}" | jq -r '. | @base64'); do
	_jq(){
		# obtain new environment variables values                       
		peerNameValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${1})\"")
		peerNameValueStripped=$(echo $peerNameValue | sed 's/"//g')
		peerNameVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_NAME"

		peerContainerValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${2})\"")
		peerContainerValueStripped=$(echo $peerContainerValue | sed 's/"//g')
		peerContainerVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_CONTAINER"
 
		peerHostValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${3})\"")
		peerHostValueStripped=$(echo $peerHostValue | sed 's/"//g')
		peerHostVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_HOST"

		peerUsernameValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${4})\"")
		peerUsernameValueStripped=$(echo $peerUsernameValue | sed 's/"//g')
		peerUsernameVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_USERNAME"

		peerPasswordValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${5})\"")
		peerPasswordValueStripped=$(echo $peerPasswordValue | sed 's/"//g')
		peerPasswordVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PASSWORD"

		peerPathValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${6})\"")
		peerPathValueStripped=$(echo $peerPathValue | sed 's/"//g')
		peerPathVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PATH"

		addEnvVariable $peerNameValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_NAME" "${!peerNameVar}"
		addEnvVariable $peerContainerValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_CONTAINER" "${!peerContainerVar}"
		addEnvVariable $peerHostValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_HOST" "${!peerHostVar}"
		addEnvVariable $peerUsernameValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_USERNAME" "${!peerUsernameVar}"
		addEnvVariable $peerPasswordValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PASSWORD" "${!peerPasswordVar}"
		addEnvVariable $peerPathValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PATH" "${!peerPathVar}"
	}
	echo $(_jq '.name' '.container' '.host' '.username' '.password' '.path')
done

echo "### Cerberus Network organization environment data successfully added to Sipher configuration"


