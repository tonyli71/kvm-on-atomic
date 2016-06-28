#!/usr/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

# Make Data Dirs
mkdir -p ${HOST}/${CONFDIR} ${HOST}/${LOGDIR} ${HOST}/${DATADIR} ${HOST}/var/opt

if [ "$MY_IP" != "" ] ; then

# Copy Exe file 

#touch ${HOST}/var/opt/run_${NAME}
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
chcon -t svirt_sandbox_file_t ${HOST}/${MY_DATA}
chmod -v 777 ${HOST}/${MY_DATA}

if [ "$MY_HOSTNAME" == "" ] ; then
      MY_HOSTNAME=${NAME}
fi

if [ "$FORWARDER" == "" ] ; then
      FORWARDER="127.0.0.1"
fi

if [ "$MY_DNS" == "" ] ; then
      MY_DNS="8.8.8.8"
fi

#docker run --privileged --name ipa-server -ti -e IPA_SERVER_IP=172.128.0.200 -e PASSWORD=redhat123 -v /var/lib/ipa-gcg-data:/data -p 53:53/udp -p 53:53 -p 80:80 -p 443:443 -p 389:389 -p 636:636 -p 88:88 -p 464:464 -p 88:88/udp -p 464:464/udp -p 123:123/udp -p 7389:7389 -p 9443:9443 -p 9444:9444 -p 9445:9445 --dns 8.8.8.8 -e FORWARDER=127.0.0.1 -e ETH0_IP=172.128.0.149 -h ipa.gcg.redhat.com -e HOSTNAME=ipa.gcg.redhat.com ipa-server

# Create Container
chroot ${HOST} /usr/bin/docker create --privileged --net=none -ti -h ${MY_HOSTNAME} -e PASSWORD=${ADMIN_PASSWORD} -e NAME=${NAME} -e MY_IFNAME=${MY_IFNAME} -e MY_IP=${MY_IP}  -e MY_PREFIX=${MY_PREFIX} -e MY_GATEWAY=${MY_GATEWAY} -e MY_IFNAME1=${MY_IFNAME1} -e MY_IP1=${MY_IP1}  -e MY_PREFIX1=${MY_PREFIX1} -e MY_GATEWAY1=${MY_GATEWAY1} -e MY_IFNAME2=${MY_IFNAME2} -e MY_IP2=${MY_IP2}  -e MY_PREFIX2=${MY_PREFIX2} -e MY_GATEWAY2=${MY_GATEWAY2} -e MY_IFNAME3=${MY_IFNAME3} -e MY_IP3=${MY_IP3}  -e MY_PREFIX3=${MY_PREFIX3} -e MY_GATEWAY3=${MY_GATEWAY3} -v ${MY_DATA}:/data -e FORWARDER=${FORWARDER} -e HOSTNAME=${MY_HOSTNAME} --dns ${MY_DNS} --name ${NAME} ${IMAGE}

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
