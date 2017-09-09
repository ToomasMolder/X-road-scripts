#!/bin/bash
# Vassil Marjunits (Vasell Marjumets), help@ria.ee
# Slightly modified by Toomas Mölder <toomas.molder@ria.ee>

userId="EE30101010007" # Dummy, please use your own isikukood here
uuid="411d6755661409fed365ad8135f8210be07613da" # Dummy, please use your own and uniq UUID here

FILE_PARING="/tmp/paring.xml"
FILE_TEENUSED="/tmp/teenused.txt"

/bin/rm -f ${FILE_PARING} ${FILE_TEENUSED}

echo
echo "NB! Skript tuleb käivitada oma asutuse TURVASERVERIS"

echo
echo -e "Sisesta X-tee KESKKONNA LÜHEND kus skript käivitatakse:\n EE = toodang\n ee-test = test\n ee-dev = arendus\n ja vajuta ENTER\n"
read keskkond
echo

case "${keskkond}" in
'EE')
	KS="213.184.41.186" # Toodang Keskserver, public anchor http://x-road.eu/packages/EE_public-anchor.xml
;;
'ee-test')
	KS="195.80.127.40"	# Test Keskserver, public anchor http://x-road.eu/packages/ee-test_public_anchor.xml
;;
'ee-dev')
	KS="195.80.109.140" # Arendus Keskserver, public anchor http://x-road.eu/packages/ee-dev_public_anchor.xml
;;
*)
echo "Sisestasid mingi jama. Käivita uuesti skript"
exit 0
;;
esac

echo -e "Sisesta ASUTUSE REGISTRIKOOD (X-tee teenuste tarbija - consumer), ja vajuta ENTER:\n"
read consumer
echo

echo -e "Sisesta turvaserveri IP (sisemine liides), kus skript käivitatakse ja vajuta ENTER\n"
read tsip
echo

port="80"
echo -e "Sisesta turvaserveri PORT, vaikimisi on 80, ja vajuta ENTER\n"
read port
echo

echo "PÄRITAKSE ANDMEID, PALUN OOTA..."
echo

red='\e[0;31m'
NC='\e[0m'

# päritakse keskserveris andmekogude nimekirja
for producer in $(dig allproducers.xtee.riik.ee txt @${KS} | grep TXT \
| grep -v ";allprod" | awk '{ print $5 }' | sed 's/"//' | sed 's/"//' | sort);do
# allowedMethods päringu koostamine
paring=$(cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<SOAP-ENV:Envelope
        xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
        xmlns:xrd="http://x-road.ee/xsd/x-road.xsd">
    <SOAP-ENV:Header>
        <xrd:consumer>${consumer}</xrd:consumer>
        <xrd:producer>${producer}</xrd:producer>
        <xrd:userId>${userId}</xrd:userId>
        <xrd:id>${uuid}</xrd:id>
        <xrd:service>${producer}.allowedMethods</xrd:service>
        <xrd:issue/>
    </SOAP-ENV:Header>
    <SOAP-ENV:Body>
        <xrd:allowedMethods/>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOF
)
echo "${paring}" > ${FILE_PARING}
echo -e "${red}Päring andmekogusse${NC} ${producer}\n"
echo -e "${producer}\n" >> ${FILE_TEENUSED}
# päritakse  andmkekogu teenindava turvaserverilt mis teenused on avatud (wget)
# päritakse 1 kord(tries) ja kui 5 sekundi(timeout) jooksul vastust ei saa katkestatakse päring.
# kuvatakse tulemust(tee /dev/tty)
# koostatakse nimekirja avatud teenustest(perl)
# tulemus salvestatakse faili ${FILE_TEENUSED} (tee -a)
wget --header='SOAPAction:' --header='Content-Type: text/xml' \
--post-file ${FILE_PARING} http://${tsip}:${port}/cgi-bin/consumer_proxy --timeout='5' --tries='1' -O- 2>&1 | tee /dev/tty \
| perl -lne 'BEGIN{undef $/} while (/<item>(.*?)<\/item>/sg){print $1}' \
| tee -a ${FILE_TEENUSED}
echo -e "\n" >> ${FILE_TEENUSED}
echo
done

echo "TEENUSTE NIMEKIRI SALVESTATI faili ${FILE_TEENUSED}"
exit 0
