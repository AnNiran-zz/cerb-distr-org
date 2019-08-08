#!/bin/bash

ORG_CONFIG_FILE=$1
dataType=$2

if [ "${dataType}" != "env" ] && [ "${dataType}" != "extrahosts" ]; then
        echo "Unknown data type request"
        echo $dataType
        exit 1
fi

ARCH=$(uname -s | grep Darwin)
if [ "$ARCH" == "Darwin" ]; then
        OPTS="-it"
else
        OPTS="-i"
fi

CURRENT_DIR=$PWD

if [ ! -f "$ORG_CONFIG_FILE" ]; then
        echo
        echo "ERROR: $ORG_CONFIG_FILE file not found. Cannot proceed with parsing new organization configuration"
        exit 1
fi

SIPHER_CONFIG_FILE=sipher-data.json

if [ ! -f "sipher-config/$SIPHER_CONFIG_FILE" ]; then
        echo "ERROR: Sipher configuration file is not present. Cannot proceed with pasrind network data"
        exit 1
fi

source .env
source ~/.profile

# check if environment variables for the external organization are set

orgLabelValue=$(jq -r '.label' $ORG_CONFIG_FILE)
result=$?

if [ "$result" -ne 0 ]; then
        echo "ERROR: Format for $ORG_CONFIG_FILE does not match expected"
        exit 1
fi

orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')
orgLabelVar="${orgLabelValueStripped^^}_LABEL"

if [ -z "${!orgLabelVar}" ]; then
        echo "Required organization environment data is missing. Obtaining ... "
        bash scripts/addExternalOrgEnvData.sh $ORG_CONFIG_FILE
        source .env
fi

orgContainers=$(jq -r '.containers[]' $ORG_CONFIG_FILE)
result=$?

if [ "$result" -ne 0 ]; then
        echo "ERROR: Format for $ORG_CONFIG_FILE does not match expected"
        exit 1
fi

for orgContainer in $(echo "${orgContainers}" | jq -r '. | @base64'); do
        _jq(){
                peerNameValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${1})\"")
                peerNameValueStripped=$(echo $peerNameValue | sed 's/"//g')
                peerNameVar="${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_NAME"

                peerHostVar="${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_HOST"
                peerUsernameVar="${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_USERNAME"
                peerPasswordVar="${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_PASSWORD"
                peerPathVar="${orgLabelValueStripped^^}_ORG_${peerNameValueStripped^^}_PATH"

                # check if configuration file is present on the host machine
                sshpass -p "${!peerPasswordVar}" ssh ${!peerUsernameVar}@${!peerHostVar} "test -e ${!peerPathVar}hl/network/external-orgs/sipher-data.json"
                result=$?
                echo $result

                if [ $result -ne 0 ]; then
                        sshpass -p "${!peerPasswordVar}" scp sipher-config/$SIPHER_CONFIG_FILE ${!peerUsernameVar}@${!peerHostVar}:${!peerPathVar}hl/network/external-orgs

                        if [ "$?" -ne 0 ]; then
                                echo "ERROR:Cannot copy Sipher configuration file to ${!peerHostVar} machine"
                                exit 1
                        fi

                        echo
                        echo "Sipher configuration file copied successfully to ${!peerHostVar} machine"
                        echo
                else
                        echo
                        echo "Sipher configuration file is already present on ${!peerHostVar} machine"
                        echo
                fi

                # start remote script
                if [ "${dataType}" == "env" ]; then
                        sshpass -p "${!peerPasswordVar}" ssh ${!peerUsernameVar}@${!peerHostVar} "cd ${!peerPathVar}hl/network && bash scripts/addOrgEnvData.sh external-orgs/sipher-data.json"
                        result=$?
                        echo $result

                        if [ $result -ne 0 ]; then
                                echo "ERROR: Sipher environment data is not added to environment on ${!peerHostVar} machine"
                                exit 1
                        fi

                        echo
                        echo "Sipher data has been successfully added to environment on ${!peerHostMachine} machine"
                        echo
                fi
        }
        echo $(_jq '.name')
done
