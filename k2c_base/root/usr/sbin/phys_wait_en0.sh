#! /usr/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

rm -rf /tmp/111

while true ;
do
   ifconfig | grep en0 > /tmp/111
   aaa="$(cat /tmp/111)"
   if [ "$aaa" == "" ] ; then
     systemctl restart keepalived
     exit 0
   else
     sleep 5 
   fi
done

