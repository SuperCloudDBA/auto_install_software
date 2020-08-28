#!/bin/bash

# https://www.keepalived.org/doc/
# version keepalived-2.0.18.tar.gz

# Install Prerequisites on RHEL/CentOS
yum install -y curl gcc openssl-devel libnl3-devel net-snmp-devel

cd /alidata/install
tar -xf keepalived-2.0.18.tar.gz
cd keepalived-2.0.18
./configure --prefix=/alidata/keepalived-2.0.18 --with-init=systemd
make
make install
mkdir -p /alidata//keepalived-2.0.18/scripts
mkdir -p /alidata//keepalived-2.0.18/logs

sed -i "s@-D@-f /alidata/keepalived-2.0.18/etc/keepalived/keepalived.conf -D -d -S 0@" /alidata/keepalived-2.0.18/etc/sysconfig/keepalived
cat >> /etc/rsyslog.conf << ENDF
local0.*                                                /var/log/keepalived.log
ENDF
systemctl restart rsyslog


