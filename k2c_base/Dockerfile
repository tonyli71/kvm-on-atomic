# kvm on Atomic Host Base
# Version 1

FROM rhel7/rhel-tools:latest

USER root

MAINTAINER Tony Li

ENV container docker

LABEL Version=1.0
LABEL Vendor="Red Hat" License=GPLv3

ADD local.repo /etc/yum.repos.d/local.repo

RUN mkdir -p /run/lock ; yum --disablerepo=* --enablerepo=lrhel* install -y deltarpm yum-utils  perl-Data-Dumper \
openssh-server keepalived rp-pppoe ppp \
iproute iptables-services openswan xl2tpd \
libvirt qemu-kvm virt-manager virt-install libguestfs-tools \
xorg-x11-apps xauth virt-viewer \
libguestfs-xfs \
openstack-utils ;\ 
yum --disablerepo=* --enablerepo=lrhel* update -y ; yum clean all 

ADD root /

RUN ln -sf dbus.service /etc/systemd/system/messagebus.service; \
chmod -v +x /bin/systemctl /usr/bin/systemctl-socket-daemon; \
chmod -v +x /usr/sbin/keepalived_phys_mon.sh /usr/sbin/keepalived_phys.sh; \
sed  -i "s/#user = \"root\"/user = \"root\"/g" /etc/libvirt/qemu.conf; \
sed  -i "s/#group = \"root\"/group = \"root\"/g" /etc/libvirt/qemu.conf;

CMD ["-D", "FOREGROUND"]

