#!/bin/sh

SSLOG_DECODER=/usr/local/bin/decode_sslog.pl


case "$1" in


'flow')

tail -f /usr/xtee/var/log/sslog | $SSLOG_DECODER

;;


'log')

cat /usr/xtee/var/log/sslog | $SSLOG_DECODER

;;

*)

echo "Usage: sslog (flow, log)"
exit 1
;;

esac
exit 0
