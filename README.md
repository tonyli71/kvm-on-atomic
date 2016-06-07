# kvm-on-atomic

Redhat atomic host is the robust foundation platform for DevOps. It is build on container technology.
if we need integrate some traditional system into DevOps which can not be containerise. we will need this kvm-on-atomic . put your system into atomic host with Kvm , make it as a blackbox and service your appliction.

# Install atomic

## install atomic on RHEL
~~~

subscription-manager register --user <your userid> --force

subscription-manager list --available --all

subscription-manager attach --pool xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
subscription-manager attach --pool yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

subscription-manager repos --disable=*

subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-optional-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-openstack-8-rpms --enable=rhel-7-server-openstack-8-director-rpms --enable=rhel-7-server-rhceph-1.3-mon-rpms --enable=rhel-7-server-rhceph-1.3-osd-rpms --enable=rhel-7-server-v2vwin-1-rpms --enable=rhel-7-server-rhceph-1.3-tools-rpms --enable=rhel-7-server-rhceph-1.3-installer-rpms --enable=rhel-7-server-rhceph-1.3-calamari-rpms --enable=rhel-7-server-rh-common-rpms --enable=rhel-7-server-ose-3.2-rpms  --enable=rhel-ha-for-rhel-7-server-rpms --enable=rhel-7-server-openstack-8-optools-rpms --enable=rhel-7-server-openstack-8-tools-rpms --enable=rhel-atomic-host-rpms --enable=rhel-7-server-rhmap-4-rpms --enable=cf-me-5.5-for-rhel-7-rpms --enable=rhel-7-server-nfv-rpms --enable=rhel-server-rhscl-7-rpms

yum install -y atomic
yum update -y
reboot

~~~

## install atomic host

~~~

subscription-manager register --user <your userid> --force

atomic host upgrade

~~~

# atomic host network

we assume have four network on the host.
the host network may like following.

~~~
-bash-4.2# brctl show
bridge name	bridge id		STP enabled	interfaces
atomic0		8000.00e0b40f9fbb	no		enp3s0
atomic1		8000.00010a0ae7d8	no		enp3s1
atomic2		8000.00e0b40f9fbc	no		enp4s0
atomic3		8000.00010a0ac65c	no		enp4s1
docker0		8000.02429bd02204	no		
~~~

enpXXXX are phy NIC
<br>
atomic[0-3] are for this demo
<br>
docker0 is gen by atomic host
<br>
