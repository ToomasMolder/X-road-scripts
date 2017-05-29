#!/usr/bin/python

from pyzabbix import ZabbixMetric, ZabbixSender
import sys
import re
import requests
import xml.etree.ElementTree as ET
import uuid

# Security server URL used by Central monitoring:
SERVER_URL="http://xtee4.ci.kit"

# Central monitoring subsystem/member (defined in global configuration):
MONITORING_CLIENT="""        <xrd:client id:objectType="SUBSYSTEM">
            <id:xRoadInstance>XTEE-CI</id:xRoadInstance>
            <id:memberClass>GOV</id:memberClass>
            <id:memberCode>00000000</id:memberCode>
            <id:subsystemCode>Center</id:subsystemCode>
        </xrd:client>
"""

# Timeout for http requests
TIMEOUT=5.0

# Namespace of monitoring service
NS = {'m': 'http://x-road.eu/xsd/monitoring'}


def getMetric(node, server):
    "Returns Zabbix packet elements from node"
    p = []
    nsp = "{" + NS['m'] + "}"

    if node.tag == nsp+"stringMetric" or node.tag == nsp+"numericMetric":
        try:
            name = node.find("./m:name", NS).text
            # Some names may have '/' character which is forbiden by zabbix
            name=name.replace("/", "")
            p.append(ZabbixMetric(server, name, node.find("./m:value", NS).text))
        except Exception:
            print "Incorect node: " + node
        return p
    elif node.tag == nsp+"histogramMetric":
        try:
            name = node.find("./m:name", NS).text
            p.append(ZabbixMetric(server, name+"_updated", node.find("./m:updated", NS).text))
            p.append(ZabbixMetric(server, name+"_min", node.find("./m:min", NS).text))
            p.append(ZabbixMetric(server, name+"_max", node.find("./m:max", NS).text))
            p.append(ZabbixMetric(server, name+"_mean", node.find("./m:mean", NS).text))
            p.append(ZabbixMetric(server, name+"_median", node.find("./m:median", NS).text))
            p.append(ZabbixMetric(server, name+"_stddev", node.find("./m:stddev", NS).text))
        except Exception:
            print "Incorect node: " + node
        return p

