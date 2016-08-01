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

      systemctl restart messagebus || true
      systemctl restart sshd || true
      systemctl restart iptables || true
      systemctl restart libvirtd || true

      while true ;
      do
           if [ -S /var/run/libvirt/libvirt-sock ] ; then
               break
           else
               sleep 5
           fi
      done
     
      if [ "$VM_IP" == "" ] ; then

          systemctl start osp-uc-conf.service

          while true ;
          do
               if [ -f /home/stack/stackrc ] ; then
                   break
               else
                   sleep 5
               fi
          done

      else

      # start KVM in contaner

      if [ "$MY_VMNAME" == "" ] ; then
          MY_VMNAME=${NAME}
      fi
      if [ "$VNC_PORT" == "" ] ; then
          VNC_PORT=5910
      fi
      if [ "$VM_RAM" == "" ] ; then
          VM_RAM=2048
      fi
      if [ "$VM_VCPU" == "" ] ; then
           VM_VCPU=2
      fi

      if [ -f "/root/net-br0.xml" ] ; then 
        for BRFname in $(ls /root/net-br?.xml) ; do     
           BRN=$(basename -s .xml ${BRFname} | awk -F "-" '{ print $2 }')
	   if [ -f ${BRFname} ] ; then
	        virsh net-destroy ${BRN} || true
     		virsh net-undefine ${BRN} || true
        	virsh net-define ${BRFname} || true
        	virsh net-start ${BRN} || true
        	virsh net-autostart ${BRN} || true
                virsh net-list | grep ${BRN} 
                if [ $? == 0 ] ; then
        	    rm -f ${BRFname} 
                fi
   	   fi
        done
      fi

      if [ "$IMAGEPATH" == "" ] ; then
           IMAGEPATH=/var/lib/libvirt/images
      fi

      if [ -f "${IMAGEPATH}/${MY_VMNAME}.qcow2" ] ; then
          echo "use exist ${IMAGEPATH}/${MY_VMNAME}.qcow2" >> /var/log/${NAME}.log
      else
          echo "create ${IMAGEPATH}/${MY_VMNAME}.qcow2" >> /var/log/${NAME}.log
          export LIBGUESTFS_BACKEND=direct
          #qemu-img create -f qcow2 ${IMAGEPATH}/${MY_VMNAME}.qcow2 40G
          #virt-resize --expand /dev/sda1 /var/lib/libvirt/images/rhel-guest.qcow2 ${IMAGEPATH}/${MY_VMNAME}.qcow2
          cp -a /var/lib/libvirt/images/rhel-guest.qcow2 ${IMAGEPATH}/${MY_VMNAME}.qcow2
          qemu-img create -f qcow2 ${IMAGEPATH}/${MY_VMNAME}-DAT.qcow2 40G
          virt-filesystems --long -h --all -a ${IMAGEPATH}/${MY_VMNAME}.qcow2
          if [ -f /etc/yum.repos.d/local.repo ] ; then
             if [ "$YUM_REPO_PREFIX" != "" ] ; then
                sed -i "s/\/.*:81/\/\/$YUM_REPO_PREFIX/g" /etc/yum.repos.d/local.repo
             fi
             export DIB_YUM_REPO_CONF="/etc/yum.repos.d/local.repo"
          fi
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --run-command 'sed -i s/net.ifnames=1/net.ifnames=0/g /etc/default/grub ;\
                            sed -i s/biosdevname=1/biosdevname=0/g /etc/default/grub ; grub2-mkconfig -o /boot/grub2/grub.cfg'
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --run-command 'cp /etc/sysconfig/network-scripts/ifcfg-eth{0,1} && sed -i s/DEVICE=.*/DEVICE=eth1/g /etc/sysconfig/network-scripts/ifcfg-eth1 && sed -i s/NAME=.*/NAME=eth1/g /etc/sysconfig/network-scripts/ifcfg-eth1 && sed -i s/BOOTPROTO=.*/BOOTPROTO=none/g /etc/sysconfig/network-scripts/ifcfg-eth1 && sed -i s/BOOTPROTOv6=.*/BOOTPROTOv6=none/g /etc/sysconfig/network-scripts/ifcfg-eth1'
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --run-command 'cp /etc/sysconfig/network-scripts/ifcfg-eth{0,2} && sed -i s/DEVICE=.*/DEVICE=eth2/g /etc/sysconfig/network-scripts/ifcfg-eth2 && sed -i s/NAME=.*/NAME=eth2/g /etc/sysconfig/network-scripts/ifcfg-eth2 && sed -i s/BOOTPROTO=.*/BOOTPROTO=none/g /etc/sysconfig/network-scripts/ifcfg-eth2 && sed -i s/BOOTPROTOv6=.*/BOOTPROTOv6=none/g /etc/sysconfig/network-scripts/ifcfg-eth2'
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --run-command 'cp /etc/sysconfig/network-scripts/ifcfg-eth{0,3} && sed -i s/DEVICE=.*/DEVICE=eth3/g /etc/sysconfig/network-scripts/ifcfg-eth3 && sed -i s/NAME=.*/NAME=eth3/g /etc/sysconfig/network-scripts/ifcfg-eth3 && sed -i s/BOOTPROTO=.*/BOOTPROTO=none/g /etc/sysconfig/network-scripts/ifcfg-eth3 && sed -i s/BOOTPROTOv6=.*/BOOTPROTOv6=none/g /etc/sysconfig/network-scripts/ifcfg-eth3'
          if [ "$VM_IP" != "" ] ; then
               if [ "$VM_PREFIX" == "" ] ; then
                   if [ "$MY_PREFIX" != "" ] ; then 
                       VM_PREFIX=$MY_PREFIX
                   else
                       VM_PREFIX=24
                   fi
               fi
               virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --run-command "sed -i s/BOOTPROTO=.*/BOOTPROTO=none/g /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                   sed -i s/BOOTPROTOv6=.*/BOOTPROTOv6=none/g /etc/sysconfig/network-scripts/ifcfg-eth0 ;
                   echo IPADDR=$VM_IP >> /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                   sed -i s/IPADDR=.*/IPADDR=$VM_IP/g /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                   echo PREFIX=$VM_PREFIX >> /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                   sed -i s/PREFIX=.*/PREFIX=$VM_PREFIX/g /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                   "
               if [ "$MY_GATEWAY" != "" ] ; then
                   virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --run-command "echo GATEWAY=$MY_GATEWAY >> /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                       sed -i s/GATEWAY=.*/GATEWAY=$MY_GATEWAY/g /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                       "
               fi
          fi
          if [ "$DOMAIN" == "" ] ; then
               DOMAIN="tli.redhat.com"
          fi
          
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --run-command "echo ${MY_VMNAME}.${DOMAIN} > /etc/hostname"
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --upload /etc/yum.repos.d/local.repo:/etc/yum.repos.d/local.repo
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --firstboot-install vim,keepalived,iptables-services
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --mkdir /root/.ssh
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --upload /root/.ssh/id_rsa:/root/.ssh/id_rsa
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --upload /root/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --upload /root/.ssh/known_hosts:/root/.ssh/known_hosts
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --run-command "chmod 600 /root/.ssh/id_rsa;chmod 644 /root/.ssh/id_rsa.pub /root/.ssh/known_hosts"

          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --upload /etc/sysconfig/iptables:/etc/sysconfig/iptables
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --upload /etc/sysctl.conf:/etc/sysctl.conf

