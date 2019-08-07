#!/bin/bash

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


