#!/bin/bash

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

                #       echo $valueContainer
                        #echo $containerStripped
                        #echo '\n'
                        if [ "$containerToRemoveStripped" == "$valueContainer" ]; then
                                #echo $valueStripped
                                yq delete --inplace sipher-org.yaml services["${sipherContainer}".sipher.cerberus.net].extra_hosts[${key}]
                        fi

                        #if [[ " ${extraHostsParsed[*]} " == *"$hostToRemove"* ]]; then

                        #       if [[ "$value" == *"$hostToRemove"* ]]; then
                        #               echo $hostToRemove
                        #               echo '\n'

                                        #yq delete --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[${key}]
                        #       else
                        #               echo "${hostToRemove} is not in the list of extra hosts for ${container}"
                        #       fi
                        #fi
                        #`echo "$hostToRemove removed from extra_hosts list in ${container}"
                }
                echo $(_jq '.key' '.value')
        done
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
cerberusOrgContainers=$(jq -r '.containers[]' $CERBERUSORG_CONFIG_FILE)

cd sipher-config/
sipherContainers=(anchorpr lead0pr lead1pr communicatepr cli)

for container in "${sipherContainers[@]}"; do

	extraHosts=$(yq r --tojson sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts)
	extraHostsParsed=$(echo ${extraHosts} | jq '. | to_entries[]')

	if [ "$extraHosts" == null ]; then
		echo "No extra hosts to remove from container ${container}"

	else

		echo "Stopping container ${container}.sipher.cerberus.net ... "

        	#docker stop "${container}.sipher.cerberus.net"
        	#sleep 10

        	echo
        	echo "### Removing network hosts from ${container}.sipher.cerberus.net ..."

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

		remainingHostsData=$(yq r --tojson sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts)
		remainingHosts=$(echo "${remainingHostsData}" | jq -r '.[]')

		if [ -z "$remainingHosts" ]; then
			# delete key
			yq delete --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts
		fi

		echo
		echo "Starting container ${container}.sipher.cerberus.net ..."

		#docker start "${container}.sipher.cerberus.net"
		#sleep 10
	fi
done

cd $CURRENT_DIR

echo
echo "### Cerberus network organization and Ordering Service instances extra hosts successfully removed from Sipher configuration ###"
