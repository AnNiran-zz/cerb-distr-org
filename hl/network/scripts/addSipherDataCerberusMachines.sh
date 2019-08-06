#!/bin/bash

ARCH=$(uname -s | grep Darwin)
if [ "$ARCH" == "Darwin" ]; then
	OPTS="-it"
else
	OPTS="-i"
fi

CURRENT_DIR=$PWD

which sshpass
if [ "$?" -ne 0 ]; then
	echo "sshpass tool not found"
 	exit 1
 fi

# check if confoguration files are present on the host machine
OS_CONFIG_FILE=network-config/os-data.json
CERBERUSORG_CONFIG_FILE=network-config/cerberusorg-data.json

SIPHER_CONFIG_FILE=sipher-config/sipher-data.json

osinstances=$(jq -r '.os[] | "\(.instances)"' $OS_CONFIG_FILE)

for osinstance in $(echo "${osinstances}" | jq -r '.[] | @base64'); do
	_jq(){
		osLabelValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${1})\"")
		osLabelValueStripped=$(echo $osLabelValue | sed 's/"//g')
		osLabelVar="${osLabelValueStripped^^}_LABEL"

		osHostValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${2})\"")
		osHostValueStripped=$(echo $osHostValue | sed 's/"//g')
		osHostVar="${osLabelValueStripped^^}_HOST"

		osUsernameValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${3})\"")
		osUsernameValueStripped=$(echo $osUsernameValue | sed 's/"//g')
		osUsernameVar="${osLabelValueStripped^^}_USERNAME"

		osPasswordValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${4})\"")
		osPasswordValueStripped=$(echo $osPasswordValue | sed 's/"//g')
		osPasswordVar="${osLabelValueStripped^^}_PASSWORD"

		osPathValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${5})\"")
		osPathValueStripped=$(echo $osPathValue | sed 's/"//g')
		osPathVar="${osLabelValueStripped^^}_PATH"

		sshpass -p "${!osPasswordVar}" ssh ${!osUsernameVar}@${!osHostVar} "test -e ${!osPathVar}hl/network/external-orgs/sipher-data.json"
		result=$?
		echo $result

		if [ $result -ne 0 ]; then
			sshpass -p "${!osPasswordVar}" scp $SIPHER_CONFIG_FILE ${!osUsernameVar}@${!osHostVar}:${!osPathVar}hl/network/external-orgs

			if [ "$?" -ne 0 ]; then
				echo "ERROR: Cannot copy ${SIPHER_CONFIG_FILE} to ${!osHostVar} remote host"
				exit 1
			fi

			echo
			echo "$SIPHER_CONFIG_FILE copied to ${!osHostVar}"
			echo
		else
			echo
			echo "$SIPHER_CONFIG_FILE is already present on ${osHostVar} remote machine"
			echo
		fi
	}
	echo $(_jq '.label' '.host' '.username' '.password' '.path')
done

orgLabelValue=$(jq -r '.label' $CERBERUSORG_CONFIG_FILE)
orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')

cerberusOrgContainers=$(jq -r '.containers[]' $CERBERUSORG_CONFIG_FILE)

for orgContainer in $(echo "${cerberusOrgContainers}" | jq -r '. | @base64'); do
	_jq(){
		peerNameValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${1})\"")
		peerNameValueStripped=$(echo $peerNameValue | sed 's/"//g')
		peerNameVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_NAME"

		peerHostValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${2})\"")
		peerHostValueStripped=$(echo $peerHostValue | sed 's/"//g')
		peerHostVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_HOST"

		peerUsernameValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${3})\"")
		peerUsernameValueStripped=$(echo $peerUsernameValue | sed 's/"//g')
		peerUsernameVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_USERNAME"

		peerPasswordValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${4})\"")
		peerPasswordValueStripped=$(echo $peerPasswordValue | sed 's/"//g')
		peerPasswordVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PASSWORD"

		peerPathValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${5})\"")
		peerPathValueStripped=$(echo $peerPathValue | sed 's/"//g')
		peerPathVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PATH"

		sshpass -p "${!peerPasswordVar}" ssh ${!peerUsernameVar}@${!peerHostVar} "test -e ${!peerPathVar}hl/network/external-orgs/sipher-data.json"
		result=$?
		echo $result

		if [ "$result" -ne 0 ]; then
			sshpass -p "${!peerPasswordVar}" scp $SIPHER_CONFIG_FILE ${!peerUsernameVar}@${!peerHostVar}:${!peerPathVar}hl/network/external-orgs

			if [ "$?" -ne 0 ]; then
				echo "ERROR: Cannot copy ${SIPHER_CONFIG_FILE} to ${!peerHostVar} remote host"
				exit 1
			fi

			echo
			echo "$SIPHER_CONFIG_FILE copied to ${!peerHostVar}"
			echo
		else
			echo
			echo "$SIPHER_CONFIG_FILE is already present on ${peerHostVar} remote machine"
			echo
		fi
	}
	echo $(_jq '.name' '.host' '.username' '.password' '.path')
