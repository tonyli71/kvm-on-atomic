# k2c_demo on Atomic Host
# Version 1

FROM k2c_with_rhel_qcow

USER root

MAINTAINER Tony Li

ENV container docker

LABEL Version=1.0
LABEL Vendor="Red Hat" License=GPLv3
LABEL INSTALL="docker run --rm --privileged -v /:/host -e HOST=/host -e IMAGE=IMAGE -e NAME=NAME -e ACTION=install -e MY_IP=\${MY_IP} -e VM_IP=\${VM_IP} -e YUM_REPO_PREFIX=\${YUM_REPO_PREFIX} -e MY_PREFIX=\${MY_PREFIX} -e MY_GATEWAY=\${MY_GATEWAY} -e MY_HOSTNAME=\${MY_HOSTNAME} -e VM_VCPU=\${VM_VCPU} -e VM_RAM=\${VM_RAM} -e VNC_PORT=\${VNC_PORT} -e MY_VMNAME=\${MY_VMNAME} IMAGE"
LABEL UNINSTALL="docker run --rm --privileged -v /:/host -e HOST=/host -e IMAGE=IMAGE -e NAME=NAME -e ACTION=uninstall IMAGE"
LABEL RUN="systemctl restart k2c-osp8-undercloud.service" 
LABEL Name=tonyli71/k2c-osp8-undercloud BZComponent=k2c-osp8-undercloud-docker Authoritative_Registry=registry.tonyli71.linkpc.net Build_Host=atomic0.tli.redhat.com build-date=2016-05-10T09:29:47.480951Z

ADD local.repo /etc/yum.repos.d/local.repo

RUN rm -rf /root/net-*; mv /usr/bin/yum /usr/bin/yum.org ; echo  '/usr/bin/yum.org --disablerepo=* --enablerepo=lrhel* $@' > /usr/bin/yum; chmod -v +x /usr/bin/yum;\
yum -y install sudo python-rdomanager-oscplugin rabbitmq-server facter openstack-utils keepalived iptables-services pystache xinetd httpd \
openstack-neutron* openstack-ironic* openstack-nova* openstack-tripleo* openstack-heat* openstack-keystone* openstack-glance* \
openstack-puppet-modules* puppet selinux-policy-devel ansible;\
yum -y update; useradd stack;\
echo "redhat" | passwd root --stdin ;\
echo "redhat" | passwd stack --stdin;\
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack;\
chmod 0440 /etc/sudoers.d/stack;\
sed -i "s/Defaults    requiretty/#Defaults    requiretty/g" /etc/sudoers;\
sudo -u stack /usr/bin/bash -c  "cp /usr/share/instack-undercloud/undercloud.conf.sample ~/undercloud.conf";\
sudo -u stack /usr/bin/bash -c  "openstack-config --set ~/undercloud.conf DEFAULT local_interface em0";\
mkdir -p /data;

ADD root /
ADD k2c-osp8-undercloud /usr/sbin/k2c-osp8-undercloud
RUN chmod -v +x /usr/sbin/k2c-osp8-undercloud

VOLUME /data

ENTRYPOINT /usr/sbin/k2c-osp8-undercloud
