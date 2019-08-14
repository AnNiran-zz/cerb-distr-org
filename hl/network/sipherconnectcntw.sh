#!/bin/bash

# network up steps

# Do some basic sanity checking to make sure that the appropriate versions of fabric
# binaries/images are available.  In the future, additional checking for the presence
# of go or other items could be added.
function checkPrereqs() {
        source .env

        # Note, we check configtxlator externally because it does not require a config file, and peer in the
        # docker image because of FAB-8551 that makes configtxlator return 'development version' in docker
        LOCAL_VERSION=$(configtxlator version | sed -ne 's/ Version: //p')
        DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)

        echo "LOCAL_VERSION=$LOCAL_VERSION"
        echo "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

        if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
                echo "=================== WARNING ==================="
                echo "  Local fabric binaries and docker images are  "
                echo "  out of  sync. This may cause problems.       "
                echo "==============================================="
        fi

        for UNSUPPORTED_VERSION in $BLACKLISTED_VERSIONS; do
                echo "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
                if [ $? -eq 0 ]; then
                        echo "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
                        exit 1
                fi

                echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
                if [ $? -eq 0 ]; then
                        echo "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
                        exit 1
                fi
        done
}

function replacePrivateKey() {
        # sed on MacOSX does not support -i flag with a null extension. We will use
        # 't' for our back-up's extension and delete it at the end of the function
        getArch
        # Copy the template to the file that will be modified to add the private key
        cp $COMPOSE_FILE_SIPHER_CA_TEMPLATE $COMPOSE_FILE_SIPHER_CA

        # The next steps will replace the template's contents with the
        # actual values of the private key file names for the two CAs.
        CURRENT_DIR=$PWD
        cd crypto-config/peerOrganizations/sipher.cerberus.net/ca/
        PRIV_KEY=$(ls *_sk)
        cd "$CURRENT_DIR"
        sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" $COMPOSE_FILE_SIPHER_CA

        if [ "$ARCH" == "Darwin" ]; then
                rm /sipher-config/sipher-ca.yamlt
        fi
}

# We will use the cryptogen tool to generate the cryptographic material (x509 certs)
# for our various network entities.  The certificates are based on a standard PKI
# implementation where validation is achieved by reaching a common trust anchor.
#
# Cryptogen consumes a file - ``crypto-config.yaml`` - that contains the network
# topology and allows us to generate a library of certificates for both the
# Organizations and the components that belong to those Organizations.  Each
# Organization is provisioned a unique root certificate (``ca-cert``), that binds
# specific components (peers and orderers) to that Org.  Transactions and communications
# within Fabric are signed by an entity's private key (``keystore``), and then verified
# specific components (peers and orderers) to that Org.  Transactions and communications
# within Fabric are signed by an entity's private key (``keystore``), and then verified
# by means of a public key (``signcerts``).  You will notice a "count" variable within
# this file.  We use this to specify the number of peers per Organization; in our
# case it's two peers per Org.  The rest of this template is extremely
# self-explanatory.
#
# After we run the tool, the certs will be parked in a folder titled ``crypto-config``.

# Generates Org certs using cryptogen tool
function generateCerts() {
        which cryptogen
        if [ "$?" -ne 0 ]; then
                echo "cryptogen tool not found. exiting"
                exit 1
        fi
        echo
        echo "##########################################################"
        echo "##### Generate certificates using cryptogen tool #########"
        echo "##########################################################"

        if [ -d "crypto-config" ]; then
                rm -Rf crypto-config
        fi
        set -x
        cryptogen generate --config=./crypto-config.yaml
        res=$?
        set +x
        if [ $res -ne 0 ]; then
                echo "Failed to generate certificates..."
                exit 1
        fi
        echo
}

# The `configtxgen tool is used to create four artifacts: orderer **bootstrap
# block**, fabric **channel configuration transaction**, and two **anchor
# peer transactions** - one for each Peer Org.
#
# The orderer block is the genesis block for the ordering service, and the
# channel transaction file is broadcast to the orderer at channel creation
# time.  The anchor peer transactions, as the name might suggest, specify each
# Org's anchor peer on this channel.
#
# Configtxgen consumes a file - ``configtx.yaml`` - that contains the definitions
# for the sample network. There are three members - one Orderer Org (``OrdererOrg``)
# and two Peer Orgs (``Org1`` & ``Org2``) each managing and maintaining two peer nodes.
# This file also specifies a consortium - ``SampleConsortium`` - consisting of our
# two Peer Orgs.  Pay specific attention to the "Profiles" section at the top of
# this file.  You will notice that we have two unique headers. One for the orderer genesis
# block - ``TwoOrgsOrdererGenesis`` - and one for our channel - ``TwoOrgsChannel``.
# These headers are important, as we will pass them in as arguments when we create
# our artifacts.  This file also contains two additional specifications that are worth
# noting.  Firstly, we specify the anchor peers for each Peer Org
# (``peer0.org1.example.com`` & ``peer0.org2.example.com``).  Secondly, we point to
# the location of the MSP directory for each member, in turn allowing us to store the
# root certificates for each Org in the orderer genesis block.  This is a critical
# concept. Now any network entity communicating with the ordering service can have
# its digital signature verified.
#
# This function will generate the crypto material and our four configuration
# artifacts, and subsequently output these files into the ``channel-artifacts``
# folder.
#
# If you receive the following warning, it can be safely ignored:
#
# [bccsp] GetDefault -> WARN 001 Before using BCCSP, please call InitFactories(). Falling back to bootBCCSP.
#
# You can ignore the logs regarding intermediate certs, we are not using them in
# this crypto implementation.

# Generate orderer genesis block, channel configuration transaction and
# anchor peer update transactions
function generateChannelsArtifacts() {

        which configtxgen
        if [ "$?" -ne 0 ]; then
                echo "configtxgen tool not found. exiting"
                exit 1
        fi

        echo "###########################################################"
        echo "#########  Generating Sipher config material ##############"
        echo "###########################################################"

        set -x
        configtxgen -printOrg SipherMSP > channel-artifacts/sipher-channel-artifacts.json
        res=$?
        set +x
        if [ $res -ne 0 ]; then
                echo "Failed to generate Sipher config materials "
                exit 1
        fi
}

#####################################################
function generateOrgConfiguration() {

        checkPrereqs
        # generate artifacts if they don't exist
        if [ ! -d "crypto-config" ]; then
                generateCerts
                replacePrivateKey
                generateChannelsArtifacts
        fi
}

function createConfigTx() {
	
	# run script in cerberus	
	

}

function t() {
        # deliver sipher-data.json file to network
        destination=$CERBERUS_OS_IP:/home/anniran/server/go/src/cerberus-os/hl/network/external-orgs

        which sshpass
        if [ "$?" -ne 0 ]; then
               echo "sshpass not found"
               exit 1
        fi

        sshpass -p "${CERBERUS_OS_PASSWORD}" scp sipher-config/sipher-data.json $CERBERUS_OS_USERNAME@$destination
        if [ "$?" -ne 0 ]; then
                echo "ERROR: Cannot copy Sipher configuration file to network hosts"
                exit 1
        fi

        echo "Sipher configuration file successfully copied to network hosts"    
}


