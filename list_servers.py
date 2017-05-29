#!/usr/bin/python

# NB! Global configuration signature is not checked. Use this program at your own risk.

import sys
import re
import requests
import xml.etree.ElementTree as ET

# Timeout for http requests
TIMEOUT=5.0

if len(sys.argv) != 2 or sys.argv[1] in ("-h", "-help", "--help"):
    print "Usage: list_server.py <central_server_name>\nThe Name/IP of Central server can be found in configuration anchor."
    exit(0)

# Name/IP of Central server
SERVER=sys.argv[1]

# Downloading shared-params.xml
try:
    globalConf = requests.get("http://"+SERVER+"/internalconf", timeout=TIMEOUT)
    globalConf.raise_for_status()
    s = re.search("Content-location: (/\d+/shared-params.xml)", globalConf.content)
    sharedParams = requests.get("http://"+SERVER+s.group(1), timeout=TIMEOUT)
    sharedParams.raise_for_status()
except requests.exceptions.RequestException:
    exit(0)

try:
    root = ET.fromstring(sharedParams.content)
    instance = root.find("./instanceIdentifier").text
    for server in root.findall("./securityServer"):
        ownerId = server.find("./owner").text
        owner = root.find("./member[@id='"+ownerId+"']")
        memberClass = owner.find("./memberClass/code").text
        memberCode = owner.find("./memberCode").text
        serverCode = server.find("./serverCode").text
        address = server.find("./address").text
        print instance + "/" + memberClass + "/" + memberCode + "/" + serverCode + "/" + address
except Exception:
    exit(0)
