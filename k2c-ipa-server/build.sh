docker rm -f $(basename `pwd`)
#docker rmi -f $(basename `pwd`)
docker build -t $(basename `pwd`) .
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi -f 

rm -rf /home/ipa-data/*
export MY_IFNAME=atomic1
export MY_IP=192.170.0.29
# DNS ZONE PREFIX MUST BE 24
export MY_PREFIX=24
export MY_GATEWAY=192.170.0.1
export MY_DATA=/home/ipa-data
export MY_HOSTNAME=ipa-server.tli.redhat.com
export ADMIN_PASSWORD=redhat123
export MY_DNS=8.8.8.8
atomic install k2c-ipa-server
/usr/bin/systemctl restart k2c-ipa-server.service
docker attach k2c-ipa-server
