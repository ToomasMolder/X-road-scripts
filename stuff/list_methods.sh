#!/bin/bash

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [ $1 = "-h" ] || [ $1 = "--help" ]; then
    echo -e "Usage: list_methods.sh <security_server_URL> <consumer_member_identifier> <producer_subsystem_identifier>
Example: ./list_methods.sh server.ci.kit VS/GOV/20000001 VS/GOV/20000001/testSystem2"
    exit 1;
fi

SERVER=$1

IFS='/' read -r -a CONSUMER <<< $2
IFS='/' read -r -a PRODUCER <<< $3

curl -s --header "Content-Type: text/xml;charset=UTF-8" --data '<?xml version="1.0" encoding="utf-8"?>
<SOAP-ENV:Envelope
        xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
        xmlns:xroad="http://x-road.eu/xsd/xroad.xsd"
        xmlns:id="http://x-road.eu/xsd/identifiers">
    <SOAP-ENV:Header>
        <xroad:client id:objectType="MEMBER">
            <id:xRoadInstance>'${CONSUMER[0]}'</id:xRoadInstance>
            <id:memberClass>'${CONSUMER[1]}'</id:memberClass>
            <id:memberCode>'${CONSUMER[2]}'</id:memberCode>
        </xroad:client>
        <xroad:service id:objectType="SERVICE">
            <id:xRoadInstance>'${PRODUCER[0]}'</id:xRoadInstance>
            <id:memberClass>'${PRODUCER[1]}'</id:memberClass>
            <id:memberCode>'${PRODUCER[2]}'</id:memberCode>
            <id:subsystemCode>'${PRODUCER[3]}'</id:subsystemCode>
            <id:serviceCode>listMethods</id:serviceCode>
        </xroad:service>
        <xroad:id>411d6755661409fed365ad8135f8210be07613da</xroad:id>
        <xroad:protocolVersion>4.0</xroad:protocolVersion>
    </SOAP-ENV:Header>
    <SOAP-ENV:Body>
        <xroad:listMethods/>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>' $SERVER \
    | perl -e 'my $stdin = join("", <STDIN>); print "$1\n" if $stdin =~ /(<SOAP-ENV:Envelope.*SOAP-ENV:Envelope>)/s' \
    | xmlstarlet sel -t -m '//xroad:listMethodsResponse/xroad:service' \
        -v "concat(id:xRoadInstance, '/', id:memberClass, '/', id:memberCode, '/', id:subsystemCode, '/', id:serviceCode, '/', id:serviceVersion)" -n \
    2>/dev/null | perl -pne 's/\/$//'
