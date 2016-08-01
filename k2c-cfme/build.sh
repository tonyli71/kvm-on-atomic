docker rm -f k2c-cfme
#docker rmi -f $(basename `pwd`)
docker build -t $(basename `pwd`) .
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi -f 
export MY_IP=192.170.1.102
export VM_IP=192.170.12.1
export MY_PREFIX=16
export MY_GATEWAY=192.170.0.1
export YUM_REPO_PREFIX=192.170.0.229:81
export MY_HOSTNAME=k2c-cfme.tli.redhat.com
export VM_RAM=16384
export VM_VCPU=8
export DATAPATH=/home/data
rm -f /home/data/k2c-cfme.qcow2
rm -f /home/data/k2c-cfme-DAT.qcow2
atomic install k2c-cfme
/usr/bin/systemctl restart k2c-cfme.service
docker attach k2c-cfme
