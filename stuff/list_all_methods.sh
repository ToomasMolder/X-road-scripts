#!/bin/bash

if [ -z ${1} ] || [ -z ${2} ] || [ ${1} = "-h" ] || [ ${1} = "--help" ]; then
    echo -e "Usage: ${0} <security_server_URL> <consumer_member_identifier>
Example: ${0} server.ci.kit VS/GOV/20000001"
    exit 1
fi

SERVER=${1}
CONSUMER=${2}
LIST_METHODS="./list_methods.sh"
LIST_SUBSYSTEMS="./list_subsystems.sh"

if [ ! -x "${LIST_METHODS}" ]; then
    echo "File '${LIST_METHODS}' is not executable or found"
    exit 1
fi

if [ ! -x "${LIST_SUBSYSTEMS}" ]; then
    echo "File '${LIST_SUBSYSTEMS}' is not executable or found"
    exit 1
fi

for PRODUCER in $( ${LIST_SUBSYSTEMS} ${SERVER} ); do
    ${LIST_METHODS} ${SERVER} ${CONSUMER} ${PRODUCER}
done

exit $?
