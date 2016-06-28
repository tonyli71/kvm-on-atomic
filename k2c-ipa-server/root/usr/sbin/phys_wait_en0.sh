#! /usr/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

rm -rf /tmp/111

while true ;
do
   ifconfig | grep en3 > /tmp/111
   aaa="$(cat /tmp/111)"
   if [ "$aaa" != "" ] ; then
      ifup br0
      brctl addif br0 en0
      ifup br1
      brctl addif br1 en1
      ifup br2
      brctl addif br2 en2
      ifup br3
      brctl addif br3 en3
      rm -rf /tmp/111
      exit 0
   else
     sleep 5 
   fi
done

