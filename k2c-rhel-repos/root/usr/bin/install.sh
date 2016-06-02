#!/usr/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

# Make Data Dirs
mkdir -p ${HOST}/${CONFDIR} ${HOST}/${LOGDIR}/k2c ${HOST}/${DATADIR} ${HOST}/var/opt

if [ "$MY_IP" != "" ] ; then

# Copy Exe file 
touch ${HOST}/var/opt/run_${NAME}
cp -p /usr/bin/run_k2c ${HOST}/var/opt/run_${NAME}
chcon -v -R -u system_u -r object_r -t mount_exec_t ${HOST}/var/opt/run_${NAME}

if [ "$MY_HOSTNAME" == "" ] ; then
      MY_HOSTNAME=${NAME}
fi

# Create Container
chroot ${HOST} /usr/bin/docker create --privileged --net=none -ti -h ${MY_HOSTNAME} -e NAME=${NAME} -e MY_IP=${MY_IP} -e VM_IP=${VM_IP} -v ${YUM_REPO_PATH}:/var/www/html/repos -e MY_PREFIX=${MY_PREFIX} -e MY_GATEWAY=${MY_GATEWAY} --name ${NAME} ${IMAGE}

# Install systemd unit file for running container
sed -e "s/TEMPLATE/${NAME}/g" /etc/systemd/system/k2c_template.service > ${HOST}/etc/systemd/system/${NAME}.service

# Enabled systemd unit file
chroot ${HOST} /usr/bin/systemctl enable ${NAME}.service

    echo "you run it with following command :"
    echo "/usr/bin/systemctl start ${NAME}.service" 

else

   echo "Usage: before install you need export following Env"
   echo "export MY_IP=xxx.xxx.xxx.xxx"
   echo "atomic install --name <contaner name> k2c_demo"

fi
