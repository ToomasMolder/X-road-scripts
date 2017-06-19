#!/bin/bash

# NB!!! Global configuration signature is not verified! Do not rely on the validity of this data!

if [ -z $1 ] || [ $1 = "-h" ] || [ $1 = "--help" ]; then
    echo -e "Usage: get_shared_params.sh <central_server_URL>\nThe URL of Central server can be found in configuration anchor"
    exit 1;
fi

SERVER=$1

curl -s "$SERVER"`curl -s $SERVER/internalconf | perl -ne "print \\\$1 if /Content-location: (.*shared-params.xml)/"`
