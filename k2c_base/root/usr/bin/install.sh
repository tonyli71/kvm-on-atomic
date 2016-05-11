#!/bin/sh
# Make Data Dirs
#mkdir -p ${HOST}/${CONFDIR} ${HOST}/${LOGDIR}/${NAME} ${HOST}/${DATADIR}

# Copy Config
#cp -pR /etc/keepalived ${HOST}/${CONFDIR}

# Create Container
#chroot ${HOST} /usr/bin/docker create -v /var/log/${NAME}/myrouterd:/var/log/myrouterd:Z -v /var/lib/${NAME}:/var/lib/myrouterd:Z --name ${NAME} ${IMAGE}

# Install systemd unit file for running container
#sed -e "s/TEMPLATE/${NAME}/g" /etc/systemd/system/myrouterd_template.service > ${HOST}/etc/systemd/system/myrouterd_${NAME}.service

# Enabled systemd unit file
#chroot ${HOST} /usr/bin/systemctl enable myrouterd_${NAME}.service

