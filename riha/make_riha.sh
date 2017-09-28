#
# Usage: make_riha.sh <Central Server IP/Name>
#

# XTEE-CI-XM
# CENTRALSERVER="xtee7.ci.kit"
#
# ee-dev
# CENTRALSERVER="195.80.109.140"
#
# ee-test
# CENTRALSERVER="195.80.127.40"
#
# EE
# CENTRALSERVER="213.184.41.178"

if [ -z ${1} ] || [ ${1} = "-h" ] || [ ${1} = "--help" ]; then
    echo -e "Usage: ${0} <Central Server IP/Name>
        The IP/Name of Central Server can be found in configuration anchor
        # XTEE-CI-XM
        # CENTRALSERVER=\"xtee7.ci.kit\"
        #
        # ee-dev
        # CENTRALSERVER=\"195.80.109.140\"
        #
        # ee-test
        # CENTRALSERVER=\"195.80.127.40\"
        #
        # EE
        # CENTRALSERVER=\"213.184.41.178\"
"
    exit 1;
fi

CENTRALSERVER=${1}

python3 ./list_subsystems_with_server.py ${CENTRALSERVER} | python3 ./subsystems_json.py
