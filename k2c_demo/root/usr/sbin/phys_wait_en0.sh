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

      if [ -f "/var/lib/libvirt/images/${MY_VMNAME}.qcow2" ] ; then
          echo "use exist /var/lib/libvirt/images/${MY_VMNAME}.qcow2" >> /var/log/${NAME}.log
      else
          echo "create /var/lib/libvirt/images/${MY_VMNAME}.qcow2" >> /var/log/${NAME}.log
          qemu-img create -f qcow2 -b /var/lib/libvirt/images/rhel-guest.qcow2 /var/lib/libvirt/images/${MY_VMNAME}.qcow2
          export LIBGUESTFS_BACKEND=direct
          if [ -f /etc/yum.repos.d/local.repo ] ; then
             if [ "$YUM_REPO_PREFIX" != "" ] ; then
                sed -i "s/\/.*:81/\/\/$YUM_REPO_PREFIX/g" /etc/yum.repos.d/local.repo
             fi
             export DIB_YUM_REPO_CONF="/etc/yum.repos.d/local.repo"
          fi
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --root-password password:Redhat01
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --run-command 'yum remove cloud-init* -y'
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --run-command 'sed -i s/net.ifnames=1/net.ifnames=0/g /etc/default/grub ;\
                            sed -i s/biosdevname=1/biosdevname=0/g /etc/default/grub ; grub2-mkconfig -o /boot/grub2/grub.cfg'
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --run-command 'cp /etc/sysconfig/network-scripts/ifcfg-eth{0,1} && sed -i s/DEVICE=.*/DEVICE=eth1/g /etc/sysconfig/network-scripts/ifcfg-eth1'
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --run-command 'cp /etc/sysconfig/network-scripts/ifcfg-eth{0,2} && sed -i s/DEVICE=.*/DEVICE=eth2/g /etc/sysconfig/network-scripts/ifcfg-eth2'
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --run-command 'cp /etc/sysconfig/network-scripts/ifcfg-eth{0,3} && sed -i s/DEVICE=.*/DEVICE=eth3/g /etc/sysconfig/network-scripts/ifcfg-eth3'
          if [ "$VM_IP" != "" ] ; then
               if [ "$VM_PREFIX" == "" ] ; then
                   if [ "$MY_PREFIX" != "" ] ; then 
                       VM_PREFIX=$MY_PREFIX
                   else
                       VM_PREFIX=24
                   fi
               fi
               virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --run-command "sed -i s/BOOTPROTO=.*/BOOTPROTO=none/g /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                   sed -i s/BOOTPROTOv6=.*/BOOTPROTOv6=none/g /etc/sysconfig/network-scripts/ifcfg-eth0 ;
                   echo IPADDR=$VM_IP >> /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                   sed -i s/IPADDR=.*/IPADDR=$VM_IP/g /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                   echo PREFIX=$VM_PREFIX >> /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                   sed -i s/PREFIX=.*/PREFIX=$VM_PREFIX/g /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                   "
               if [ "$MY_GATEWAY" != "" ] ; then
                   virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --run-command "echo GATEWAY=$MY_GATEWAY >> /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                       sed -i s/GATEWAY=.*/GATEWAY=$MY_GATEWAY/g /etc/sysconfig/network-scripts/ifcfg-eth0 ; \
                       "
               fi
          fi
          DOMAINNAME="tli.redhat.com"
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --run-command "echo ${MY_VMNAME}.${DOMAINNAME} > /etc/hostname"
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --upload /etc/yum.repos.d/local.repo:/etc/yum.repos.d/local.repo
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --firstboot-install vim,keepalived,iptables-services
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --mkdir /root/.ssh
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --upload /root/.ssh/id_rsa:/root/.ssh/id_rsa
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --upload /root/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --upload /root/.ssh/known_hosts:/root/.ssh/known_hosts
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --run-command "chmod 600 /root/.ssh/id_rsa;chmod 644 /root/.ssh/id_rsa.pub /root/.ssh/known_hosts"

          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --upload /etc/sysconfig/iptables:/etc/sysconfig/iptables
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --upload /etc/sysctl.conf:/etc/sysctl.conf

          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --upload /root/firstboot-install.sh:/root/firstboot-install.sh
          virt-customize -a /var/lib/libvirt/images/${MY_VMNAME}.qcow2 --firstboot /root/firstboot-install.sh

      fi

      virsh list --all | grep ${MY_VMNAME}
      if [ $? != 0 ] ; then
          virt-install --ram $VM_RAM --vcpus $VM_VCPU --os-variant rhel7 --disk path=/var/lib/libvirt/images/${MY_VMNAME}.qcow2,device=disk,bus=virtio,format=qcow2 --import --noautoconsole --graphics vnc,password=redhat,listen=0.0.0.0,port=$VNC_PORT --network network:br0 --network network:br1 --network network:br2 --network network:br3 --name ${MY_VMNAME} --dry-run --print-xml > /root/${MY_VMNAME}.xml
          virsh define --file /root/${MY_VMNAME}.xml
      fi

      virsh start ${MY_VMNAME}

      rm -rf /tmp/111
      exit 0
   else
     sleep 5 
   fi
done

