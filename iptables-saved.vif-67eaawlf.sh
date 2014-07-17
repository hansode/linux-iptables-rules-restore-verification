#!/bin/bash
#
# requires:
#  bash
#

vif=vif-67eaawlf

host_addr=10.112.8.45
network=10.112.8.0/24
inst_addr=10.112.9.122
zabbix_addr=10.112.8.32
friend_addrs="10.112.9.98 10.112.9.119 10.112.9.97 10.112.9.63"

cat <<_RULE_
# filter table
*filter
## standard chains
:INPUT   ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT  ACCEPT [0:0]
## secg chains
:d_${vif} - [0:0]
:d_${vif}_icmp - [0:0]
:d_${vif}_tcp  - [0:0]
:d_${vif}_udp  - [0:0]
:s_${vif} - [0:0]
:s_${vif}_icmp - [0:0]
:s_${vif}_tcp  - [0:0]
:s_${vif}_udp  - [0:0]
## rules
### host fw: fluentd
-A INPUT -d ${host_addr}/32 -i brpub -p tcp -m physdev --physdev-in vif-+ -m tcp --dport 24224 -j ACCEPT 
-A INPUT -d ${host_addr}/32 -i brpub -p udp -m physdev --physdev-in vif-+ -m udp --dport 24224 -j ACCEPT 
-A INPUT -d ${network}  -i brpub -m physdev --physdev-in vif-+ -j REJECT --reject-with icmp-port-unreachable 
### FORWARD routing
-A FORWARD -m physdev --physdev-in  ${vif} --physdev-is-bridged -j s_${vif} 
-A FORWARD -m physdev --physdev-out ${vif} --physdev-is-bridged -j d_${vif} 
### inbound routing
-A d_${vif} -p icmp -m state --state NEW,RELATED,ESTABLISHED -j d_${vif}_icmp 
-A d_${vif} -p udp  -m state --state NEW,ESTABLISHED         -j d_${vif}_udp 
-A d_${vif} -p tcp  -m state --state NEW,ESTABLISHED         -j d_${vif}_tcp 
### in-icmp
#### zabbix
-A d_${vif}_icmp -s ${zabbix_addr}/32 -p icmp -j ACCEPT 
#### secg
$(proto=icmp
  for friend_addr in ${friend_addrs}; do echo -A d_${vif}_${proto} -s ${friend_addr}/32 -j ACCEPT; done)
-A d_${vif}_icmp -p icmp -m state --state RELATED,ESTABLISHED -j ACCEPT 
-A d_${vif}_icmp -j DROP 
### in-tcp
#### zabbix
-A d_${vif}_tcp -s ${zabbix_addr}/32 -p tcp -m tcp --dport 1:65535 -j ACCEPT 
#### secg
$(proto=tcp
  for friend_addr in ${friend_addrs}; do echo -A d_${vif}_${proto} -s ${friend_addr}/32 -j ACCEPT; done)
-A d_${vif}_tcp -p tcp -m state --state RELATED,ESTABLISHED -j ACCEPT 
-A d_${vif}_tcp -j DROP 
### in-udp
#### zabbix
-A d_${vif}_udp -s ${zabbix_addr}/32 -p udp -m udp --dport 10050:10051 -j ACCEPT 
#### secg
$(proto=udp
  for friend_addr in ${friend_addrs}; do echo -A d_${vif}_${proto} -s ${friend_addr}/32 -j ACCEPT; done)
-A d_${vif}_udp -p udp -m state --state ESTABLISHED -j ACCEPT 
-A d_${vif}_udp -j DROP 
### outbound routing
-A s_${vif} -p icmp -j s_${vif}_icmp 
-A s_${vif} -p udp  -j s_${vif}_udp 
-A s_${vif} -p tcp  -j s_${vif}_tcp 
##
COMMIT

# nat table
*nat
## standard chains
:PREROUTING  ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:OUTPUT      ACCEPT [0:0]
## secg chains
:${vif}_snat - [0:0]
:${vif}_snat_exceptions - [0:0]
## rules
### POSTROUTING routing
-A POSTROUTING -s ${inst_addr}/32 -j ${vif}_snat_exceptions 
-A POSTROUTING -s ${inst_addr}/32 -j ${vif}_snat 
##
COMMIT
_RULE_