done


function addSipherEnvToCerberusMachines() {

	which sshpass
	if [ "$?" -ne 0 ]; then
		echo "sshpass tool not found"
		exit 1
	fi

	# check if confoguration files are present on the host machine
	OS_CONFIG_FILE=network-config/os-data.json
	CERBERUSORG_CONFIG_FILE=network-config/cerberusorg-data.json

	osinstances=$(jq -r '.os[] | "\(.instances)"' $OS_CONFIG_FILE)

	for osinstance in $(echo "${osinstances}" | jq -r '.[] | @base64'); do
		_jq(){
			osLabelValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${1})\"")
			osLabelValueStripped=$(echo $osLabelValue | sed 's/"//g')
			osLabelVar="${osLabelValueStripped^^}_LABEL"

			osHostValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${2})\"")
			osHostValueStripped=$(echo $osHostValue | sed 's/"//g')
			osHostVar="${osLabelValueStripped^^}_HOST"

			osUsernameValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${3})\"")
			osUsernameValueStripped=$(echo $osUsernameValue | sed 's/"//g')
			osUsernameVar="${osLabelValueStripped^^}_USERNAME"

			osPasswordValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${4})\"")
			osPasswordValueStripped=$(echo $osPasswordValue | sed 's/"//g')
			osPasswordVar="${osLabelValueStripped^^}_PASSWORD"

			osPathValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${5})\"")
			osPathValueStripped=$(echo $osPathValue | sed 's/"//g')
			osPathVar="${osLabelValueStripped^^}_PATH"

			#sshpass -p "${!osPasswordVar}" ssh ${!osUsernameVar}@${!osHostVar} cd ${!osPathVar}hl/network && ./operatecntw.sh add-org-env -o sipher
			#result=$?
			#echo $result

			#if [ $result -ne 0 ]; then
			#	echo "ERROR: Cannot add Sipher environment variables to ${!osHostVar} remote host"
			#	exit 1
			#	fi

			#echo
			#echo "Sipher environment data added on ${osHostVar} remote machine"
			#echo
		}
		echo $(_jq '.name' '.host' '.username' '.password' '.path')
	done
        
	cerberusOrgContainers=$(jq -r '.containers[]' $CERBERUSORG_CONFIG_FILE)

	orgLabelValue=$(jq -r '.label' $CERBERUSORG_CONFIG_FILE)
	orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')

	for orgContainer in $(echo "${cerberusOrgContainers}" | jq -r '. | @base64'); do
		_jq(){
			peerNameValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${1})\"")
			peerNameValueStripped=$(echo $peerNameValue | sed 's/"//g')
			peerNameVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_NAME"

			peerHostValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${2})\"")
			peerHostValueStripped=$(echo $peerHostValue | sed 's/"//g')
			peerHostVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_HOST"

			peerUsernameValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${3})\"")
			peerUsernameValueStripped=$(echo $peerUsernameValue | sed 's/"//g')
			peerUsernameVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_USERNAME"

			peerPasswordValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${4})\"")
			peerPasswordValueStripped=$(echo $peerPasswordValue | sed 's/"//g')
			peerPasswordVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PASSWORD"

			peerPathValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${5})\"")
			peerPathValueStripped=$(echo $peerPathValue | sed 's/"//g')
			peerPathVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PATH"

			echo ${!peerPasswordVar}

			sshpass -p "${!peerPasswordVar}" ssh ${!peerUsernameVar}@${!peerHostVar} "cd ${!peerPathVar}hl/network && ./scripts/addOrgEnvData.sh sipher"
			result=$?	
			echo $result

			#if [ "$result" -ne 0 ]; then
			#	echo "ERROR: Cannot add Sipher environment variables to ${!peerHostVar} remote host"
			#	exit 1

			#else
			#	echo
			#	echo "Sipher environment data added on ${peerHostVar} remote machine"	
			#	echo
			#fi	
		}
		echo $(_jq '.name' '.host' '.username' '.password' '.path')
	done
}

