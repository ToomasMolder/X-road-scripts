#!/bin/bash

if [ -z $1 ] || [ $1 = "-h" ] || [ $1 = "--help" ]; then
    echo -e "Usage: list_servers.sh <central_server_URL>\nThe URL of Central server can be found in configuration anchor"
    exit 1;
fi

SERVER=$1

./get_shared_params.sh $SERVER | xmlstarlet sel -t -m '/ns3:conf/securityServer' \
    -v "concat(/ns3:conf/instanceIdentifier, '/', /ns3:conf/member[@id=current()/owner]/memberClass/code, '/', /ns3:conf/member[@id=current()/owner]/memberCode, '/', serverCode, '/', address)" -n
