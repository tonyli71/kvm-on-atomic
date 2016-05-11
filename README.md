# kvm-on-atomic

Redhat atomic host is the robust foundation platform for DevOps. It is build on container technology.
if we need integrate some traditional system into DevOps which can not be containerise. we will need this kvm-on-atomic . put your system into atomic host with Kvm , make it as a blackbox and service your appliction.

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
