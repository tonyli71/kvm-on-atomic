docker rm -f k2c_demo
#docker rmi -f $(basename `pwd`)
docker build -t $(basename `pwd`) .
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi -f 
export MY_IP=192.170.1.100
export VM_IP=192.170.1.200
export MY_PREFIX=16
export MY_GATEWAY=192.170.0.1
export YUM_REPO_PREFIX=192.170.0.229:81
atomic install k2c_demo
/usr/bin/systemctl restart k2c_demo.service
docker attach k2c_demo
