#!/bin/bash
function removeOsEnvData() {

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
	
	source .env

	echo
	echo "### Cerberusntw Ordering service environment data successfully removed from Sipher configuration"
}

function removeCerberusOrgEnvData() {

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

	source .env

	orgLabelValue=$(jq -r '.label' $CERBERUSORG_CONFIG_FILE)
	orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')

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

}

function removeNetworkHosts() {

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
		extraHosts=$(yq r --tojson sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts)
		extraHostsParsed=$(echo ${extraHosts} | jq '. | to_entries[]')

		echo "Stopping container ${container}.sipher.cerberus.net ... "

		#docker stop "${container}.sipher.cerberus.net"
		#sleep 10

		echo
		echo "### Removing network hosts from ${container}.sipher.cerberus.net ..."

		if [ "$hosts" == null ]; then
			echo "No extra hosts to remove from container ${container}"

		else
			for extraHost in $(echo "${extraHostsParsed}" | jq -r '. | @base64'); do
				_jq(){
					key=$(echo "$(echo ${extraHost} | base64 --decode | jq -r ${1})")
					value=$(echo "$(echo ${extraHost} | base64 --decode | jq -r ${2})")

					valueStripped=$(echo $value | sed 's/"//g')
					valueContainer=$(echo $valueStripped | sed 's/:.*//')

					for osinstance in $(echo "${osinstances}" | jq -r '.[] | @base64'); do
						_jq(){
							osInstanceContainerValue=$(echo "$(echo ${osinstance} | base64 --decode | jq -r ${1})")
							osInstanceContainerValueStripped=$(echo $osInstanceContainerValue | sed 's/"//g')

							if [ "${osInstanceContainerValueStripped}" == "${valueContainer}" ]; then
								yq delete --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[${key}]
							fi
						}
						echo $(_jq '.container' '.host')
					done
				}
				echo $(_jq '.key' '.value')
			done

			for cerberusOrgContainer in $(echo "${cerberusOrgContainers}" | jq -r '. | @base64'); do
				_jq(){
					cerberusOrgContainerValue=$(echo "$(echo ${cerberusOrgContainer} | base64 --decode | jq -r ${1})")
					cerberusOrgContainerValueStripped=$(echo $cerberusOrgContainerValue | sed 's/"//g')

					for extraHost in $(echo "${extraHostsParsed}" | jq -r '. | @base64'); do
						_jq() {
							key=$(echo "$(echo ${extraHost} | base64 --decode | jq -r ${1})")
							value=$(echo "$(echo ${extraHost} | base64 --decode | jq -r ${2})")

							valueStripped=$(echo $value | sed 's/"//g')
							valueContainer=$(echo $valueStripped | sed 's/:.*//')

							if [ "${cerberusOrgContainerValueStripped}" == "${valueContainer}" ]; then
								yq delete --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[${key}]
							fi
						}
						echo $(_jq '.key' '.value')
					done
				}
				echo $(_jq '.container' '.host')
			done
		fi

		remainingHostsData=$(yq r --tojson sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts)
		remainingHosts=$(echo "${remainingHostsData}" | jq -r '.[]')

		if [ -z $remainingHosts ]; then
			# delete key
			yq delete --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts
		fi

		echo
		echo "Starting container ${container}.sipher.cerberus.net ..."
		
		#docker start "${container}.sipher.cerberus.net"
		#sleep 10
	done

	cd $CURRENT_DIR

	echo
	echo "### Network hosts successfully removed from Sipher configuration ###"
}

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


# not used
function removeExtraHost() {
	extraHosts=$1
	containerToRemove=$2
	sipherContainer=$3

	containerToRemoveStripped=$(echo $containerToRemove | sed 's/"//g')
	extraHostsParsed=$(echo ${extraHosts} | jq '. | to_entries[]')
	
	for extraHost in $(echo "${extraHostsParsed}" | jq -r '. | @base64'); do
		_jq() {
			key=$(echo "$(echo ${extraHost} | base64 --decode | jq -r ${1})")
			value=$(echo "$(echo ${extraHost} | base64 --decode | jq -r ${2})")
			valueStripped=$(echo $value | sed 's/"//g')
			valueContainer=$(echo $valueStripped | sed 's/:.*//')	

		#	echo $valueContainer
			#echo $containerStripped
			#echo '\n'
			if [ "$containerToRemoveStripped" == "$valueContainer" ]; then
				#echo $valueStripped
				yq delete --inplace sipher-org.yaml services["${sipherContainer}".sipher.cerberus.net].extra_hosts[${key}]
			fi
		
			#if [[ " ${extraHostsParsed[*]} " == *"$hostToRemove"* ]]; then

			#	if [[ "$value" == *"$hostToRemove"* ]]; then
			#		echo $hostToRemove
			#		echo '\n'

					#yq delete --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[${key}]
			#	else
			#		echo "${hostToRemove} is not in the list of extra hosts for ${container}"
			#	fi
			#fi
			#`echo "$hostToRemove removed from extra_hosts list in ${container}"
		}
		echo $(_jq '.key' '.value')
	done
}
