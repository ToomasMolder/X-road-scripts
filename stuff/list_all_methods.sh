#!/bin/bash

if [ -z $1 ] || [ -z $2 ] || [ $1 = "-h" ] || [ $1 = "--help" ]; then
    echo -e "Usage: $0 <security_server_URL> <consumer_member_identifier>
Example: $0 server.ci.kit VS/GOV/20000001"
    exit 1;
fi

SERVER=$1
CONSUMER=$2

for PRODUCER in $( ./list_subsystems.sh $SERVER ); do
    ./list_methods.sh $SERVER $CONSUMER $PRODUCER
done
