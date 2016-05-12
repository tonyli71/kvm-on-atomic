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
LABEL RUN="systemctl restart k2c_demo.service" 
LABEL Name=k2c_demo BZComponent=k2c-demo-docker Authoritative_Registry=registry.tonyli71.linkpc.net Build_Host=atomic0.tli.redhat.com build-date=2016-05-10T09:29:47.480951Z

RUN rm -rf /root/net-*;
ADD root /
ADD k2c_demo /usr/sbin/k2c_demo
RUN chmod -v +x /usr/sbin/k2c_demo

ENTRYPOINT /usr/sbin/k2c_demo
