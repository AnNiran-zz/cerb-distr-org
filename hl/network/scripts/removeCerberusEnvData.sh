#!/bin/bash

function removeEnvVariable() {
        varName=$1
        currentValue=$2

        if [ -z "$currentValue" ]; then
                echo "$varName is not present"
        else
                unset $varName
                sed -i -e "/${varName}/d" .env
                echo "$varName deleted"
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
		osLabelValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${1})\"")
		osLabelValueStripped=$(echo $osLabelValue | sed 's/"//g')

		osLabelVar="${osLabelValueStripped^^}_LABEL"
		osContainerVar="${osLabelValueStripped^^}_CONTAINER"
		osHostVar="${osLabelValueStripped^^}_HOST"
		osUsernameVar="${osLabelValueStripped^^}_USERNAME"
		osPasswordVar="${osLabelValueStripped^^}_PASSWORD"
		osPathVar="${osLabelValueStripped^^}_PATH"

		removeEnvVariable "${osLabelValueStripped^^}_LABEL" "${!osLabelVar}"
		removeEnvVariable "${osLabelValueStripped^^}_CONTAINER" "${!osContainerVar}"
		removeEnvVariable "${osLabelValueStripped^^}_HOST" "${!osHostVar}"
		removeEnvVariable "${osLabelValueStripped^^}_USERNAME" "${!osUsernameVar}"
		removeEnvVariable "${osLabelValueStripped^^}_PASSWORD" "${!osPasswordVar}"
		removeEnvVariable "${osLabelValueStripped^^}_PATH" "${!osPathVar}"
	}
	echo $(_jq '.label')
done

echo
echo "### Cerberusntw Ordering service environment data successfully removed from Sipher configuration"


orgLabelValue=$(jq -r '.label' $CERBERUSORG_CONFIG_FILE)
orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')
orgLabelVar="${orgLabelValueStripped^^}_LABEL"

# remove label
removeEnvVariable "${orgLabelValueStripped^^}_LABEL" "${!orgLabelVar}"

orgContainers=$(jq -r '.containers[]' $CERBERUSORG_CONFIG_FILE)

for orgContainer in $(echo "${orgContainers}" | jq -r '. | @base64'); do
	_jq(){
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

		removeEnvVariable "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_NAME" "${!peerNameVar}"
		removeEnvVariable "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_CONTAINER" "${!peerContainerVar}"
		removeEnvVariable "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_HOST" "${!peerHostVar}"
		removeEnvVariable "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_USERNAME" "${!peerUsernameVar}"
		removeEnvVariable "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PASSWORD" "${!peerPasswordVar}"
		removeEnvVariable "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PATH" "${!peerPathVar}"
	}
	echo $(_jq '.name' '.container' '.host' '.username' '.password' '.path')
done

echo "#### Cerberusntw CerberusOrg environment data successfully removed from Sipher configuration"

