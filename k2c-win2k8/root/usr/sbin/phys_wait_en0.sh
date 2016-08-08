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
          virt-inspector /var/lib/libvirt/images/win-guest.qcow2 | tee /tmp/virt-inspector-win-guest
          #cp -a /var/lib/libvirt/images/win-guest.qcow2 ${IMAGEPATH}/${MY_VMNAME}.qcow2
          mkdir ${IMAGEPATH}/${MY_VMNAME}
          #virt-v2v -i disk /var/lib/libvirt/images/win-guest.qcow2 -o local -os ${IMAGEPATH}/${MY_VMNAME} -of qcow2
          virt-v2v -i disk /var/lib/libvirt/images/win-guest.qcow2 -o local -os ${IMAGEPATH}/${MY_VMNAME} -of raw
          myloop=$(losetup -a | grep "mydata-${NAME}.disk" | tail -n 1 | awk -F ':' '{ print $1;}')
          if [ "$myloop" != "" ] ; then
             echo $myloop > /myloop
             losetup -d $myloop
             losetup $myloop ${IMAGEPATH}/${MY_VMNAME}/win-guest-sda
             kpartx -a $myloop
             mount /dev/mapper/`basename $myloop`p2 /mnt
             PASSWORD="Redhat123"
#             chntpw /mnt/Windows/System32/config/SAM << EOF
#2
#$PASSWORD
#y
#EOF
             chntpw /mnt/Windows/System32/config/SAM << EOF
1
y
EOF

cat > /mnt/Program\ Files/Red\ Hat/Firstboot/Enable_Windows_Update_Auto_Restart.reg << EOF

Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU]
"NoAutoRebootWithLoggedOnUsers"=-
"AlwaysAutoRebootAtScheduledTime"=dword:00000001
EOF

cat > /mnt/Program\ Files/Red\ Hat/Firstboot/Disable_Windows_Update_Auto_Restart.reg << EOF
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU]
"NoAutoRebootWithLoggedOnUsers"=dword:00000001
"AlwaysAutoRebootAtScheduledTime"=dword:00000000
EOF

cat > /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0000-1470202492-kai5cjh8.bat << EOF
regedit /s "\Program Files\Red Hat\Firstboot\Enable_Windows_Update_Auto_Restart.reg"

if EXIST "\Program Files\Red Hat\Firstboot\auto_booted" goto booted_0
echo "1" > "\Program Files\Red Hat\Firstboot\auto_booted
c:\windows\system32\shutdown.exe /R /T 300 /F
:booted_0
EOF
          cat  /mnt/Program\ Files/Red\ Hat/Firstboot/firstboot.bat | grep uninstall > /mnt/Program\ Files/Red\ Hat/Firstboot/fb_uninstall.bat
          mv  /mnt/Program\ Files/Red\ Hat/Firstboot/firstboot.bat /mnt/Program\ Files/Red\ Hat/Firstboot/firstboot.org
          cat /mnt/Program\ Files/Red\ Hat/Firstboot/firstboot.org | grep -v uninstall > /mnt/Program\ Files/Red\ Hat/Firstboot/firstboot.bat
#netdom renamecomputer %computername% /newname:<NewName> /reboot:0
#netdom renamecomputer %computername% /newname:${MY_VMNAME} /Force
#netdom renamecomputer %computername% /newname:${MY_VMNAME} /Force
#netdom renamecomputer %computername% /newname:${MY_VMNAME} /Force /reboot:0
             cat > /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0002-1470202492-kai5cjh8.bat << EOF
echo configure hostname

IF  EXIST "\Program Files\Red Hat\Firstboot\scripts\0005-1470202492-kai5cjh8.bat" goto end_0
REM del /F /S "\Program Files\Red Hat\Firstboot\scripts\0001-*.bat"
REM copy "\Program Files\Red Hat\Firstboot\firstboot.org" "\Program Files\Red Hat\Firstboot\firstboot.bat"
copy "\Program Files\Red Hat\Firstboot\0005-1470202492-kai5cjh8.bat" "\Program Files\Red Hat\Firstboot\scripts\0005-1470202492-kai5cjh8.bat"

