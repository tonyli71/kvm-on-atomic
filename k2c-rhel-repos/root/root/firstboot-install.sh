#! /usr/bin/bash
yum -y install keepalived rp-pppoe iptables-services openswan xl2tpd
yum -y update

systemctl disable  firewalld.service
systemctl enable iptables.service

reboot
