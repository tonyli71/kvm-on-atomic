#!/usr/bin/bash
#!/bin/sh

chroot ${HOST} /usr/bin/systemctl disable /etc/systemd/system/${NAME}.service
rm -f ${HOST}/etc/systemd/system/${NAME}.service
rm -f ${HOST}/var/opt/run_${NAME}

