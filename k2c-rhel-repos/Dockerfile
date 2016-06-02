# my rhel-repos service on Atomic Host
# Version 1

FROM k2c_base

#FROM rhel7:latest

USER root

MAINTAINER Tony Li

ENV container docker

LABEL Version=1.0
LABEL Vendor="Red Hat" License=GPLv3
LABEL INSTALL="docker run --rm --privileged -v /:/host -e HOST=/host -e IMAGE=IMAGE -e NAME=NAME -e ACTION=install -e MY_IP=\${MY_IP} -e VM_IP=\${VM_IP} -e YUM_REPO_PATH=\${YUM_REPO_PATH} -e MY_PREFIX=\${MY_PREFIX} -e MY_GATEWAY=\${MY_GATEWAY} -e MY_HOSTNAME=\${MY_HOSTNAME} -e DATAPATH=\${DATAPATH} IMAGE"
LABEL UNINSTALL="docker run --rm --privileged -v /:/host -e HOST=/host -e IMAGE=IMAGE -e NAME=NAME -e ACTION=uninstall IMAGE"
LABEL RUN="systemctl restart k2c-rhel-repos.service"
LABEL Name=tonyli71/k2c-rhel-repos BZComponent=k2c-rhel-repos-docker Authoritative_Registry=registry.tonyli71.linkpc.net Build_Host=atomic0.tli.redhat.com build-date=2016-05-10T09:29:47.480951Z

ADD local.repo /etc/yum.repos.d/local.repo

RUN rm -rf /root/net-*;\
mv /usr/bin/yum /usr/bin/yum.org ; echo  '/usr/bin/yum.org --disablerepo=* --enablerepo=lrhel* $@' > /usr/bin/yum; chmod -v +x /usr/bin/yum;\
yum -y install xinetd httpd procps-ng \
ansible;\
yum -y update;\
echo "redhat" | passwd root --stdin ;\
mkdir -p /var/www/html/repos;mkdir -p /run/lock;\
chmod 777 /var/www/html/repos; echo "ServerName 127.0.0.1:80" >> /etc/httpd/conf/httpd.conf

ADD root /

VOLUME /var/www/html/repos

EXPOSE 81

ADD k2c-rhel-repos /usr/sbin/k2c-rhel-repos
RUN chmod -v +x /usr/sbin/k2c-rhel-repos
ENTRYPOINT /usr/sbin/k2c-rhel-repos

