
export MY_IFNAME=atomic1
export MY_IP=192.170.0.229
export MY_PREFIX=16
export MY_GATEWAY=192.170.0.1
export YUM_REPO_PATH=/home/repos
atomic install k2c-rhel-repos
/usr/bin/systemctl restart k2c-rhel-repos.service

docker rm -f k2c-rhel-repos-int
export MY_IFNAME=atomic2
export MY_IP=172.16.0.229
export MY_PREFIX=16
export MY_GATEWAY=172.16.0.254
export YUM_REPO_PATH=/home/repos
atomic install -n k2c-rhel-repos-int k2c-rhel-repos
/usr/bin/systemctl restart k2c-rhel-repos-int.service

