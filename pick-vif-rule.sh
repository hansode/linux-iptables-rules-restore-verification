#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail

vifs="${@}"

while read line; do
  if [[ ${line} =~ "vif-" ]]; then
    for vif in ${vifs}; do
      [[ ${line} =~ "${vif}" ]] || continue
      echo ${line}
    done
  else
    echo ${line}
  fi
done < /dev/stdin
