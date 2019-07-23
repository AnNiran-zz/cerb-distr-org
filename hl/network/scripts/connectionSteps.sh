#!/bin/bash

function printConnectionSteps() {


	echo "####################################################################################################################"
	echo "### Connection configuration steps for Sipher ###"
	echo "####################################################################################################################"
	echo "NOTE: In case of any changes made to 'sipher-config/sipher-data.json' file - all steps for establishing connection must be run again from the beginning"
	echo
	echo
	echo
	echo "#### Connect Sipher organization to Cerberus Network step by step: ###"
	echo
	echo "************************************************************"
	echo "./sipher.sh generate"
	echo "Generating certificates and genesis block"
	echo
	echo "Generate organization crypto materials for all peers set in crypto-config.yaml file"
	echo "Generates genesis.block file"
	echo "Copies ordering service entity certificates locally in crypto-config/ folder"
	echo
	echo
	echo "***********************************************************"
	echo "./sipher.sh add-network-env"
	echo "Setting network environment variables"
	echo
	echo "Requires 'network-config/os-data.json' and 'network-config/cerberusorg-data.json' files to be present"
	echo "Reads cerberus ordering services and cerberus organization host information - host address, username, password, network name and label"
	echo "and adds it to .env file as environment variables"
	echo "Data is further used for remote hosts connections and information exchange"
	echo "This initial step is required in order to all further checks and settings to be run successfully"
	echo
	echo
	echo "***********************************************************" 
	echo "./sipher.sh add-sipher-env-to-network"
	echo "Adding Sipher environment data to network remotely"
	echo
	echo "Requires sipher-data.json file to be present on remote host machine inside <cerberus-network-path>/hl/network/external-orgs"
	echo "Checks if the configuration file is present remotely, if not - delivers it from 'sipher-config/' local folder"
	echo "Runs a remote script that adds Sipher host, username, password, name and label information to remote machine configuration files"
	echo "This setting is required for all further settings and connections from Cerberus network host machines to Sipher"
	echo
	echo
	echo "***********************************************************"
	echo "./sipher.sh add-network-hosts"
	echo "Adding Cerberus OS and organization hosts to Sipher containers"
	echo
	echo "Checks if required environment values for network access are set and addsnetwork hosts to Sipher yaml configuration files"
	echo
	echo
	echo "***********************************************************"
	echo "./sipher.sh add-inherent-hosts-to-network"
	echo "Adding Sipher hosts to Cerberus OS and organization containers configuration"
	echo 
	echo "Checks if required sipher-data.json file is present on dedicated remote machine and delivers it if missing"
	echo "Adds Sipher hosts addresses to Cerberus Ordering Service and organization container configuration files"
	echo
	echo
	echo "***********************************************************"
	echo "./sipher.sh connect-to-channel -l <channel-name>"
	echo "Connecting Sipher to network channel"
	echo
	echo
	echo "Requires 'channel-artifacts/sipher-channel-artifacts.json' file to be present locally"
	echo "If the file is not generated the function execution stops and returns a message to generate crypto materials and begin connection process again"
	echo "Generating crypto materials and certificates is required as a first step of the process of bringing Sipher organization up and connecting it to Cerberus network"
	echo "These materials are used in Sipher hosts communication with other network entities and generating them more than once during the connection establishing process"
	echo "may result in errors in authenticating organization peers and revoking memberships"
	echo
	echo "Checks if Sipher configuration files: configtx.yaml, crypto-config.yaml and shipher-channel-artifacts.json are present on the remote host"
	echo "If they are not - delivers them before proceeding"
	echo
	echo 
	
	echo
	echo "Channel name/names must be provided with an option tag -l; accepted names are: 'pers', 'inst' and 'int'"
	echo "For more than one channel, names must be provided separated with commas and without spaces. Example:"
	echo "./sipher.sh connect-to-channel -l pers,inst"
	echo
	echo
	echo "************************************************************"

}
