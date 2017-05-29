#!/bin/bash

# IP or URI of central server
# Environment: CI
CENTRALSERVER="xtee7.ci.kit"

LIST_SERVERS="./list_servers.py"
if [ ! -f "${LIST_SERVERS}" ]
then
    echo "ERROR: File ${LIST_SERVERS} does not exists"
    exit 1
fi

GET_OPMON="get_opmon.py"
if [ ! -f "${GET_OPMON}" ]
then
    echo "ERROR: File ${GET_OPMON} does not exists"
    exit 1
fi

# Current timestamp
NOW=`/bin/date +"%Y-%m-%d_%H:%M:%S%z"`

# A cache file is used when central server does not reply
CACHE_DIR="."
CACHE_EXT="txt"
SERVERS_CACHE_NOW="${CACHE_DIR}/cache_${CENTRALSERVER}_${NOW}.${CACHE_EXT}"
SERVERS_CACHE="${CACHE_DIR}/cache_${CENTRALSERVER}.${CACHE_EXT}"

DATA=`${LIST_SERVERS} ${CENTRALSERVER}`

if [[ -z ${DATA} ]]; then
    DATA=`/bin/cat ${SERVERS_CACHE}`
    if [[ -z ${DATA} ]]; then
        echo "ERROR: Server list not available"
        exit 1
    fi
else
    echo "${DATA}" > ${SERVERS_CACHE_NOW}
        /bin/rm -f ${SERVERS_CACHE}
        /bin/ln -s ${SERVERS_CACHE_NOW} ${SERVERS_CACHE}
fi

echo "${DATA}" | python ${GET_OPMON}

