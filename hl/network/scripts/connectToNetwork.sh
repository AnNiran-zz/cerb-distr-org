#!/bin/bash
function connectToNetworkSipherOrg() {

	# call cli container
	# execute script for creating channel config update

	echo "echo from the new function"
}

function connectToNetworkCerberusOrg() {
 
	which sshpass

	if [ "$?" -ne 0 ]; then
		echo "sshpass tool not found"
		exit 1
	fi

	# check if configuration files are present on the remote host and deliver them if they are not  
	channelArtifactsFiles=(configtx.yaml crypto-config.yaml sipher-channel-artifacts.json)
	channelArtifactsLocation=/home/$CERBERUS_OS_USERNAME/server/go/src/cerberus-os/hl/network/external-orgs

	for file in "${channelArtifactsFiles[@]}"; do

		# check if channel artifacts have been delivered to network host
		if sshpass -p "${CERBERUS_OS_PASSWORD}" ssh $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP "cd $channelArtifactsLocation && test -e sipher-artifacts    /$file"; then
			echo "$file exists"
			echo "Proceeding with check"
		else
			echo "$file does not exist. Adding organization artifacts to Cerberus hosts"
			deliverOrgChannelArtifacts

			break
		fi
	done

	# proceed from here ...         

	# destination=/home/$CERBERUS_OS_USERNAME/server/go/src/cerberus-os/hl/network
	scriptLocation=/home/$CERBERUS_OS_USERNAME/server/go/src/cerberus-os/hl/network/cerberusntw.sh
	sshpass -p "${CERBERUS_OS_PASSWORD}" ssh $CERBERUS_OS_USERNAME@$CERBERUS_OS_IP "${scriptLocation} connectorg -n sipher -l ${CHANNELS_LIST}"
}


