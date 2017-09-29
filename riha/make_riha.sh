#
# Usage: make_riha.sh <Central Server IP/Name>
#

if [ -z ${1} ] || [ ${1} = "-h" ] || [ ${1} = "--help" ]; then
    echo -e "Usage: ${0} <Central Server IP/Name>
        The IP/Name of Central Server can be found in configuration anchor http://x-road.eu/packages/
        # XTEE-CI-XM
        # CENTRALSERVER=\"xtee7.ci.kit\"
        #
        # ee-dev http://x-road.eu/packages/ee-dev_public_anchor.xml
        # CENTRALSERVER=\"195.80.109.140\"
        #
        # ee-test http://x-road.eu/packages/ee-test_public_anchor.xml
        # CENTRALSERVER=\"195.80.127.40\"
        #
        # EE http://x-road.eu/packages/EE_public-anchor.xml
        # CENTRALSERVER=\"213.184.41.178\"
"
    exit 1;
fi

CENTRALSERVER=${1}

python3 ./list_subsystems_with_server.py ${CENTRALSERVER} | python3 ./subsystems_json.py
