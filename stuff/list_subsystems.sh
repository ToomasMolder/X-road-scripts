#!/bin/bash

if [ -z ${1} ] || [ ${1} = "-h" ] || [ ${1} = "--help" ]; then
    echo -e "Usage: ${0} <security_server_IP/name>
Example: ${0} server.ci.kit"
    exit 1;
fi

SERVER=${1}

: '
Quick installation of xmlstarlet:
Step 1: Update system:
        sudo apt-get update
Step 2: Install: xmlstarlet
Ater updaing the OS run following command to install the packae:
        sudo apt-get install xmlstarlet
'

curl -s ${SERVER}/listClients | xmlstarlet sel -t -m '//ns2:member/ns2:id[@ns1:objectType="SUBSYSTEM"]' \
    -v "concat(ns1:xRoadInstance, '/', ns1:memberClass, '/', ns1:memberCode, '/', ns1:subsystemCode)" -n
