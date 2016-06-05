# my ipa-server service on Atomic Host
# Version 1

FROM k2c_base

#FROM rhel7:latest

USER root

MAINTAINER Tony Li

ENV container docker

LABEL Version=1.0
LABEL Vendor="Red Hat" License=GPLv3
LABEL INSTALL="docker run --rm --privileged -v /:/host -e HOST=/host -e IMAGE=IMAGE -e NAME=NAME -e ACTION=install -e ADMIN_PASSWORD=\${ADMIN_PASSWORD} -e MY_IFNAME=\${MY_IFNAME} -e MY_IP=\${MY_IP} -e VM_IP=\${VM_IP} -e MY_DATA=\${MY_DATA} -e MY_PREFIX=\${MY_PREFIX} -e MY_GATEWAY=\${MY_GATEWAY} -e MY_HOSTNAME=\${MY_HOSTNAME} -e MY_DNS=\${MY_DNS} -e FORWARDER=\${FORWARDER} -e DATAPATH=\${DATAPATH} IMAGE"
LABEL UNINSTALL="docker run --rm --privileged -v /:/host -e HOST=/host -e IMAGE=IMAGE -e NAME=NAME -e ACTION=uninstall IMAGE"
LABEL RUN="systemctl restart k2c-ipa-server.service"
LABEL Name=tonyli71/k2c-ipa-server BZComponent=k2c-ipa-server-docker Authoritative_Registry=registry.tonyli71.linkpc.net Build_Host=atomic0.tli.redhat.com build-date=2016-05-10T09:29:47.480951Z

ADD local.repo /etc/yum.repos.d/local.repo

RUN rm -rf /root/net-*;\
mv /usr/bin/yum /usr/bin/yum.org ; echo  '/usr/bin/yum.org --disablerepo=* --enablerepo=lrhel* $@' > /usr/bin/yum; chmod -v +x /usr/bin/yum;\
yum -y install xinetd httpd procps-ng \
ansible \
389-ds-base bind bind-dyndb-ldap perl tomcat xorg-x11-utils certmonger wget log4j pango tar zip ipa-client GConf2 acl \
ant antlr-tool apache-commons-cli apache-commons-codec apache-commons-io apache-commons-lang apr apr-util args4j bcel bea-stax bea-stax-api \
codemodel dom4j easymock2 fontawesome-fonts glassfish-dtd-parser glassfish-fastinfoset glassfish-jaxb glassfish-jaxb-api hamcrest hsqldb \
httpcomponents-client httpcomponents-core httpd httpd-tools ipa-admintools isorelax java-atk-wrapper javassist jaxen jakarta-commons-httpclient jakarta-oro jboss-annotatbons-1.1-api jdom jettison jing jss junit jvnet-parent krb5-pkinit krb5-server ldapjdk libunistring \
memcached mod_auth_kerb mod_nss mod_wsgi mozjs17 net-tools open-sans-fonts \
perl-Business-ISBN perl-Business-ISBN-Data perl-Crypt-SSLeay perl-Digest perl-Digest-MD5 \
perl-Encode-Locale perl-File-Listing perl-File-Slurp \
perl-HTTP-Cookies perl-HTTP-Daemon perl-HTTP-Date perl-HTTP-Message perl-HTTP-Negotiate \
perl-HTML-Parser perl-HTML-Tagset perl-IO-HTML perl-IO-Socket-IP perl-IO-Socket-SSL \
perl-LWP-MediaTypes perl-Net-HTTP perl-Net-LibIDN perl-Net-SSLeay perl-TimeDate perl-URI \
perl-WWW-RobotRules perl-XML-LibXML perl-XML-NamespaceSupport \
perl-XML-SAX perl-XML-SAX-Base perl-libwww-perl \
pki-base pki-ca pki-server pki-tools \
python-memcached python-requests python-urllib3 \
ipa-server* \
openssh-server;\
yum -y update;\
groupadd -g 389 dirsrv ; useradd -u 389 -g 389 -c 'DS System User' -d '/var/lib/dirsrv' --no-create-home -s '/sbin/nologin' dirsrv;\
groupadd -g 17 pkiuser || true ; useradd -u 17 -g 17 -c 'CA System User' -d '/var/lib' --no-create-home -s '/sbin/nologin' pkiuser || true;\
echo "redhat" | passwd root --stdin ;\
mkdir -p /run/lock

ADD root /

EXPOSE 22 53/udp 53 80 443 389 636 88 464 88/udp 464/udp 123/udp 7389 9443 9444 9445 8005

VOLUME /data

ADD k2c-ipa-server /usr/sbin/k2c-ipa-server
RUN chmod -v +x /usr/sbin/k2c-ipa-server
ENTRYPOINT /usr/sbin/k2c-ipa-server

