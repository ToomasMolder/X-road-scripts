#!/bin/bash

# Sample scripts to collect X-Road v6 operational monitoring data from security servers.
# Includes:
# cron.sh - main script (bash) to be executed manually or from crontab. Sample: */15 * * * * /path/to/cron.sh
# list_servers.py - Python script to prepare list of security servers, from where operational monitoring data to be collected
# get_opmon.py - Python script to collect operational monitoring data from given security server

#
# Variables
#
# Executables
PYTHON="/usr/bin/python"
# Get current working directory
CWD=$(pwd)
LIST_SERVERS="${CWD}/list_servers.py"
GET_OPMON="${CWD}/get_opmon.py"
# IP or URI of central server
# Environment: CI
CENTRALSERVER="xtee7.ci.kit"
# Current timestamp
NOW=$(/bin/date +"%Y-%m-%d_%H:%M:%S%z")
# A cache file is used when central server does not reply
CACHE_DIR="."
CACHE_EXT="txt"
SERVERS_CACHE_NOW="${CACHE_DIR}/cache_${CENTRALSERVER}_${NOW}.${CACHE_EXT}"
SERVERS_CACHE="${CACHE_DIR}/cache_${CENTRALSERVER}.${CACHE_EXT}"
# Directory to keep result files, log directory
LOG_DIR="."

#
# Basic checks before actual work
#
# We do expect Python available
if [ ! -x "${PYTHON}" ] || [ ! -f "${PYTHON}" ]
then
    echo "ERROR: ${PYTHON} is not executable or available!"
    exit 1
fi

# We do expect Python ver 2.x available
PYTHON_VERSION=$(${PYTHON} -V 2>&1)
if [[ "${PYHON_VERSION}" =~ "2." ]]
then
    echo "ERROR: ${PYTHON} version 2.x is required!"
    exit 1
fi

# We do expect required Python scripts available
if [ ! -f "${LIST_SERVERS}" ]
then
    echo "ERROR: File ${LIST_SERVERS} does not exist!"
    exit 1
fi

if [ ! -f "${GET_OPMON}" ]
then
    echo "ERROR: File ${GET_OPMON} does not exist!"
    exit 1
fi

# We do expect working directory exists
if [ ! -d "${LOG_DIR}" ]
then
    echo "ERROR: Log directory ${LOG_DIR} does not exist!"
    exit 1
fi

#
# Do the actual stuff
#
# Receive list of security servers available from CENTRALSERVER global configuration
# When succeeded, keep it in cache file
# When failed, use cache file
DATA=$(${PYTHON} ${LIST_SERVERS} ${CENTRALSERVER})

if [[ -z ${DATA} ]]; then
    DATA=$(/bin/cat ${SERVERS_CACHE})
    if [[ -z ${DATA} ]]; then
        echo "ERROR: Server list not available"
        exit 1
    fi
else
    echo "${DATA}" > ${SERVERS_CACHE_NOW}
        /bin/rm -f ${SERVERS_CACHE}
        /bin/ln -s ${SERVERS_CACHE_NOW} ${SERVERS_CACHE}
fi

# Receive operational monitoring data from security servers in list
# Script GET_OPMON keeps the status of data received in ${LOG_DIR}/nextRecordsFrom.json
cd ${LOG_DIR}
echo "${DATA}" | ${PYTHON} ${GET_OPMON}
cd ${CWD}
