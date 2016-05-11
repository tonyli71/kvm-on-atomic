#! /usr/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

ifconfig | grep en0 > /dev/null
if [ $? == 0 ] ; then

   ip a show dev br0
   if [ $? != 0 ] ; then
       ifup br0
   fi

   brctl show br0 | grep en0
   if [ $? != 0 ] ; then
      brctl addif br0 en0
   fi

   ip a show dev br0 | grep 192.168.1.247/24
   if [ $? != 0 ] ; then
       ip addr add 192.168.1.247/24 dev br0
   fi
   
   ip a show dev br0 | grep 192.168.1.248/24

   if [ $? == 0 ] ; then
        arping -c 1 -I br0 192.168.1.248
        if [ $? == 0 ] ; then
            ip addr del 192.168.1.248/24 dev br0
            exit 1
        else 
            #ps -lef | grep pppoe | grep -v grep  > /dev/null
            #if [ $? != 0 ] ; then
            #     ifup ppp0
            #     /usr/libexec/iptables/iptables.init reload
            #     sysctl -p
            #fi
            #IP=`pppoe-status | grep inet | awk -F ' ' '{ print $2}'`
            #if [ "${IP}" != "" ] ; then
            #    ssh 219.136.252.28 "echo ${IP} > /tmp/pppoe1"
            #fi
            ifconfig | grep eth1 > /dev/null
            if [ $? == 0 ] ; then
                 brctl show br1 | grep eth1
                 if [ $? != 0 ] ; then
                     brctl addif br1 eth1
                 fi
            fi
            ifconfig | grep en1 > /dev/null
            if [ $? == 0 ] ; then
                 brctl show br2 | grep en1
                 if [ $? != 0 ] ; then
                     brctl addif br2 en1
                 fi
            fi
            ifconfig | grep eth2 > /dev/null
            if [ $? == 0 ] ; then
                 brctl show br3 | grep eth2
                 if [ $? != 0 ] ; then
                     brctl addif br3 eth2
                 fi
            fi
            virsh list | grep myrouter
            if [ $? != 0 ] ; then
                 sleep 5
                 virsh start myrouter
            fi
        fi
    else
        arping -c 1 -I br0 192.168.1.248
        if [ $? == 0 ] ; then
            exit 0
        else
            ip addr add 192.168.1.248/24 dev br0
            #/bin/systemctl restart  ipa.service & 
            exit 1
        fi
    fi
fi

exit 0

