#! /usr/bin/bash

if [ ! -f /root/updated ] ; then

yum -y install rp-pppoe openswan xl2tpd
yum -y install sudo python-rdomanager-oscplugin rabbitmq-server facter openstack-utils keepalived iptables-services
yum -y update

systemctl disable  firewalld.service
systemctl disable  NetworkManager.service
systemctl enable iptables.service

ipaddr=$(facter ipaddress_eth0)
echo -e "$ipaddr\t\t<<undercloud.redhat.local>>\t<<undercloud>>" >> /etc/hosts

hostname <<undercloud.redhat.local>>
hostnamectl set-hostname <<undercloud.redhat.local>>
systemctl restart network.service

useradd stack
echo "Redhat01" | passwd stack --stdin
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack

sed -i "s/Defaults    requiretty/#Defaults    requiretty/g" /etc/sudoers

cp /usr/lib/python2.7/site-packages/instack_undercloud/undercloud.py /usr/lib/python2.7/site-packages/instack_undercloud/undercloud.py.org
cp /usr/lib/python2.7/site-packages/instack_undercloud/undercloud.py.tli /usr/lib/python2.7/site-packages/instack_undercloud/undercloud.py

chmod +x /etc/systemd/system/osp-uc-conf.service
openstack-config --set /etc/systemd/system/osp-uc-conf.service Service TTYPath /dev/tty1
systemctl enable osp-uc-conf.service

touch /root/updated

fi

if [ ! -f /home/stack/undercloud.conf ] ; then 

sudo -u stack /usr/bin/bash -c  "cp /usr/share/instack-undercloud/undercloud.conf.sample ~/undercloud.conf"
sudo -u stack /usr/bin/bash -c  "openstack-config --set ~/undercloud.conf DEFAULT local_ip XXX.XXX.10.1/16"
sudo -u stack /usr/bin/bash -c  "openstack-config --set ~/undercloud.conf DEFAULT undercloud_public_vip  XXX.XXX.10.10"
sudo -u stack /usr/bin/bash -c  "openstack-config --set ~/undercloud.conf DEFAULT undercloud_admin_vip XXX.XXX.10.11"
sudo -u stack /usr/bin/bash -c  "openstack-config --set ~/undercloud.conf DEFAULT local_interface eth0"
sudo -u stack /usr/bin/bash -c  "openstack-config --set ~/undercloud.conf DEFAULT masquerade_network XXX.XXX.0.0/16"
sudo -u stack /usr/bin/bash -c  "openstack-config --set ~/undercloud.conf DEFAULT dhcp_start XXX.XXX.10.20"
sudo -u stack /usr/bin/bash -c  "openstack-config --set ~/undercloud.conf DEFAULT dhcp_end XXX.XXX.10.120"
sudo -u stack /usr/bin/bash -c  "openstack-config --set ~/undercloud.conf DEFAULT network_cidr XXX.XXX.0.0/16"
sudo -u stack /usr/bin/bash -c  "openstack-config --set ~/undercloud.conf DEFAULT network_gateway XXX.XXX.0.1"
sudo -u stack /usr/bin/bash -c  "openstack-config --set ~/undercloud.conf DEFAULT inspection_iprange  XXX.XXX.10.150,XXX.XXX.10.180"

fi

#cat << EOF >> /etc/rc.local
#sleep 60
#sudo -u stack /usr/bin/bash -c  "openstack undercloud install | tee /home/stack/undercloud-install.log "
#sed -i -i "s/sudo -u stack/#sudo -u stack/g"  /etc/rc.local
#EOF

#chmod -v +x /etc/rc.local
#chmod -v +x /etc/rc.local/etc/rc.local

reboot

