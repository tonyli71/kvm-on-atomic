#! /usr/bin/bash

if [ ! -f /root/updated ] ; then

#yum -y update

systemctl disable  firewalld.service
systemctl disable  NetworkManager.service
systemctl enable iptables.service

ipaddr=$(facter ipaddress_eth0)

sed -i "s/Defaults    requiretty/#Defaults    requiretty/g" /etc/sudoers

touch /root/updated

fi

