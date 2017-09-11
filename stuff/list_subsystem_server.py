#!/usr/bin/python

# NB! Global configuration signature is not checked. Use this program at your own risk.

import sys
import re
import requests
import xml.etree.ElementTree as ET

# Timeout for http requests
TIMEOUT=5.0

if len(sys.argv) != 2 or sys.argv[1] in ("-h", "-help", "--help"):
    print "Usage: list_subsystem_server.py <central_server_name>\nThe Name/IP of Central server can be found in configuration anchor."
    exit(0)

# Name/IP of Central server
SERVER=sys.argv[1]

# Downloading shared-params.xml
try:
    globalConf = requests.get("http://"+SERVER+"/internalconf", timeout=TIMEOUT)
    globalConf.raise_for_status()
    s = re.search("Content-location: (/.+/shared-params.xml)", globalConf.content)
    sharedParams = requests.get("http://"+SERVER+s.group(1), timeout=TIMEOUT)
    sharedParams.raise_for_status()
except requests.exceptions.RequestException:
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
            for server in root.findall("./securityServer[client='{}']".format(subsystemId)):
                ownerId = server.find("./owner").text
                owner = root.find("./member[@id='"+ownerId+"']")
                ownerClass = owner.find("./memberClass/code").text
                ownerCode = owner.find("./memberCode").text
                serverCode = server.find("./serverCode").text
                address = server.find("./address").text
                foundServer = True
                print "{}/{}/{}/{}".format(instance, memberClass, memberCode, subsystemCode.encode('utf8'))
                #print "{}/{}/{}/{} -> {}/{}/{}/{}/{}".format(instance, memberClass, memberCode, subsystemCode.encode('utf8'), instance, ownerClass, ownerCode, serverCode.encode('utf8'), address.encode('utf8'))
            if not foundServer:
                None
                #print "{}/{}/{}/{} -> NO SERVER".format(instance, memberClass, memberCode, subsystemCode.encode('utf8'))
except Exception as e:
    print e
    exit(0)
