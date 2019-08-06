#!/bin/bash

function addCerberusExtraHosts() {

	ARCH=$(uname -s | grep Darwin)
 	if [ "$ARCH" == "Darwin" ]; then
		OPTS="-it"
 	else
		OPTS="-i"
	fi

	source ~/.profile

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
		echo "ERROR: $CERBERUSORG_CONFIG_FILE file not found. Cannot proceed with parsing organizations hosts"
		exit 1
	fi

	osinstances=$(jq -r '.os[] | "\(.instances)"' $OS_CONFIG_FILE)
	cerberusOrgContainers=$(jq -r '.containers[]' $CERBERUSORG_CONFIG_FILE)


	cd sipher-config/
	sipherContainers=(anchorpr lead0pr lead1pr communicatepr cli)

	for container in "${sipherContainers[@]}"
	do
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
}

function addExternalOrganizationExtraHosts() {
	
	ORG_CONFIG_FILE=$1

	source ~/.profile

	orgLabel=$(jq -r '.label' $ORG_CONFIG_FILE)
	orgLabelStripped=$(echo $orgLabel | sed 's/"//g')

	orgContainers=$(jq -r '.containers[]' $ORG_CONFIG_FILE)

	cd sipher-config/
	sipherContainers=(anchorpr lead0pr lead1pr communicatepr cli)

	for container in "${sipherContainers[@]}"
	do
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
}

function loop() {
	cd network-config/

	osinstances=$(jq -r '.os[] | "\(.instances)"' cerberusntw-data.json)
	organizations=$(jq '.organizations' org-data.json)

	cd $CURRENT_DIR

	for organization in $(echo "${organizations}" | jq -r '.[] | @base64'); do
		_jq(){
			orgData=$(echo "$(echo ${organization} | base64 --decode | jq -r ${1})")
			name=$(echo "$(echo ${orgData} | jq -r ${2})")
			host=$(echo "$(echo ${orgData} | jq -r ${3})")
			orgHostUsername=$(echo "$(echo ${orgData} | jq -r ${4})")
			orgHostPassword=$(echo "$(echo ${orgData} | jq -r ${5})")

			nameVar="${name^^}_NAME"
			addEnvVariable $name "${name^^}_NAME" "${!nameVar}"

			hostVar="${name^^}_IP_HOST"
			addEnvVariable $host "${name^^}_IP_HOST" "${!hostVar}"
	
			hostUsernameVar="${name^^}_HOST_USERNAME"
			addEnvVariable $orgHostUsername "${name^^}_HOST_USERNAME" "${!hostUsernameVar}"

			hostPasswordVar="${name^^}_HOST_PASSWORD"
			addEnvVariable $orgHostPassword "${name^^}_HOST_PASSWORD" "${!hostPasswordVar}"
		}
		echo $(_jq '.org' '.name' '.host' '.username' '.password')
	done

	for organization in $(echo "${organizations}" | jq -r '.[] | @base64'); do
		_jq(){
			orgData=$(echo "$(echo ${organization} | base64 --decode | jq -r ${1})")
			host=$(echo "$(echo ${orgData} | jq -r ${2})")
			containers=$(echo "$(echo ${orgData} | jq -r ${3})")

			for row in $(echo "${containers}" | jq -r '.[] | @base64'); do
				_jq(){
					extraHost=$(echo "\"$(echo ${row} | base64 --decode | jq -r ${1}):${host}\"")
					yq write --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[+] $extraHost
				}
				echo $(_jq '.container')
			done
		}
		echo $(_jq '.org' '.host' '.containers')
	done
}


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
		echo "added ${value} in list of extra_hosts for $container"
	fi
}

