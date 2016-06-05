#!/bin/bash
set -eux

# firstboot isn't split out by role yet so we handle it this way
if ! hostname | grep compute &>/dev/null; then
 echo "Exiting. This script is only for the compute role."
 exit 0
fi

mkdir -p /var/lib/etc-data/json-config #FIXME: this should be a docker data container

# heat-docker-agents service
cat <<EOF > /etc/systemd/system/heat-docker-agents.service

[Unit]
Description=Heat Docker Agent Container
After=docker.service
Requires=docker.service

[Service]
User=root
Restart=on-failure
ExecStartPre=-/usr/bin/docker kill heat-agents
ExecStartPre=-/usr/bin/docker rm heat-agents
ExecStartPre=/usr/bin/docker pull $agent_image
ExecStart=/usr/bin/docker run --name heat-agents --privileged --net=host -v /var/lib/etc-data:/var/lib/etc-data -v /run:/run -v /etc:/host/etc -v /usr/bin/atomic:/usr/bin/atomic -v /var/lib/dhclient:/var/lib/dhclient -v /var/lib/cloud:/var/lib/cloud -v /var/lib/heat-cfntools:/var/lib/heat-cfntools --entrypoint=/usr/bin/os-collect-config $agent_image
ExecStop=/usr/bin/docker stop heat-agents

[Install]
WantedBy=multi-user.target

EOF

# update docker for local insecure registry(optional)
# Note: This is different for different docker versions
# For older docker versions < 1.4.x use commented line
#echo "OPTIONS='--insecure-registry $docker_registry'" >> /etc/sysconfig/docker
#echo "ADD_REGISTRY='--registry-mirror $docker_registry'" >> /etc/sysconfig/docker

# Local docker registry 1.8
if [ $docker_namespace_is_registry ]; then
    # if namespace is used with local registry, trim all namespacing
    trim_var=$docker_registry
    registry_host="${trim_var%%/*}"
    /bin/sed -i "s/# INSECURE_REGISTRY='--insecure-registry'/INSECURE_REGISTRY='--insecure-registry $registry_host'/g" /etc/sysconfig/docker
fi

/sbin/setenforce 0
/sbin/modprobe ebtables

# We need hostname -f to return in a centos container for the puppet hook
HOSTNAME=$(hostname)
echo "127.0.0.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Remove upstream bits that setup Docker.
# RHEL Atomic will start docker 1.8.2 for us and point at
# Red Hat's registry.

# enable and start docker
/usr/bin/systemctl enable docker.service
/usr/bin/systemctl restart --no-block docker.service

# enable and start heat-docker-agents
chmod 0640 /etc/systemd/system/heat-docker-agents.service
/usr/bin/systemctl enable heat-docker-agents.service
/usr/bin/systemctl start --no-block heat-docker-agents.service

# Disable NetworkManager and let the ifup/down scripts work properly.
/usr/bin/systemctl disable NetworkManager
/usr/bin/systemctl stop NetworkManager

# Atomic's root partition & logical volume defaults to 3G.  In order to launch
# larger VMs, we need to enlarge the root logical volume and scale down the
# docker_pool logical volume. We are allocating 80% of the disk space for
# vm data and the remaining 20% for docker images.
ATOMIC_ROOT='/dev/mapper/atomicos-root'
ROOT_DEVICE=`pvs -o vg_name,pv_name --no-headings | grep atomicos | awk '{ print $2}'`

growpart $( echo "${ROOT_DEVICE}" | sed -r 's/([^0-9]*)([0-9]+)/\1 \2/' )
pvresize "${ROOT_DEVICE}"
lvresize -l +80%FREE "${ATOMIC_ROOT}"
xfs_growfs "${ATOMIC_ROOT}"

cat <<EOF > /etc/sysconfig/docker-storage-setup
GROWPART=true
AUTO_EXTEND_POOL=yes
POOL_AUTOEXTEND_PERCENT=30
POOL_AUTOEXTEND_THRESHOLD=70
EOF
