docker rm -f k2c-ipa-server
#docker rmi -f $(basename `pwd`)
docker build -t $(basename `pwd`) .
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi -f 

rm -rf /home/ipa-data/*
export MY_IFNAME=atomic1
export MY_IP=192.170.0.29
# DNS ZONE PREFIX MUST BE IN 24
export MY_PREFIX=16
export MY_GATEWAY=192.170.0.1

export MY_IFNAME1=atomic0
export MY_IP1=192.171.255.29
export MY_PREFIX1=16

export MY_IFNAME2=atomic2
export MY_IP2=192.172.255.29
export MY_PREFIX2=16

export MY_IFNAME3=atomic3
export MY_IP3=192.173.255.29
export MY_PREFIX3=16

export MY_DATA=/home/ipa-data
export MY_HOSTNAME=ipa-server.tli.redhat.com
export ADMIN_PASSWORD=redhat123
#export MY_DNS=8.8.8.8
export MY_DNS=202.96.128.86
export FORWARDER=202.96.128.86
atomic install -n k2c-ipa-server k2c-ipa-server
/usr/bin/systemctl restart k2c-ipa-server.service
docker attach k2c-ipa-server
