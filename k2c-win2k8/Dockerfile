# k2c-win2k8 on Atomic Host
# Version 1

FROM k2c_base

USER root

MAINTAINER Tony Li

ENV container docker

LABEL Version=1.0
LABEL Vendor="Red Hat" License=GPLv3
LABEL INSTALL="docker run --rm --privileged -v /:/host -e HOST=/host -e IMAGE=IMAGE -e NAME=NAME -e ACTION=install -e MY_IFNAME=\${MY_IFNAME} -e MY_IP=\${MY_IP} -e VM_IP=\${VM_IP} -e MY_PREFIX=\${MY_PREFIX} -e MY_GATEWAY=\${MY_GATEWAY} -e MY_IFNAME1=\${MY_IFNAME1} -e MY_IP1=\${MY_IP1} -e VM_IP1=\${VM_IP1} -e MY_PREFIX1=\${MY_PREFIX1} -e MY_GATEWAY1=\${MY_GATEWAY1} -e MY_IFNAME2=\${MY_IFNAME2} -e MY_IP2=\${MY_IP2} -e VM_IP2=\${VM_IP2} -e MY_PREFIX2=\${MY_PREFIX2} -e MY_GATEWAY2=\${MY_GATEWAY2} -e MY_IFNAME3=\${MY_IFNAME3} -e MY_IP3=\${MY_IP3} -e VM_IP3=\${VM_IP3} -e MY_PREFIX3=\${MY_PREFIX3} -e MY_GATEWAY3=\${MY_GATEWAY3} -e YUM_REPO_PREFIX=\${YUM_REPO_PREFIX} -e MY_HOSTNAME=\${MY_HOSTNAME} -e VM_VCPU=\${VM_VCPU} -e VM_RAM=\${VM_RAM} -e VM_SIZE=\${VM_SIZE} -e VM_DAT_SIZE=\${VM_DAT_SIZE} -e VNC_PORT=\${VNC_PORT} -e MY_VMNAME=\${MY_VMNAME} -e DATAPATH=\${DATAPATH} IMAGE"
LABEL UNINSTALL="docker run --rm --privileged -v /:/host -e HOST=/host -e IMAGE=IMAGE -e NAME=NAME -e ACTION=uninstall IMAGE"
LABEL RUN="systemctl restart k2c-win2k8.service" 
LABEL Name=tonyli71/k2c-win2k8 BZComponent=k2c-win2k8-docker Authoritative_Registry=registry.tonyli71.linkpc.net Build_Host=atomic0.tli.redhat.com build-date=2016-05-10T09:29:47.480951Z

ADD win2k8.qcow2 /var/lib/libvirt/images/win-guest.qcow2
ADD ntfs-3g-2016.2.22-1.el7.x86_64.rpm /
ADD virtio-win-1.8.0-4.el7.noarch.rpm /
ADD chntpw-0.99.6-22.110511.el7.nux.x86_64.rpm /
ADD local.repo /etc/yum.repos.d/local.repo
RUN rm -rf /root/net-*; mv /usr/bin/yum /usr/bin/yum.org ; echo  '/usr/bin/yum.org --disablerepo=* --enablerepo=lrhel* $@' > /usr/bin/yum; chmod -v +x /usr/bin/yum;\
yum -y install sudo python-rdomanager-oscplugin rabbitmq-server facter openstack-utils keepalived iptables-services pystache xinetd httpd \
openstack-puppet-modules* puppet selinux-policy-devel ansible dos2unix libguestfs libguestfs-tools libguestfs-winsupport virt-v2v qemu-guest-agent;\
yum -y update; rpm -ihv ntfs-3g-2016.2.22-1.el7.x86_64.rpm; rpm -ihv virtio-win-1.8.0-4.el7.noarch.rpm; rpm -ihv chntpw-0.99.6-22.110511.el7.nux.x86_64.rpm; \
echo "redhat" | passwd root --stdin ;\
echo "redhat" | passwd stack --stdin;\
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack;\
chmod 0440 /etc/sudoers.d/stack;\
sed -i "s/Defaults    requiretty/#Defaults    requiretty/g" /etc/sudoers;\
mkdir -p /data;

ADD root /
ADD k2c-win2k8 /usr/sbin/k2c-win2k8
RUN chmod -v +x /usr/sbin/k2c-win2k8

VOLUME /data

ENTRYPOINT /usr/sbin/k2c-win2k8
