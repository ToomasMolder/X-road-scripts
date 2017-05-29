#!/bin/bash

# IP or URI of central server
CENTRALSERVER="xtee3.ci.kit"

# A cache file is used when central server does not reply
SERVERS_CACHE="/var/tmp/xtee_servers_xtee3.ci.kit.txt"

DATA=`./list_servers.py $CENTRALSERVER`

if [[ -z $DATA ]]; then
    DATA=`cat $SERVERS_CACHE`
    if [[ -z $DATA ]]; then
        echo "ERROR: Server list not available"
        exit 1
    fi
else
    echo "$DATA" > $SERVERS_CACHE
fi

echo "$DATA" | python add_hosts.py
echo "$DATA" | python push_metrics.py