REM netdom renamecomputer %computername% /newname:${MY_VMNAME} /Force 

:end_0

EOF

             cat > /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat << EOF

IF not EXIST "\Program Files\Red Hat\Firstboot\scripts\0002-1470202492-kai5cjh8.bat" goto next_0 

del /F /S "\Program Files\Red Hat\Firstboot\scripts\0002-1470202492-kai5cjh8.bat"

:next_0

echo configure Administrator's password
net user Administrator ${PASSWORD}
echo configure networks
EOF

          if [ "$VM_IP" != "" ] ; then
             if [ "$VM_NETMASK" == "" ] ; then
               if [ "$VM_PREFIX" == "" ] ; then
                   if [ "$MY_PREFIX" != "" ] ; then
                       VM_PREFIX=$MY_PREFIX
                       VM_NETMASK="255.255.0.0"
                   else
                       VM_PREFIX=24
                       VM_NETMASK="255.255.255.0"
                   fi
               fi
             fi
               if [ "$MY_GATEWAY" != "" ] ; then
                 cat >> /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat << EOF
netsh interface ip set address "本地连接" static ${VM_IP} ${VM_NETMASK} ${MY_GATEWAY} 1 || goto exit_1
echo "eth0 set" > "\Program Files\Red Hat\Firstboot\eth0.txt"
EOF
               else
                 cat >> /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat << EOF
netsh interface ip set address "本地连接" static ${VM_IP} ${VM_NETMASK} || goto exit_1
echo "eth0 set" > "\Program Files\Red Hat\Firstboot\eth0.txt"
EOF
               fi
          fi

          if [ "$VM_IP1" != "" ] ; then
               if [ "$VM_PREFIX1" == "" ] ; then
                   if [ "$MY_PREFIX1" != "" ] ; then
                       VM_PREFIX1=$MY_PREFIX1
                   else
                       VM_PREFIX1=24
                   fi
               fi
               if [ "$MY_GATEWAY1" != "" ] ; then
                 cat >> /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat << EOF
netsh interface ip set address "本地连接 2" static ${VM_IP1}/${VM_PREFIX1} ${MY_GATEWAY1} 1 || goto exit_1
echo "eth1 set" > "\Program Files\Red Hat\Firstboot\eth1.txt"
EOF
               else
                 cat >> /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat << EOF
netsh interface ip set address "本地连接 2" static ${VM_IP1}/${VM_PREFIX1} || goto exit_1 
echo "eth1 set" > "\Program Files\Red Hat\Firstboot\eth1.txt"
EOF
               fi
          fi

          if [ "$VM_IP2" != "" ] ; then
               if [ "$VM_PREFIX2" == "" ] ; then
                   if [ "$MY_PREFIX2" != "" ] ; then
                       VM_PREFIX2=$MY_PREFIX2
                   else
                       VM_PREFIX2=24
                   fi
               fi
               if [ "$MY_GATEWAY2" != "" ] ; then
                 cat >> /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat << EOF
netsh interface ip set address "本地连接 3" static ${VM_IP2}/${VM_PREFIX2} ${MY_GATEWAY2} 1 || goto exit_1
echo "eth2 set" > "\Program Files\Red Hat\Firstboot\eth2.txt"
EOF
               else
                 cat >> /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat << EOF
netsh interface ip set address "本地连接 3" static ${VM_IP2}/${VM_PREFIX2} || goto exit_1
echo "eth2 set" > "\Program Files\Red Hat\Firstboot\eth2.txt"
EOF
               fi
          fi
          if [ "$VM_IP3" != "" ] ; then
               if [ "$VM_PREFIX3" == "" ] ; then
                   if [ "$MY_PREFIX3" != "" ] ; then
                       VM_PREFIX3=$MY_PREFIX3
                   else
                       VM_PREFIX3=24
                   fi
               fi
               if [ "$MY_GATEWAY3" != "" ] ; then
                 cat >> /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat << EOF
netsh interface ip set address "本地连接 4" static ${VM_IP3}/${VM_PREFIX3} ${MY_GATEWAY3} 1 || goto exit_1 
echo "eth3 set" > "\Program Files\Red Hat\Firstboot\eth3.txt"
EOF
               else
                 cat >> /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat << EOF
