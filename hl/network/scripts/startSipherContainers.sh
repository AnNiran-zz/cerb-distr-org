#!/bin/bash

# This file manages containers starting depending on their host machines
currentHost="155.138.144.24"
orgMainPeers=(anchorpr lead0pr lead1pr communicatepr execute0pr execute1pr fallaback0pr fallback1pr)

orgConfigFile=sipher-config/sipher-data.json

ARCH=$(uname -s | grep Darwin)
if [ "$ARCH" == "Darwin" ]; then
        OPTS="-it"
else
        OPTS="-i"
fi

CURRENT_DIR=$PWD

if [ ! -f "$orgConfigFile" ]; then
        echo
        echo "ERROR: $orgConfigFile file not found. Cannot proceed with parsing network configuration"
        exit 1
fi

source .env
source ~/.profile

orgContainersHosts=$(jq -r '.containers[]' $orgConfigFile)

for container in $(echo "${orgContainersHosts}" | jq -r '. | @base64'); do
	_jq(){
		name=$(echo "$(echo ${container} | base64 --decode | jq -r ${1})")
		containerName=$(echo "$(echo ${container} | base64 --decode | jq -r ${2})")
		host=$(echo "$(echo ${container} | base64 --decode | jq -r ${3})")
		username=$(echo "$(echo ${container} | base64 --decode | jq -r ${4})")
		password=$(echo "$(echo ${container} | base64 --decode | jq -r ${5})")
		path=$(echo "$(echo ${container} | base64 --decode | jq -r ${6})")

		echo $currentHost
		echo $host
		# check if my current hosts is the same as any of the other peers, so I will start composite cli container
		# otherwise - start my own cli
		if [ "$host" == "$currentHost" ]; then
			# start cli.sipher.cerberus.net container
		else
			# start separate cli container
		fi
	

	}
	echo $(_jq '.name' '.container' '.host' '.username' '.password' '.path')
done
