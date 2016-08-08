#!/usr/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

# Make Data Dirs
mkdir -p ${HOST}/${CONFDIR} ${HOST}/${LOGDIR} ${HOST}/${DATADIR} ${HOST}/var/opt

if [ "$MY_IP" != "" ] ; then

# Copy Exe file 
touch ${HOST}/var/opt/run_${NAME}
#cp -p /usr/bin/run_k2c ${HOST}/var/opt/run_${NAME}
sed -e "s/k2c_demo/${NAME}/g" /usr/bin/run_k2c > ${HOST}/var/opt/run_${NAME}

if [ "$MY_IFNAME" != "" ] ;then
    sed -i "s/Atomic0/${MY_IFNAME}/g"  ${HOST}/var/opt/run_${NAME}
fi

if [ "$MY_IFNAME1" != "" ] ;then
    sed -i "s/Atomic1/${MY_IFNAME1}/g"  ${HOST}/var/opt/run_${NAME}
fi

if [ "$MY_IFNAME2" != "" ] ;then
    sed -i "s/Atomic2/${MY_IFNAME2}/g"  ${HOST}/var/opt/run_${NAME}
fi

if [ "$MY_IFNAME3" != "" ] ;then
    sed -i "s/Atomic3/${MY_IFNAME3}/g"  ${HOST}/var/opt/run_${NAME}
fi

chmod -v +x ${HOST}/var/opt/run_${NAME}
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
    if [ ! -f /tmp/mydata-${NAME}.disk ] ; then
        chroot ${HOST} dd if=/dev/zero of=/tmp/mydata-${NAME}.disk bs=1MiB count=10
        chroot ${HOST} losetup --find --show /tmp/mydata-${NAME}.disk
    fi
    chroot ${HOST} /usr/bin/docker create --privileged --net=none -ti -h ${MY_HOSTNAME} -e NAME=${NAME} -e MY_IFNAME=${MY_IFNAME} -e MY_IP=${MY_IP} -e VM_IP=${VM_IP} -e MY_PREFIX=${MY_PREFIX} -e MY_GATEWAY=${MY_GATEWAY} -e MY_IFNAME1=${MY_IFNAME1} -e MY_IP1=${MY_IP1} -e VM_IP1=${VM_IP1} -e MY_PREFIX1=${MY_PREFIX1} -e MY_GATEWAY1=${MY_GATEWAY1} -e MY_IFNAME2=${MY_IFNAME2} -e MY_IP2=${MY_IP2} -e VM_IP2=${VM_IP2} -e MY_PREFIX2=${MY_PREFIX2} -e MY_GATEWAY2=${MY_GATEWAY2} -e MY_IFNAME3=${MY_IFNAME3} -e MY_IP3=${MY_IP3} -e VM_IP3=${VM_IP3} -e MY_PREFIX3=${MY_PREFIX3} -e MY_GATEWAY3=${MY_GATEWAY3} -e YUM_REPO_PREFIX=${YUM_REPO_PREFIX} -e MY_PREFIX=${MY_PREFIX} -e VM_VCPU=${VM_VCPU} -e VM_RAM=${VM_RAM} -e VM_SIZE=${VM_SIZE} -e VM_DAT_SIZE=${VM_DAT_SIZE} -e VNC_PORT=${VNC_PORT} -e MY_VMNAME=${MY_VMNAME} --name ${NAME} ${IMAGE}
else
    if [ ! -f $DATAPATH/mydata-${NAME}.disk ] ; then
        chroot ${HOST} dd if=/dev/zero of=$DATAPATH/mydata-${NAME}.disk bs=1MiB count=10
        chroot ${HOST} losetup --find --show $DATAPATH/mydata-${NAME}.disk
    fi
    chroot ${HOST} /usr/bin/docker create --privileged --net=none -ti -h ${MY_HOSTNAME} -e NAME=${NAME} -e MY_IFNAME=${MY_IFNAME} -e MY_IP=${MY_IP} -e VM_IP=${VM_IP} -e MY_PREFIX=${MY_PREFIX} -e MY_GATEWAY=${MY_GATEWAY} -e MY_IFNAME1=${MY_IFNAME1} -e MY_IP1=${MY_IP1} -e VM_IP1=${VM_IP1} -e MY_PREFIX1=${MY_PREFIX1} -e MY_GATEWAY1=${MY_GATEWAY1} -e MY_IFNAME2=${MY_IFNAME2} -e MY_IP2=${MY_IP2} -e VM_IP2=${VM_IP2} -e MY_PREFIX2=${MY_PREFIX2} -e MY_GATEWAY2=${MY_GATEWAY2} -e MY_IFNAME3=${MY_IFNAME3} -e MY_IP3=${MY_IP3} -e VM_IP3=${VM_IP3} -e MY_PREFIX3=${MY_PREFIX3} -e MY_GATEWAY3=${MY_GATEWAY3} -e YUM_REPO_PREFIX=${YUM_REPO_PREFIX} -e MY_PREFIX=${MY_PREFIX} -e VM_VCPU=${VM_VCPU} -e VM_RAM=${VM_RAM} -e VM_SIZE=${VM_SIZE} -e VM_DAT_SIZE=${VM_DAT_SIZE} -e VNC_PORT=${VNC_PORT} -e MY_VMNAME=${MY_VMNAME} --name ${NAME} -v ${DATAPATH}:/data -e IMAGEPATH=/data ${IMAGE}
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
