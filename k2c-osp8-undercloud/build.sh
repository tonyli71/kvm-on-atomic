docker rm -f k2c-osp8-undercloud
#docker rmi -f $(basename `pwd`)
docker build -t $(basename `pwd`) .
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi -f 
export MY_IP=172.16.1.101
#export VM_IP=172.16.10.1
export MY_PREFIX=16
export MY_GATEWAY=172.16.0.254
export YUM_REPO_PREFIX=172.16.0.229:81
export MY_HOSTNAME=k2c-osp8-undercloud.tli.redhat.com
export VM_RAM=16384
export VM_VCPU=8
export DATAPATH=/home/data
export BRCTL_SUBNET_PREFIX=172.16
atomic install k2c-osp8-undercloud
/usr/bin/systemctl restart k2c-osp8-undercloud.service
docker attach k2c-osp8-undercloud
