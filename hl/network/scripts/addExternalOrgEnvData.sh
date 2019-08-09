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

ORG_CONFIG_FILE=$1

ARCH=$(uname -s | grep Darwin)
if [ "$ARCH" == "Darwin" ]; then
        OPTS="-it"
else
        OPTS="-i"
fi

CURRENT_DIR=$PWD

if [ ! -f "$ORG_CONFIG_FILE" ]; then
        echo
        echo "ERROR: $ORG_CONFIG_FILE file not found. Cannot proceed with parsing network configuration"
        exit 1
fi

source .env
source ~/.profile

orgLabelValue=$(jq -r '.label' $ORG_CONFIG_FILE)
result=$?

if [ "$result" -ne 0 ]; then
        echo "ERROR: Format for $ORG_CONFIG_FILE does not match expected"
        exit 1
fi

orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')
orgLabelVar="${orgLabelValueStripped^^}_ORG_LABEL"

# add organization label
addEnvVariable $orgLabelValueStripped "${orgLabelValueStripped^^}_ORG_LABEL" "${!orgLabelVar}"

orgContainers=$(jq -r '.containers[]' $ORG_CONFIG_FILE)

for container in $(echo "${orgContainers}" | jq -r '. | @base64'); do
	_jq(){
		# obtaine new environment variables
		peerNameValue=$(echo "\"$(echo ${container} | base64 --decode | jq -r ${1})\"")
		peerNameValueStripped=$(echo $peerNameValue | sed 's/"//g')
		peerNameVar="${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_NAME"

		peerContainerValue=$(echo "\"$(echo ${container} | base64 --decode | jq -r ${2})\"")
		peerContainerValueStripped=$(echo $peerContainerValue | sed 's/"//g')
		peerContainerVar="${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_CONTAINER"

		peerHostValue=$(echo "\"$(echo ${container} | base64 --decode | jq -r ${3})\"")
		peerHostValueStripped=$(echo $peerHostValue | sed 's/"//g')
		peerHostVar="${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_HOST"

		peerUsernameValue=$(echo "\"$(echo ${container} | base64 --decode | jq -r ${4})\"")
		peerUsernameValueStripped=$(echo $peerUsernameValue | sed 's/"//g')
		peerUsernameVar="${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_USERNAME"

		peerPasswordValue=$(echo "\"$(echo ${container} | base64 --decode | jq -r ${5})\"")
		peerPasswordValueStripped=$(echo $peerPasswordValue | sed 's/"//g')
		peerPasswordVar="${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_PASSWORD"

		peerPathValue=$(echo "\"$(echo ${container} | base64 --decode | jq -r ${6})\"")
		peerPathValueStripped=$(echo $peerPathValue | sed 's/"//g')
		peerPathVar="${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_PATH"

		addEnvVariable $peerNameValueStripped "${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_NAME" "${!peerNameVar}"
		addEnvVariable $peerContainerValueStripped "${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_CONTAINER" "${!peerContainerVar}"
		addEnvVariable $peerHostValueStripped "${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_HOST" "${!peerHostVar}"
		addEnvVariable $peerUsernameValueStripped "${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_USERNAME" "${!peerUsernameVar}"
		addEnvVariable $peerPasswordValueStripped "${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_PASSWORD" "${!peerPasswordVar}"
		addEnvVariable $peerPathValueStripped "${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_PATH" "${!peerPathVar}"
	}
	echo $(_jq '.name' '.container' '.host' '.username' '.password' '.path')
done

echo
echo "### ${orgLabelValueStripped^} environment data has been successfully added"
echo