#          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --upload /usr/bin/osp-uc-config:/usr/bin/osp-uc-config
#          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --upload /etc/systemd/system/osp-uc-conf.service:/etc/systemd/system/osp-uc-conf.service
#          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --run-command "chmod +x /usr/bin/osp-uc-config;\
#			 mkdir -p /usr/lib/python2.7/site-packages/instack_undercloud"
#          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --upload /usr/lib/python2.7/site-packages/instack_undercloud/undercloud.py:/usr/lib/python2.7/site-packages/instack_undercloud/undercloud.py.tli
#
#          if [ "$BRCTL_SUBNET_PREFIX" == "" ] ; then
#               BRCTL_SUBNET_PREFIX="192.170"
#          fi
#          sed -i "s/<<undercloud.redhat.local>>/${MY_VMNAME}.${DOMAIN}/g" /root/firstboot-install.sh
#          sed -i "s/<<undercloud>>/${MY_VMNAME}/g" /root/firstboot-install.sh
#          sed -i s/XXX.XXX/$BRCTL_SUBNET_PREFIX/g /root/firstboot-install.sh
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --upload /root/firstboot-install.sh:/root/firstboot-install.sh
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --firstboot /root/firstboot-install.sh
          virt-customize -a ${IMAGEPATH}/${MY_VMNAME}.qcow2 --root-password password:redhat

      fi

      virsh list --all | grep ${MY_VMNAME}
      if [ $? != 0 ] ; then
          virt-install --ram $VM_RAM --vcpus $VM_VCPU --os-variant rhel7 \
              --disk path=${IMAGEPATH}/${MY_VMNAME}.qcow2,device=disk,bus=virtio,format=qcow2 \
              --disk path=${IMAGEPATH}/${MY_VMNAME}-DAT.qcow2,device=disk,bus=virtio,format=qcow2 \
              --import --noautoconsole --graphics vnc,password=redhat,listen=0.0.0.0,port=$VNC_PORT \
              --network network:br0 --network network:br1 \
              --network network:br2 --network network:br3 \
              --name ${MY_VMNAME} --dry-run --print-xml > /root/${MY_VMNAME}.xml
          virsh define --file /root/${MY_VMNAME}.xml
      fi

      virsh start ${MY_VMNAME}

      # end of start kvm in contaner

      fi

      # contaner had set 
      rm -rf /tmp/111
      exit 0
   else
     sleep 5 
   fi
done

