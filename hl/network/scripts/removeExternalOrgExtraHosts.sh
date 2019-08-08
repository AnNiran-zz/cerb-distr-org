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

ORG_CONFIG_FILE=$1

if [ ! -f "$ORG_CONFIG_FILE" ]; then
        echo
        echo "ERROR: $ORG_CONFIG_FILE file not found. Cannot proceed with parsing network configuration"
        exit 1
fi

source .env
source ~/.profile

orgLabelValue=$(jq -r '.label' $ORG_CONFIG_FILE)
orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')

orgContainers=$(jq -r '.containers[]' $ORG_CONFIG_FILE)

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

		for orgContainer in $(echo "${orgContainers}" | jq -r '. | @base64'); do
			_jq(){
				orgContainerValue=$(echo "$(echo ${orgContainer} | base64 --decode | jq -r ${1})")
				orgContainerValueStripped=$(echo $orgContainer | sed 's/"//g')

				for extraHost in $(echo "${extraHostParsed}" | jq -r '. | @base64'); do
					_jq(){
						key=$(echo "$(echo ${extraHost} | base64 --decode | jq -r ${1})")
						value=$(echo "$(echo ${extraHost} | base64 --decode | jq -r ${2})")

						valueStripped=$(echo $value | sed 's/"//g')
						valueContainer=$(echo $valueStripped | sed 's/:.*//g')

						if [ "${orgContainerValueStripped}" == "${valueContainer}" ]; then
							yq delete --inplace sipher-org.yaml services["${container}".sipher.cerberus.net].extra_hosts[${key}]
						fi
					}
					echo $(_jq, '.key' '.value')
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
echo "### ${orgLabelValueStripped^} extra hosts has been removed from Sipher configuration files"

