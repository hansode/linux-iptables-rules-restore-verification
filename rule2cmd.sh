#!/bin/bash
#
# requires:
#  bsah
#
set -e
set -o pipefail

table=
line=

while read line; do
  case "${line}" in
    "" | "#*")
      ;;
    \**)
      table=${line##\*}
      ;;
    :INPUT* | :FORWARD* | :OUTPUT* | :PREROUTING* | :POSTROUTING* | :OUTPUT*)
      ;;
    :*)
      chain=${line##:}
      chain=${chain%% *}
      echo iptables -t ${table} -N ${chain}
      ;;
    -*)
      echo iptables -t ${table} ${line}
      ;;
  esac
done < /dev/stdin
