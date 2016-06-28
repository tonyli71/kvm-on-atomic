docker rm -f $(basename `pwd`)
#docker rmi -f $(basename `pwd`)
docker build -t $(basename `pwd`) .
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi -f 

export MY_IFNAME=atomic1
export MY_IP=192.170.0.229
export MY_PREFIX=16
export MY_GATEWAY=192.170.0.1
export YUM_REPO_PATH=/home/repos
export MY_HOSTNAME=k2c-rhel-repos.tli.redhat.com
atomic install k2c-rhel-repos
/usr/bin/systemctl restart k2c-rhel-repos.service

docker rm -f k2c-rhel-repos-int
export MY_IFNAME=atomic2
export MY_IP=172.16.0.229
export MY_PREFIX=16
export MY_GATEWAY=172.16.0.254
export YUM_REPO_PATH=/home/repos
export MY_HOSTNAME=k2c-rhel-repos-int.tli.redhat.com
atomic install -n k2c-rhel-repos-int k2c-rhel-repos
/usr/bin/systemctl restart k2c-rhel-repos-int.service

docker attach k2c-rhel-repos-int
