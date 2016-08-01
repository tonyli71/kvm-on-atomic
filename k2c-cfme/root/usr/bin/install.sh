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

if [ "$MY_VMNAME" == "" ] ; then
          MY_VMNAME=${NAME}
fi
if [ "$VNC_PORT" == "" ] ; then
          VNC_PORT=5910
fi
if [ "$VM_RAM" == "" ] ; then
          VM_RAM=2048
fi
if [ "$VM_VCPU" == "" ] ; then
           VM_VCPU=2
fi


# Create Container

if [ "$DATAPATH" == "" ] ; then
    chroot ${HOST} /usr/bin/docker create --privileged --net=none -ti -h ${MY_HOSTNAME} -e NAME=${NAME} -e MY_IP=${MY_IP} -e VM_IP=${VM_IP} -e YUM_REPO_PREFIX=${YUM_REPO_PREFIX} -e MY_PREFIX=${MY_PREFIX} -e MY_GATEWAY=${MY_GATEWAY} -e VM_VCPU=${VM_VCPU} -e VM_RAM=${VM_RAM} -e VNC_PORT=${VNC_PORT} -e MY_VMNAME=${MY_VMNAME} --name ${NAME} ${IMAGE}
else
    chroot ${HOST} /usr/bin/docker create --privileged --net=none -ti -h ${MY_HOSTNAME} -e NAME=${NAME} -e MY_IP=${MY_IP} -e VM_IP=${VM_IP} -e YUM_REPO_PREFIX=${YUM_REPO_PREFIX} -e MY_PREFIX=${MY_PREFIX} -e MY_GATEWAY=${MY_GATEWAY} -e VM_VCPU=${VM_VCPU} -e VM_RAM=${VM_RAM} -e VNC_PORT=${VNC_PORT} -e MY_VMNAME=${MY_VMNAME} --name ${NAME} -v ${DATAPATH}:/data -e IMAGEPATH=/data ${IMAGE}
fi

# Install systemd unit file for running container
sed -e "s/TEMPLATE/${NAME}/g" /etc/systemd/system/k2c_template.service > ${HOST}/etc/systemd/system/${NAME}.service

# Enabled systemd unit file
chroot ${HOST} /usr/bin/systemctl enable ${NAME}.service

    echo "you run it with following command :"
    echo "/usr/bin/systemctl start ${NAME}.service" 

else

   echo "Usage: before install you need export following Env"
   echo "export MY_IP=xxx.xxx.xxx.xxx"
   echo "export VM_IP=xxx.xxx.xxx.xxx"
   echo "atomic install --name <contaner name> k2c_demo"

fi
