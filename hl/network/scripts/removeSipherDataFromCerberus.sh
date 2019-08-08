#!/bin/bash
dataType=$1

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

SIPHER_CONFIG_FILE=sipher-data.json

if [ ! -f "sipher-config/$SIPHER_CONFIG_FILE" ]; then
        echo "ERROR: Sipher configuration file is not present. Cannot proceed with pasrind network data"
        exit 1
fi

source ~/.profile
source .env

orgLabelValue=$(jq -r '.label' $CERBERUSORG_CONFIG_FILE)
result=$?

if [ "$result" -ne 0 ]; then
        echo "ERROR: Format for $CERBERUSORG_CONFIG_FILE does not match expected"
        exit 1
fi

orgLabelValueStripped=$(echo $orgLabelValue | sed 's/"//g')
orgLabelVar="${orgLabelValueStripped^^}_LABEL"

if [ -z "${!orgLabelVar}" ]; then
        echo "Required organization environment data is missing. Obtaining ... "
        bash scripts/addCerberusEnvData.sh
        source .env
fi

which sshpass
if [ "$?" -ne 0 ]; then
        echo "sshpass tool not found"
        exit 1
fi

osinstances=$(jq -r '.os[] | "\(.instances)"' $OS_CONFIG_FILE)
result=$?

if [ "$result" -ne 0 ]; then
        echo "ERROR: Format for $OS_CONFIG_FILE does not match expected"
        exit 1
fi

for osinstance in $(echo "${osinstances}" | jq -r '.[] | @base64'); do
        _jq(){
                # obtain new environment variables values
                osLabelValue=$(echo "\"$(echo ${osinstance} | base64 --decode | jq -r ${1})\"")
                osLabelValueStripped=$(echo $osLabelValue | sed 's/"//g')

                osHostVar="${osLabelValueStripped^^}_HOST"
                osUsernameVar="${osLabelValueStripped^^}_USERNAME"
                osPasswordVar="${osLabelValueStripped^^}_PASSWORD"
                osPathVar="${osLabelValueStripped^^}_PATH"

                # start remote script
                if [ "${dataType}" == "env" ]; then
                        sshpass -p "${!osPasswordVar}" ssh ${!osUsernameVar}@${!osHostVar} "cd ${!osPathVar}hl/network && bash scripts/removeOrgEnvData.sh external-orgs/sipher-data.json"
                        result=$?
                        echo $result

                        if [ $result -ne 0 ]; then
                                echo "ERROR: Sipher environment data is not added on ${!osHostVar} machine"
                                exit 1
                        fi

                        echo
                        echo "Sipher environment data has been successfully added on ${!osHostVar} remote machine"
                fi
        }
        echo $(_jq '.label')
done

orgContainers=$(jq -r '.containers[]' $CERBERUSORG_CONFIG_FILE)

for orgContainer in $(echo "${orgContainers}" | jq -r '. | @base64'); do
        _jq(){
                peerNameValue=$(echo "\"$(echo ${orgContainer} | base64 --decode | jq -r ${1})\"")
                peerNameValueStripped=$(echo $peerNameValue | sed 's/"//g')
                peerNameVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_NAME"

                peerHostVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_HOST"
                peerUsernameVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_USERNAME"
                peerPasswordVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PASSWORD"
                peerPathVar="${orgLabelValueStripped^^}_${peerNameValueStripped^^}_PATH"

                # start remote script
                if [ "${dataType}" == "env" ]; then
                        sshpass -p "${!peerPasswordVar}" ssh ${!peerUsernameVar}@${!peerHostVar} "cd ${!peerPathVar}hl/network && bash scripts/removeOrgEnvData.sh external-orgs/sipher-data.json"
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

