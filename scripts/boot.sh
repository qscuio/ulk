#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 ARCH RELEASE"
    exit 1
fi

# Moved to seperate script
# sudo brctl addbr br0
# sudo tunctl -t tap1 -u root
# sudo tunctl -t tap2 -u root
# sudo brctl addif br0 tap1
# sudo brctl addif br0 tap2

# sudo ifconfig br0 down
# sudo ifconfig tap1 down
# sudo ifconfig tap2 down
# sudo brctl delbr br0

#
# using kvm can improve the performance of guest system.
# this need enable cpu virtualization in vmware.
# check cpu virtualization by "kvm-ok" command.
# -enable-kvm -cpu host 
# 

# 
# We mount project directory into /home/qwert of guest os.
#  
# We create a 4 core 8G (4+4) memory guest
# 

if [ "$1" = "x86_64" ]; then
    sudo qemu-system-x86_64 \
	-smp 4 -enable-kvm -cpu host \
	-m 8G \
	-object memory-backend-ram,size=4G,id=m0 \
	-object memory-backend-ram,size=4G,id=m1 \
	-numa node,nodeid=0,memdev=m0 \
	-numa node,nodeid=1,memdev=m1 \
	-kernel build/arch/x86_64/boot/bzImage \
	-append "console=ttyS0 root=/dev/sda earlyprintk=serial nokaslr page_owner=on"\
	-drive file=$RELEASE.img,format=raw \
	-fsdev local,id=myid,path=.,security_model=mapped \
	-device virtio-9p-pci,fsdev=myid,mount_tag=hostshare \
	-net nic,model=e1000, -net tap,ifname=tap1,script=scripts/up.sh,downscript=scripts/down.sh  \
	-net nic,model=e1000, -net tap,ifname=tap2,script=no,downscript=no  \
	-nographic -s -S -pidfile vm.pid \
	-vga virtio \
	-monitor telnet:localhost:12345,server,nowait \
	2>&1 | tee vm.log
elif [ "$1" = "aarch64" ]; then
    sudo qemu-system-aarch64 \
	-machine virt,gic-version=max \
	-accel tcg,thread=multi \
	-cpu max \
	-smp 4 \
	-m 8G \
	-append "console=ttyAMA0 root=/dev/vda earlyprintk=serial slub_debug=UZ page_owner=on" \
	-kernel build/arch/arm64/boot/Image.gz \
	-drive file=$RELEASE.img,format=raw \
	-fsdev local,id=myid,path=.,security_model=mapped \
	-device virtio-9p-pci,fsdev=myid,mount_tag=hostshare \
	-net nic,model=e1000, -net tap,ifname=tap1,script=scripts/up.sh,downscript=scripts/down.sh  \
	-net nic,model=e1000, -net tap,ifname=tap2,script=no,downscript=no  \
	-nographic -s -S -pidfile vm.pid \
	-vga virtio \
	-monitor telnet:localhost:12345,server,nowait \
	2>&1 | tee vm.log
else
    echo "Invalid architecture $1"
    exit 1;
fi

# Quit qemu
# CTRL + A + X 
