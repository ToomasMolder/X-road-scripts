#!/usr/bin/python

import sys
import re
import json

memberName = {}
with open('RIHA_membercode-membername.txt', 'r') as f:
    for line in f:
        # Example: 10178070	Elisa Eesti AS
        line = line.strip('\r\n')
        arr = line.split('\t')
        memberName[arr[0]] = arr[1]

subSystemName = {}
with open('RIHA_subsystemcode-subsystemname.txt', 'r') as f:
    for line in f:
        # Example: 10256137	10256137-posr	Positiivne register	Positive credit bureau
        line = line.strip('\r\n')
        arr = line.split('\t')
        id = '{}/{}'.format(arr[0], arr[1])
        val = {'et': arr[2], 'en': arr[3]}
        subSystemName[id] = val

        # Fix for RIHA
        m = re.match("^(\d{8})-(.+)$", arr[1])
        if m:
            # RIHA "10264823/10264823-maais" subsystem might be X-Road "10264823/maais" subsystem
            id2='{}/{}'.format(arr[0], m.group(2))
            subSystemName[id2] = val

            # RIHA "70000562/70008440-viisaregister" might be X-Road "70008440/viisaregister"
            id3='{}/{}'.format(m.group(1), m.group(2))
            subSystemName[id3] = val

email = {}
with open('RIHA_subsystemcode-contacts.txt', 'r') as f:
    for line in f:
        # Example:
        # 70007647	70007647-misp2	Eesnimi	Perenimi	email
        # 70007647	70007647-misp2	Eesnimi	Perenimi	email
        line = line.strip('\r\n')
        arr = line.split('\t')
        id = '{}/{}'.format(arr[0], arr[1])
        val = {'email': arr[4], 'name': '{} {}'.format(arr[2], arr[3])}
        if id not in email:
            email[id] = []
        email[id].append(val)

        # Fix for RIHA
        m = re.match("^(\d{8})-(.+)$", arr[1])
        if m:
            # RIHA "10264823/10264823-maais" subsystem might be X-Road "10264823/maais" subsystem
            id2='{}/{}'.format(arr[0], m.group(2))
            if id2 not in email:
                email[id2] = []
            email[id2].append(val)

            # RIHA "70000562/70008440-viisaregister" might be X-Road "70008440/viisaregister"
            id3='{}/{}'.format(m.group(1), m.group(2))
            if id3 not in email:
                email[id3] = []
            # Avoiding duplicate addition if keys are the same
            if id2 != id3:
                email[id3].append(val)


# f = open('riha.json', 'w')
jsonDataArr = []
for line in sys.stdin:
    # Example: EE/GOV/70006317/monitoring
    line = line.strip()
    arr = line.split('/')
    id = '{}/{}'.format(arr[2], arr[3])
    jsonData = {
        'x_road_instance': arr[0],
        'member_class': arr[1],
        'member_code': arr[2],
        'member_name': memberName[arr[2]] if arr[2] in memberName else None,
        'subsystem_code': arr[3],
        'subsystem_name': subSystemName[id] if id in subSystemName else {'et': '', 'en': ''},
        'email': email[id] if id in email else []
    }
    # f.write(json.dumps(jsonData, indent=2, ensure_ascii=False)+'\n')
    # print (json.dumps(jsonData, indent=2, ensure_ascii=False))
    jsonDataArr.append(jsonData)
# f.close()

# with open('riha.json', 'w') as f:
#     json.dump(jsonDataArr, f, indent=2, ensure_ascii=False)

print (json.dumps(jsonDataArr, indent=2, ensure_ascii=False))
