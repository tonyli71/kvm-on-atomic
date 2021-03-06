#!/usr/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

# Make Data Dirs
mkdir -p ${HOST}/${CONFDIR} ${HOST}/${LOGDIR}/k2c ${HOST}/${DATADIR} ${HOST}/var/opt

if [ "$MY_IP" != "" ] ; then

# Copy Exe file 
touch ${HOST}/var/opt/run_${NAME}
#cp -p /usr/bin/run_k2c ${HOST}/var/opt/run_${NAME}
sed -e "s/k2c_demo/${NAME}/g" /usr/bin/run_k2c > ${HOST}/var/opt/run_${NAME}

if [ "$MY_IFNAME" != "" ] ;then
    sed -i "s/atomic1/${MY_IFNAME}/g"  ${HOST}/var/opt/run_${NAME}
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

chroot  ${HOST} /usr/sbin/modprobe scsi_transport_iscsi
chroot  ${HOST} /usr/sbin/modprobe ipmi_devintf
chroot  ${HOST} /usr/sbin/modprobe openvswitch

# Create Container
cmd="chroot ${HOST} /usr/bin/docker create --privileged --net=none -ti -h ${MY_HOSTNAME} -e NAME=${NAME} -e MY_IP=${MY_IP} -e VM_IP=${VM_IP} -e YUM_REPO_PREFIX=${YUM_REPO_PREFIX} -e MY_PREFIX=${MY_PREFIX} -e MY_GATEWAY=${MY_GATEWAY} -e VM_VCPU=${VM_VCPU} -e VM_RAM=${VM_RAM} -e VNC_PORT=${VNC_PORT} -e MY_VMNAME=${MY_VMNAME} -e BRCTL_SUBNET_PREFIX=${BRCTL_SUBNET_PREFIX} -v /:/host -v /etc/localtime:/etc/localtime -v /etc/machine-id:/etc/machine-id --device=/dev/loop-control:/dev/loop-control:rwm --ulimit nofile=65536:65536 --ulimit nproc=2048:4096"

if [ "$DATAPATH" == "" ] ; then
    if [ ! -f /tmp/mydata-${NAME}.disk ] ; then
        chroot ${HOST} dd if=/dev/zero of=/tmp/mydata-${NAME}.disk bs=1MiB count=10
        chroot ${HOST} losetup --find --show /tmp/mydata-${NAME}.disk
    fi
else
    if [ ! -f $DATAPATH/mydata-${NAME}.disk ] ; then
        chroot ${HOST} dd if=/dev/zero of=$DATAPATH/mydata-${NAME}.disk bs=1MiB count=10
        chroot ${HOST} losetup --find --show $DATAPATH/mydata-${NAME}.disk
    fi
    cmd="$cmd -v ${DATAPATH}:/data -e IMAGEPATH=/data"
fi

if [ "$MYDBPATH" != "" ] ; then
    cmd="$cmd -v ${MYDBPATH}:/var/lib/mysql"
fi

if [ "$GLANCEPATH" != "" ] ; then
    cmd="$cmd -v ${GLANCEPATH}:/var/lib/glance"
fi

if [ "$SWIFTPATH" != "" ] ; then
    cmd="$cmd -v ${SWIFTPATH}:/etc/swift"
fi

cmd="$cmd --name ${NAME} ${IMAGE}";$cmd

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
   echo "atomic install --name <container name> k2c_demo"

fi
