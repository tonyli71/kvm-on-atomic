#! /usr/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

ifconfig | grep eth0 > /dev/null
if [ $? == 0 ] ; then

   ip a show dev eth0 | grep 192.168.1.250/24

   if [ $? == 0 ] ; then
        arping -c 1 -I eth0 192.168.1.250
        if [ $? == 0 ] ; then
            ip addr del 192.168.1.250/24 dev eth0
            exit 1
        else 
            ps -lef | grep pppoe | grep -v grep  > /dev/null
            if [ $? != 0 ] ; then
                 ifup ppp0
            fi
            IP=`pppoe-status | grep inet | awk -F ' ' '{ print $2}'`
            if [ "${IP}" != "" ] ; then
                ssh 219.136.252.28 "echo ${IP} > /tmp/pppoe2"
            fi
        fi
    else
        arping -c 1 -I eth0 192.168.1.250
        if [ $? == 0 ] ; then
            exit 0
        else
            ip addr add 192.168.1.250/24 dev eth0
            #/bin/systemctl restart  ipa.service & 
            exit 1
        fi
    fi
fi

exit 0

