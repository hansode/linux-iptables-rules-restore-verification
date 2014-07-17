```
$ key=$(grep -w 'FORWARD -m' iptables-saved  | awk '{print $6}' | sort | uniq | tail -3 | xargs echo | sed 's, ,|,g')
$ egrep -v "${key}" iptables-saved > iptables-saved.vif-67eaawlf
```
