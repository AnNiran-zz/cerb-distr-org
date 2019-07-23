#!/usr/bin/env bash

# This is a collection of bash functions used by different scripts
 
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/cerberus.net/orderers/orderer.cerberus.net/msp/tlscacerts/tlsca.cerberus.net-cert.pem
  
OSINSTANCE0_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/cerberus.net/orderers/osinstance0.cerberus.net/msp/tlscacerts/tlsca.cerberus.net-cert.pem
OSINSTANCE1_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/cerberus.net/orderers/osinstance1.cerberus.net/msp/tlscacerts/tlsca.cerberus.net-cert.pem
OSINSTANCE2_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/cerberus.net/orderers/osinstance2.cerberus.net/msp/tlscacerts/tlsca.cerberus.net-cert.pem
OSINSTANCE3_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/cerberus.net/orderers/osinstance3.cerberus.net/msp/tlscacerts/tlsca.cerberus.net-cert.pem
OSINSTANCE4_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/cerberus.net/orderers/osinstance4.cerberus.net/msp/tlscacerts/tlsca.cerberus.net-cert.pem
  
CORE_PEER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/sipher.cerberus.net/peers/anchorpr.sipher.cerberus.net/tls/ca.crt
 


verifyResult() {
	if [ $1 -ne 0 ]; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
		echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
		echo
		exit 1
	fi
}

setOrdererGlobals() {
 	OSINSTANCE=$1
	echo $OSINSTANCE

 	CORE_PEER_LOCALMSPID="OSMSP"
 	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cerberusorg.cerberus.net/users/Admin@cerberusorg.cerberus.net/msp

	if [ $OSINSTANCE -eq 0 ]; then
 		CORE_PEER_TLS_ROOTCERT_FILE=$OSINSTANCE0_CA
 	elif [ $OSINSTANCE -eq 1 ]; then
		CORE_PEER_TLS_ROOTCERT_FILE=$OSINSTANCE1_CA
	elif [ $OSINSTANCE -eq 2 ]; then
		CORE_PEER_TLS_ROOTCERT_FILE=$OSINSTANCE2_CA
	elif [ $OSINSTANCE -eq 3 ]; then
		CORE_PEER_TLS_ROOTCERT_FILE=$OSINSTANCE3_CA
	elif [ $OSINSTANCE -eq 4 ]; then
		CORE_PEER_TLS_ROOTCERT_FILE=$OSINSTANCE4_CA
 	else
		echo "Unknown ordering service instance"
	fi
}

function setGlobals() {
	PEER=$1
	# peers:
	# peer0 - anchorpr
  	# peer1 - lead0pr
	# peer2 - lead1pr
 	# peer3 - communicatepr
 	# peer4 - execute0pr
 	# peer5 - execute1pr
 	# peer6 - fallback0pr
	# peer7 - fallback1pr

	CORE_PEER_LOCALMSPID="SipherMSP"
	ORGANIZATION_NAME="sipher"
	CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_CA
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/sipher.cerberus.net/users/Admin@sipher.cerberus.net/msp

	if [ $PEER -eq 0 ]; then
		PEER_NAME="anchorpr"
		CORE_PEER_ADDRESS=anchorpr.sipher.cerberus.net:7051
	elif [ $PEER -eq 1 ]; then
		PEER_NAME="lead0pr"
		CORE_PEER_ADDRESS=lead0pr.sipher.cerberus.net:7051
	elif [ $PEER -eq 2 ]; then
		PEER_NAME="lead1pr"
		CORE_PEER_ADDRESS=lead1pr.sipher.cerberus.net:7051
	elif [ $PEER -eq 3 ]; then
		PEER_NAME="communicatepr"
		CORE_PEER_ADDRESS=communicatepr.sipher.cerberus.net:7051
	elif [ $PEER -eq 4 ]; then
		PEER_NAME="execute0pr"
		CORE_PEER_ADDRESS=execute0pr.sipher.cerberus.net:7051
	elif [ $PEER -eq 5 ]; then
		PEER_NAME="execute1pr"
		CORE_PEER_ADDRESS=execute1pr.sipher.cerberus.net:7051
	elif [ $PEER -eq 6 ]; then
		PEER_NAME="fallback0pr"
		CORE_PEER_ADDRESS=fallback0pr.sipher.cerberus.net:7051
	elif [ $PEER -eq 7 ]; then
		PEER_NAME="fallback1pr"
		CORE_PEER_ADDRESS=fallback1pr.sipher.cerberus.net:7051
	else
		echo "Unknown peer"
		exit 1
	fi

	if [ "$VERBOSE" == "true" ]; then
		env | grep CORE
	fi
}


