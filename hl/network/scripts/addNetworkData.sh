#!/bin/bash
function addOsEnvData() {

	# read network data inside network-config/ folder
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

			# add label
			addEnvVariable $osLabelValueStripped "${osLabelValueStripped^^}_LABEL" "${!osLabelVar}"

			# add container
			addEnvVariable $osContainerValueStripped "${osLabelValueStripped^^}_CONTAINER" "${!osContainerVar}"
	
			# add host
			addEnvVariable $osHostValueStripped "${osLabelValueStripped^^}_HOST" "${!osHostVar}"

			# add username
			addEnvVariable $osUsernameValueStripped "${osLabelValueStripped^^}_USERNAME" "${!osUsernameVar}"

			# add password
			addEnvVariable $osPasswordValueStripped "${osLabelValueStripped^^}_PASSWORD" "${!osPasswordVar}"

			# add path
			addEnvVariable $osPathValueStripped "${osLabelValueStripped^^}_PATH" "${!osPathVar}"

		}
		echo $(_jq '.label' '.container' '.host' '.username' '.password' '.path')

	done

	source .env

	echo "### Cerberusntw Ordering service environment data successfully added to Sipher configuration"
}

function addCerberusOrgEnvData() {

	# read network data inside network-config/ folder
	ARCH=$(uname -s | grep Darwin)
	if [ "$ARCH" == "Darwin" ]; then
		OPTS="-it"
	else
		OPTS="-i"
	fi

	CURRENT_DIR=$PWD

	CERBERUSORG_CONFIG_FILE=network-config/cerberusorg-data.json
	if [ ! -f "$CERBERUSORG_CONFIG_FILE" ]; then
		echo
		echo "ERROR: $CERBERUSORG_CONFIG_FILE file not found. Cannot proceed with parsing network configuration."
		exit 1
	fi

	orgLabelValue=$(jq -r '.label' $CERBERUSORG_CONFIG_FILE)
	orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')

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
			

			source .env

			# add label
			addEnvVariable $peerNameValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_NAME" "${!peerNameVar}"

			# add container
			addEnvVariable $peerContainerValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_CONTAINER" "${!peerContainerVar}"

			# add host
			addEnvVariable $peerHostValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_HOST" "${!peerHostVar}"

			# add username
			addEnvVariable $peerUsernameValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_USERNAME" "${!peerUsernameVar}"

			# add password
			addEnvVariable $peerPasswordValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PASSWORD" "${!peerPasswordVar}"

			# add path
			addEnvVariable $peerPathValueStripped "${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PATH" "${!peerPathVar}"

			source .env
		}
		echo $(_jq '.name' '.container' '.host' '.username' '.password' '.path')
	done

	echo "### Cerberusntw CerberusOrg environment data successfully added to Sipher configuration"
}

function addNetworkHosts() {

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
	echo "### External hosts successfully added to Sipher ###"
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

