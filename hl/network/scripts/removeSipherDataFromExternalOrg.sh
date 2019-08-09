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

CURRENT_DIR=$PWD

if [ ! -f "$ORG_CONFIG_FILE" ]; then
        echo
        echo "ERROR: $ORG_CONFIG_FILE file not found. Cannot proceed with parsing network configuration"
        exit 1
fi

source ~/.profile
source .env

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

which sshpass
if [ "$?" -ne 0 ]; then
        echo "sshpass tool not found"
        exit 1
fi

orgContainers=$(jq -r '.containers[]' $ORG_CONFIG_FILE)

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

