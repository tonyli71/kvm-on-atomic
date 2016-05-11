#! /usr/bin/bash
yum -y install keepalived rp-pppoe iptables-services openswan xl2tpd
yum -y update

restorecon -Rv /etc/xl2tpd
cp /etc/ppp/ip-up.my /etc/ppp/ip-up
cp /etc/keepalived/keepalived_vm.conf /etc/keepalived/keepalived.conf
restorecon -Rv /etc/ppp

cp /etc/systemd/system/xl2tpd2701.service /lib/systemd/system/xl2tpd2701.service
chmod +x /usr/sbin/xl2tpd2701 
chcon -v -R -u system_u -r object_r -t mount_exec_t /usr/sbin/xl2tpd2701

systemctl enable iptables.service
systemctl enable keepalived.service
systemctl enable ipsec.service
systemctl enable xl2tpd.service
systemctl enable xl2tpd2701.service

reboot
