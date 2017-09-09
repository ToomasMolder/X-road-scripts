# getService.sh skript

Otsib vastust küsimusele, millised  X-tee teenused on avatud asutusele kasutamiseks.

Skript esitab asutuse (consumer) nimel allowedMethods päringu turvaserveri kaudu kõikide andmekogude (producer) turvaserveritele.

Päringu vastuse tulemus salvestatakse faili /tmp/teenused.txt (seadistatav).
Õnnestunud vastuses on kujul: andmekogu lühinimi ja teenuste loetelu selle all.  
nt: 

    e-toimik
    
    e-toimik.MingiXteeTeenus1.v1
    e-toimik.MingiXteeTeenus2.v1


NB1! Skript käivitatakse turvaserveris.

NB2! Teenuseid ei kuvata kui turvaserver ei vasta päringule (jälgi terminalis veateateid)

NB3! Kui andmekogu turvaserver ei vasta 5 sekundi jooksul esimesel pöörumisel (`timeout='5'`), pöördutakse järgmise andmekogu poole.
