#!/bin/bash
#Vassil Marjunits (Vasell Marjumets), help@ria.ee

rm paring.xml teenused.txt 2> /dev/null
port="80"
echo
echo "NB! Skript tuleb käivitada TURVASERVERIS"

echo
echo -e "Sisesta X-tee KESKKONNA LÜHEND kus skript käivitatakse:\n to = toodang\n te = test\n ar = arendus\n ja vajuta ENTER\n"
read keskkond
echo

echo -e "Sisesta ASUTUSE REGISTRIKOOD (X-tee teenuste tarbija - consumer), ja vajuta ENTER:\n"
read consumer
echo

echo -e "Sisesta turvaserveri IP (sisemine liides), kus skript käivitatakse ja vajuta ENTER\n"
read tsip
echo

echo -e "Sisesta turvaserveri PORT, vaikimisi on 80, ja vajuta ENTER\n"
read port
echo

echo "PÄRITAKSE ANDMEID, PALUN OOTA..."
echo

red='\e[0;31m'
NC='\e[0m'

case "$keskkond" in
'to')
	KS=195.80.107.58 # Toodang Keskserver
;;
'te')
	KS=195.80.127.6	# Test Keskserver
;;
'ar')
	KS=195.80.109.163 #Arendus Keskserver
;;
*)
echo "Sisestasid mingi jama. Käivita uuesti skript"
exit 0
;;
esac

# päritakse keskserveris andmekogude nimekirja
for producer in $(dig allproducers.xtee.riik.ee txt @$KS | grep TXT \
| grep -v ";allprod" | awk '{ print $5 }' | sed 's/"//' | sed 's/"//' | sort);do
#allowedMethods päringu koostamine
paring=$(cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<SOAP-ENV:Envelope
        xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
        xmlns:xrd="http://x-road.ee/xsd/x-road.xsd">
    <SOAP-ENV:Header>
        <xrd:consumer>$consumer</xrd:consumer>
        <xrd:producer>$producer</xrd:producer>
        <xrd:userId>EE30101010007</xrd:userId>
        <xrd:id >411d6755661409fed365ad8135f8210be07613da</xrd:id>
        <xrd:service>$producer.allowedMethods</xrd:service>
        <xrd:issue/>
    </SOAP-ENV:Header>
    <SOAP-ENV:Body>
        <xrd:allowedMethods/>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOF
)
echo "$paring" > /tmp/paring.xml
echo -e "${red}Päring andmekogusse${NC} $producer\n"
echo -e "$producer\n" >> teenused.txt
# päritakse  andmkekogu teenindava turvaserverilt mis teenused on avatud (wget)
# päritakse 1 kord(tries) ja kui 5 sekundi(timeout) jooksul vastust ei saa katktestatakse päring.
# kuvatakse tulemust(tee /dev/tty)
# koostatakse nimekirja avatud teenustest(perl)
# tulemus salvestatakse faili teenused.txt (tee -a)
wget --header='SOAPAction:' --header='Content-Type: text/xml' \
--post-file /tmp/paring.xml http://$tsip:$port/cgi-bin/consumer_proxy --timeout='5' --tries='1' -O- 2>&1 | tee /dev/tty \
| perl -lne 'BEGIN{undef $/} while (/<item>(.*?)<\/item>/sg){print $1}' \
| tee -a /tmp/teenused.txt
echo -e "\n" >> teenused.txt
echo
done

echo "TEENUSTE NIMEKIRI SALVESTATI faili teenused.txt mis asub /tmp kaustas"
exit 0
