docker rm -f $(basename `pwd`)
#docker rmi -f $(basename `pwd`)
docker build -t $(basename `pwd`) .
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi -f 
export MY_IP=192.170.0.229
export MY_PREFIX=16
export MY_GATEWAY=192.170.0.1
export YUM_REPO_PATH=/home/repos
atomic install k2c-rhel-repos
/usr/bin/systemctl restart k2c-rhel-repos.service
docker attach k2c-rhel-repos