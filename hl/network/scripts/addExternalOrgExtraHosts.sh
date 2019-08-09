#!/bin/bash

function addExtraHost() {
        extraHosts=$1 # existing extraHosts
        container=$2
        newHostContainer=$3
        newHost=$4

        extraHostsParsed=$(echo ${extraHosts} | jq '. | to_entries[]')

        if [[ " ${extraHostsParsed[*]} " == *"$newHostContainer"* ]]; then
                echo "$newHost already in list of extra hosts for $container"
        else
                yq write --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[+] $newHost
                echo "added ${extraHost} in list of extra_hosts for $container"
        fi
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

# check if external organization environment variables are set
orgLabelValue=$(jq -r '.label' $ORG_CONFIG_FILE)
result=$?

if [ "$result" -ne 0 ]; then
        echo "ERROR: Format for $ORG_CONFIG_FILE does not match expected"
        exit 1
fi

orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')
orgLabelVar="${orgLabelValueStripped^^}_ORG_LABEL"

if [ -z "${!orgLabelVar}" ]; then
	echo "Required organization environment data is missing. Obtaining ... "
	bash scripts/addExternalOrgEnvData.sh $ORG_CONFIG_FILE
	source .env
fi

orgContainers=$(jq -r '.containers[]' $ORG_CONFIG_FILE)

cd sipher-config/
sipherContainers=(anchorpr lead0pr lead1pr communicatepr cli)

for container in "${sipherContainers[@]}"; do

	hosts=$(yq r --tojson sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts)

	echo
	echo "### Adding ${orgLabelStripped^} extra hosts to Sipher configuration ... "

	if [ "$hosts" == null ]; then
		yq write --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[+] null

		for orgContainer in $(echo "${orgContainers}" | jq -r '. | @base64'); do
			_jq(){
				orgContainerValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${1})\"")
				orgContainerValueStripped=$(echo $orgContainerValue | sed 's/"//g')

				hostValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${2})\"")
				hostValueStripped=$(echo ${hostValue} | sed 's/"//g')

				extraHost="\"$orgContainerValueStripped:$hostValueStripped\""

				yq write --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[+] $extraHost
			}
			echo $(_jq '.container' '.host')
		done

		yq delete --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[0]
	else

		for orgContainer in $(echo "${orgContainers}" | jq -r '. | @base64'); do
			_jq(){
				orgContainerValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${1})\"")
				orgContainerValueStripped=$(echo $orgContainerValue | sed 's/"//g')

				hostValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${2})\"")
				hostValueStripped=$(echo ${hostValue} | sed 's/"//g')

                        extraHost="\"$orgContainerValueStripped:$hostValueStripped\""

			addExtraHost $hosts $container $orgContainerValueStripped $extraHost
			}
			echo $(_jq '.container' '.host')
		done
	fi
done

cd $CURRENT_DIR

echo
echo "### ${orgLabelStripped^} external hosts successfully added to Sipher configuration ###"

