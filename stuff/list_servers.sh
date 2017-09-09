#!/bin/bash

if [ -z ${1} ] || [ ${1} = "-h" ] || [ ${1} = "--help" ]; then
    echo -e "Usage: ${0} <central_server_URL>\nThe URL of Central server can be found in configuration anchor"
    exit 1;
fi

SERVER=${1}
GET_SHARED_PARAMS="./get_shared_params.sh"

: '
Quick installation of xmlstarlet:

Step 1: Update system:

        sudo apt-get update
Step 2: Install: xmlstarlet

Ater updaing the OS run following command to install the packae:

        sudo apt-get install xmlstarlet
'

if [[ -x "${GET_SHARED_PARAMS}" ]]
then
    ${GET_SHARED_PARAMS} ${SERVER} | xmlstarlet sel -t -m '/ns3:conf/securityServer' \
    -v "concat(/ns3:conf/instanceIdentifier, '/', /ns3:conf/member[@id=current()/owner]/memberClass/code, '/', /ns3:conf/member[@id=current()/owner]/memberCode, '/', serverCode, '/', address)" -n
    exit $?;
else
    echo "File '${GET_SHARED_PARAMS}' is not executable or found"
    exit 1;
fi
