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

# check if cerberus environment variables are set
for osinstance in $(echo "${osinstances}" | jq -r '.[] | @base64'); do
	_jq(){
		# check if os label environment variable is set
		osLabelValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${1})\"")
		osLabelValueStripped=$(echo $osLabelValue | sed 's/"//g')
		osLabelVar="${osLabelValueStripped^^}_LABEL"

		if [ -z "${!osLabelVar}" ]; then
			echo "Required network environment data is not present. Obtaining ... "
			bash scripts/addCerberusEnvData.sh
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
	bash scripts/addCerberusEnvData.sh
	source .env
fi

cerberusOrgContainers=$(jq -r '.containers[]' $CERBERUSORG_CONFIG_FILE)

cd sipher-config/
sipherContainers=(anchorpr lead0pr lead1pr communicatepr cli)

for container in "${sipherContainers[@]}"; do
                
	hosts=$(yq r --tojson sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts)

	echo
	echo "### Adding network hosts to ${container}.sipher.cerberus.net ..."

	if [ "$hosts" == null ]; then
		yq write --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[+] null

		for osinstance in $(echo "${osinstances}" | jq -r '.[] | @base64'); do
			_jq(){
				containerValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${1})\"")
				containerValueStripped=$(echo $containerValue | sed 's/"//g')

				hostValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${2})\"")
				hostValueStripped=$(echo ${hostValue} | sed 's/"//g')

				extraHost="\"$containerValueStripped:$hostValueStripped\""

				yq write --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[+] $extraHost
			}
			echo $(_jq '.container' '.host')
		done

		for row in $(echo "${cerberusOrgContainers}" | jq -r '. | @base64'); do
			_jq(){
				containerValue=$(echo "\"$(echo ${row} | base64 --decode | jq -r ${1})\"")
				containerValueStripped=$(echo $containerValue | sed 's/"//g')

				hostValue=$(echo "\"$(echo ${row} | base64 --decode | jq -r ${2})\"")
				hostValueStripped=$(echo $hostValue | sed 's/"//g')

				extraHost="\"$containerValueStripped:$hostValueStripped\""
				yq write --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[+] $extraHost
			}
			echo $(_jq '.container' '.host')
		done

		yq delete --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[0]

	else
		for osinstance in $(echo "${osinstances}" | jq -r '.[] | @base64'); do
			_jq(){
				containerValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${1})\"")
				containerValueStripped=$(echo $containerValue | sed 's/"//g')

				hostValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${2})\"")
				hostValueStripped=$(echo $hostValue | sed 's/"//g')

				extraHost="\"$containerValueStripped:$hostValueStripped\""

				addExtraHost $hosts $container $containerValueStripped $extraHost
 				#yq write --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[+] $extraHost
			}
			echo $(_jq '.container' '.host')
		done

		for row in $(echo "${cerberusOrgContainers}" | jq -r '. | @base64'); do
			_jq(){
				containerValue=$(echo "$(echo ${row} | base64 --decode | jq -r ${1})")
				containerValueStripped=$(echo $containerValue | sed 's/"//g')

				hostValue=$(echo "\"$(echo ${row} | base64 --decode | jq -r ${2})\"")
				hostValueStripped=$(echo $hostValue | sed 's/"//g')

				extraHost="\"$containerValueStripped:$hostValueStripped\""
			
				addExtraHost $hosts $container $containerValueStripped $extraHost
			}
			echo $(_jq '.container' '.host')
		done
	fi
done

cd $CURRENT_DIR

echo
echo "### Cerberus network organization and Orsering Service instances external hosts successfully added to Sipher configuration ###"