def getXRoadPackages(node, server):
    "Returns Zabbix packet elements from 'Packages' node"
    p=[]

    try:
        name = node.find("./m:name", NS).text
        data = ''
        for pack in node.findall("./m:stringMetric", NS):
            packname = pack.find("./m:name", NS).text
            if "xroad" in packname:
                data += packname + ": " + pack.find("./m:value", NS).text + "\n"
        p.append(ZabbixMetric(server, name, data))
    except Exception:
        print "Incorect 'Packages' node: " + node
    return p


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

    host_name = re.sub("[^0-9a-zA-Z\.-]+", '.', m.group(0))

    body = """<SOAP-ENV:Envelope
       xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
       xmlns:id="http://x-road.eu/xsd/identifiers"
       xmlns:xrd="http://x-road.eu/xsd/xroad.xsd"
       xmlns:m="http://x-road.eu/xsd/monitoring">
    <SOAP-ENV:Header>
""" + MONITORING_CLIENT + """        <xrd:service id:objectType="SERVICE">
            <id:xRoadInstance>""" + m.group(1) + """</id:xRoadInstance>
            <id:memberClass>""" + m.group(2) + """</id:memberClass>
            <id:memberCode>""" + m.group(3) + """</id:memberCode>
            <id:serviceCode>getSecurityServerMetrics</id:serviceCode>
        </xrd:service>
        <xrd:securityServer id:objectType="SERVER">
            <id:xRoadInstance>""" + m.group(1) + """</id:xRoadInstance>
            <id:memberClass>""" + m.group(2) + """</id:memberClass>
            <id:memberCode>""" + m.group(3) + """</id:memberCode>
            <id:serverCode>""" + m.group(4) + """</id:serverCode>
        </xrd:securityServer>
        <xrd:id>""" + str(uuid.uuid4()) + """</xrd:id>
        <xrd:protocolVersion>4.0</xrd:protocolVersion>
    </SOAP-ENV:Header>
    <SOAP-ENV:Body>
        <m:getSecurityServerMetrics/>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
"""

    headers = {"Content-type": "text/xml;charset=UTF-8"}

    try:
        response = requests.post(SERVER_URL, data=body, headers=headers, timeout=TIMEOUT)
        response.raise_for_status()
    except requests.exceptions.RequestException:
        print "Cannot get response for: " + m.group(0)
        continue

    try:
        # Skipping multipart headers
        envel = re.search("<SOAP-ENV:Envelope.+<\/SOAP-ENV:Envelope>", response.content, re.DOTALL)
        root = ET.fromstring(envel.group(0))
        metrics = root.find(".//m:getSecurityServerMetricsResponse/m:metricSet", NS)
        if metrics is None:
            raise
    except Exception:
        print "Cannot parse response of: " + m.group(0)
        continue

    packet = []

    try: packet += getMetric(metrics.find(".//m:stringMetric[m:name='proxyVersion']", NS), host_name)
    except Exception: print "Metric 'proxyVersion' for host " + host_name + " is not available"
    try: packet += getMetric(metrics.find(".//m:histogramMetric[m:name='CommittedVirtualMemory']", NS), host_name)
    except Exception: print "Metric 'CommittedVirtualMemory' for host " + host_name + " is not available"
    try: packet += getMetric(metrics.find(".//m:histogramMetric[m:name='FreePhysicalMemory']", NS), host_name)
    except Exception: print "Metric 'FreePhysicalMemory' for host " + host_name + " is not available"
    try: packet += getMetric(metrics.find(".//m:histogramMetric[m:name='FreeSwapSpace']", NS), host_name)
    except Exception: print "Metric 'FreeSwapSpace' for host " + host_name + " is not available"
    try: packet += getMetric(metrics.find(".//m:histogramMetric[m:name='OpenFileDescriptorCount']", NS), host_name)
    except Exception: print "Metric 'OpenFileDescriptorCount' for host " + host_name + " is not available"
    try: packet += getMetric(metrics.find(".//m:histogramMetric[m:name='SystemCpuLoad']", NS), host_name)
    except Exception: print "Metric 'SystemCpuLoad' for host " + host_name + " is not available"
    try: packet += getMetric(metrics.find(".//m:numericMetric[m:name='DiskSpaceFree_/']", NS), host_name)
    except Exception: print "Metric 'DiskSpaceFree_/' for host " + host_name + " is not available"
    try: packet += getMetric(metrics.find(".//m:numericMetric[m:name='DiskSpaceTotal_/']", NS), host_name)
    except Exception: print "Metric 'DiskSpaceTotal_/' for host " + host_name + " is not available"
    try: packet += getMetric(metrics.find(".//m:numericMetric[m:name='MaxFileDescriptorCount']", NS), host_name)
    except Exception: print "Metric 'MaxFileDescriptorCount' for host " + host_name + " is not available"
    try: packet += getMetric(metrics.find(".//m:stringMetric[m:name='OperatingSystem']", NS), host_name)
    except Exception: print "Metric 'OperatingSystem' for host " + host_name + " is not available"
    try: packet += getMetric(metrics.find(".//m:numericMetric[m:name='TotalPhysicalMemory']", NS), host_name)
    except Exception: print "Metric 'TotalPhysicalMemory' for host " + host_name + " is not available"
    try: packet += getMetric(metrics.find(".//m:numericMetric[m:name='TotalSwapSpace']", NS), host_name)
    except Exception: print "Metric 'TotalSwapSpace' for host " + host_name + " is not available"

    # In might not be a good idea to store Package list in zabbix. As a compromise we filter only xroad packages.
    try: packet += getXRoadPackages(metrics.find(".//m:metricSet[m:name='Packages']", NS), host_name)
    except Exception: print "Metric 'Packages' (xroad) for host " + host_name + " is not available"

    # Pushing metrics to zabbix
    sender = ZabbixSender('localhost')
    sender.send(packet)
