#! /usr/bin/bash

if [ ! -f /root/updated ] ; then

yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion vim lrzsz unzip;
yum -y update
yum -y install atomic-openshift-utils

systemctl disable  firewalld.service
systemctl disable  NetworkManager.service
systemctl enable iptables.service

ipaddr=$(facter ipaddress_eth0)

sed -i "s/Defaults    requiretty/#Defaults    requiretty/g" /etc/sudoers

touch /root/updated

#create internal database

appliance_console << EOF

8

1

0
redhat
redhat


15
2
Y
EOF

#Config OSE 3.2
cat > /etc/ansible/hosts <<EOF
[OSEv3:children]
masters
nodes

[OSEv3:vars]
ansible_ssh_user=root
openshift_use_dnsmasq=False
deployment_type=openshift-enterprise
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

[masters]
ose32-master.tli.redhat.com

[nodes]
ose32-master.tli.redhat.com
ose32-node-rhel-0.tli.redhat.com
ose32-node-rhel-1.tli.redhat.com

EOF

# ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml

cat > /etc/dnsmasq.d/openshift-cluster.conf <<EOF

EOF


fi

