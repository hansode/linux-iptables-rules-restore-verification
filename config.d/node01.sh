#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -x

# Do some changes ...

rsync -avx /vagrant/iptables-saved /etc/sysconfig/iptables

service iptables restart
service iptables status
