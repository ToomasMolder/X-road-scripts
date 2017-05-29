#!/bin/bash

# List of servers
DATA="XTEE-CI/GOV/00000000/00000000_1/xtee4.ci.kit
XTEE-CI/GOV/00000001/00000001_1/xtee5.ci.kit
XTEE-CI/COM/00000002/00000002_1/xtee6.ci.kit"

# For static list of servers it is enough to run the following line only once
#echo "$DATA" | python add_hosts.py

echo "$DATA" | python push_metrics.py
