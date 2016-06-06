docker rm -f $(basename `pwd`)
#docker rmi -f $(basename `pwd`)
docker build -t $(basename `pwd`) .
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi -f 

export MY_IFNAME=atomic1
export MY_IP=192.170.0.228
export MY_PREFIX=16
export MY_GATEWAY=192.170.0.1
export REGISTRY_PATH=/home/docker-registry
atomic install k2c-registry
/usr/bin/systemctl restart k2c-registry.service

docker attach k2c-registry
