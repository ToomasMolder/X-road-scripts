#!/usr/bin/python

from zabbix.api import ZabbixAPI
import sys
import re

templateid = "10242" # enter your own template id here!

# Create ZabbixAPI class instance
user = '' # enter your own here!
password = '' # enter your own here!
zapi = ZabbixAPI(url='https://xtee-monitor.ci.kit/', user=user, password=password)

# Get all monitored hosts
result1 = zapi.host.get(monitored_hosts=1, output='extend')

# Get all disabled hosts
result2 = zapi.do_request('host.get',
                          {
                              'filter': {'status': 1},
                              'output': 'extend'
                          })

# Filter results
hostnames1 = [host['host'] for host in result1]
hostnames2 = [host['host'] for host in result2['result']]

# Example stdin:
# XTEE-CI/GOV/00000000/00000000_1/xtee4.ci.kit
# XTEE-CI/GOV/00000001/00000001_1/xtee5.ci.kit
# XTEE-CI/COM/00000002/00000002_1/xtee6.ci.kit
# Server name part is "greedy" match to allow server names to have "/" character
for line in sys.stdin:
    m = re.match("^(.+?)/(.+?)/(.+?)/(.+)/(.+?)$", line)

    if m is None or m.lastindex != 5:
        print "Incorrect server string: " + line
        continue

    visible_name = m.group(0)
    host_name = re.sub("[^0-9a-zA-Z\.-]+", '.', visible_name)

    if host_name not in hostnames1 and host_name not in hostnames2:
        zapi.do_request('host.create',
            {
                "host": host_name,
                "name": visible_name,
                "interfaces": [
                    {
                        "type": 1,
                        "main": 1,
                        "useip": 1,
                        "ip": "127.0.0.1",
                        "dns": "",
                        "port": "10050"
                    }
                ],	
                "groups": [
        	    {
                        "groupid":"2"
                    }
                ],
                "templates": [
                    {
                        "templateid": templateid
                    }
                ],
                "description": visible_name,
            }
        )
