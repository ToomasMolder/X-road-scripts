# getService.sh skript

Otsib vastust küsimusele millised  X-tee teenused on avatud asutusele kasutamiseks

Skrip esitab asutuse (consumer) nimel allowedMethods päringu turvaserveri kaudu kõikide andmekogude (producer) turvaserveritele.

Päringu vastuse tulemus salvestatakse /tmp/ kausta, teenused.txt faili.
Õnnestunud vastuses on kujul: andmekogu lühinimi ja teenuste loetelu selle all.  
nt: 

    e-toimik
    
    e-toimik.MingiXteeTeenus1.v1
    e-toimik.MingiXteeTeenus2.v1


NB1! Skript käivitatakse turvaserveris (root õigustes).

NB2! Teenuseid ei kuvata kui turvaserver ei vasta päringule - teadmata põhjusel (jälgi terminalis veateateid)

NB3! Kui andmekogu turvaserver ei vasta 5 sekundi jooksul esimesel pöörumisel (`timeout='5'`), pöördutakse järgmise andmekogu poole.