netsh interface ip set address "本地连接 4" static ${VM_IP3}/${VM_PREFIX3} || goto exit_1 
echo "eth3 set" > "\Program Files\Red Hat\Firstboot\eth3.txt"
EOF
               fi
          fi

cat >> /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat << EOF

if not EXIST "\Program Files\Red Hat\Firstboot\eth3.txt" goto exit_1
if EXIST "\Program Files\Red Hat\Firstboot\done" goto exit_1
REM "\Program Files\Red Hat\Firstboot\fb_uninstall.bat"
copy "\Program Files\Red Hat\Firstboot\firstboot.org" "\Program Files\Red Hat\Firstboot\firstboot.bat"
echo "1" > "\Program Files\Red Hat\Firstboot\done.txt"
netdom renamecomputer %computername% /newname:${MY_VMNAME} /Force /reboot:0
del /F /S "\Program Files\Red Hat\Firstboot\scripts\0005-1470202492-kai5cjh8.bat"
:exit_1
EOF


#del /F "Program Files\Red Hat\Firstboot\scripts\0002-1470202492-kai5cjh8.bat"

             iconv -f utf-8 -t CP936 /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0002-1470202492-kai5cjh8.bat > /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0003-1470202492-kai5cjh8.bat
             unix2dos -n /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0003-1470202492-kai5cjh8.bat /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0002-1470202492-kai5cjh8.bat
             rm -f /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0003-1470202492-kai5cjh8.bat
             cp /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0002-1470202492-kai5cjh8.bat /mnt/Program\ Files/Red\ Hat/Firstboot/0002-1470202492-kai5cjh8.bat

             iconv -f utf-8 -t CP936 /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat > /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0003-1470202492-kai5cjh8.bat
             unix2dos -n /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0003-1470202492-kai5cjh8.bat /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat
             rm -f /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0003-1470202492-kai5cjh8.bat
             cp /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat /mnt/Program\ Files/Red\ Hat/Firstboot/0005-1470202492-kai5cjh8.bat
             rm -f /mnt/Program\ Files/Red\ Hat/Firstboot/scripts/0005-1470202492-kai5cjh8.bat
             umount /mnt
             kpartx -d $myloop
             losetup -d $myloop
          fi
          mv ${IMAGEPATH}/${MY_VMNAME}/win-guest-sda ${IMAGEPATH}/${MY_VMNAME}.qcow2

          #qemu-img create -f qcow2 ${IMAGEPATH}/${MY_VMNAME}.qcow2 40G
          #virt-resize --expand /dev/sda1 /var/lib/libvirt/images/win-guest.qcow2 ${IMAGEPATH}/${MY_VMNAME}.qcow2
#          if [ "$VM_SIZE" == "" ] ; then
#              qemu-img create -f qcow2 -b /var/lib/libvirt/images/win-guest.qcow2 ${IMAGEPATH}/${MY_VMNAME}.qcow2
#              virt-filesystems --long -h --all -a ${IMAGEPATH}/${MY_VMNAME}.qcow2
#          else
#              qemu-img create -f qcow2 ${IMAGEPATH}/${MY_VMNAME}.qcow2 ${VM_SIZE}G
#              virt-resize --expand /dev/sda1 /var/lib/libvirt/images/win-guest.qcow2 ${IMAGEPATH}/${MY_VMNAME}.qcow2
#              virt-filesystems --long -h --all -a ${IMAGEPATH}/${MY_VMNAME}.qcow2
#              virt-df -a ${IMAGEPATH}/${MY_VMNAME}.qcow2
#              rm -f /var/lib/libvirt/images/win-guest.qcow2
#          fi

          if [ "$VM_DAT_SIZE" == "" ] ; then
              qemu-img create -f qcow2 ${IMAGEPATH}/${MY_VMNAME}-DAT.qcow2 40G
          else
              qemu-img create -f qcow2 ${IMAGEPATH}/${MY_VMNAME}-DAT.qcow2 ${VM_DAT_SIZE}G
          fi

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

