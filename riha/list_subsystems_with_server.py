#!/usr/bin/python

# NB! Global configuration signature is not checked. Use this program at your own risk.

import sys
import re
import requests
import xml.etree.ElementTree as ET

# Timeout for http requests
TIMEOUT=5.0

if len(sys.argv) != 2 or sys.argv[1] in ("-h", "-help", "--help"):
    print("Usage: list_subsystem_server.py <central_server_name>\nThe Name/IP of Central server can be found in configuration anchor.")
    exit(0)

# Name/IP of Central server
SERVER=sys.argv[1]

# Downloading shared-params.xml
try:
    globalConf = requests.get("http://{}/internalconf".format(SERVER), timeout=TIMEOUT)
    globalConf.raise_for_status()
    s = re.search("Content-location: (/.+/shared-params.xml)", globalConf.content.decode('utf-8'))
    sharedParams = requests.get("http://{}{}".format(SERVER, s.group(1)), timeout=TIMEOUT)
    sharedParams.raise_for_status()
except requests.exceptions.RequestException as e:
    print(e)
    exit(0)

try:
    root = ET.fromstring(sharedParams.content)
    instance = root.find("./instanceIdentifier").text
    for member in root.findall("./member"):
        memberId = member.attrib["id"]
        memberClass = member.find("./memberClass/code").text
        memberCode = member.find("./memberCode").text
        for subsystem in member.findall("./subsystem"):
            subsystemId = subsystem.attrib["id"]
            subsystemCode = subsystem.find("./subsystemCode").text
            foundServer = False
            if root.findall("./securityServer[client='{}']".format(subsystemId)):
                print(u"{}/{}/{}/{}".format(instance, memberClass, memberCode, subsystemCode))
                # if sys.version_info[0] < 3:
                    # print("{}/{}/{}/{}".format(instance, memberClass, memberCode, subsystemCode.encode('utf-8')))
                # else:
                    # print("{}/{}/{}/{}".format(instance, memberClass, memberCode, subsystemCode))
except Exception as e:
    print(e)
    exit(0)
