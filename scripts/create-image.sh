#!/usr/bin/env bash
# Copyright 2016 syzkaller project authors. All rights reserved.
# Use of this source code is governed by Apache 2 LICENSE that can be found in the LICENSE file.

# create-image.sh creates a minimal Debian Linux image suitable for syzkaller.

set -eux

# Create a minimal Debian distribution in a directory.
DIR=chroot
PREINSTALL_PKGS=openssh-server,curl,tar,gdb,gdbserver,gcc,g++,libc6-dev,libc6-dbg,time,strace,sudo,less,psmisc,selinux-utils,policycoreutils,checkpolicy,selinux-policy-default,firmware-atheros,debian-ports-archive-keyring,net-tools,locales

# If ADD_PACKAGE is not defined as an external environment variable, use our default packages
if [ -z ${ADD_PACKAGE+x} ]; then
    ADD_PACKAGE="make,sysbench,git,vim,tmux,usbutils,pciutils,tcpdump,file,liblzma-dev,libncursesw5-dev,libboost-regex-dev,zlib1g-dev,texinfo,bison,patch,locales,cmake"
fi

# Variables affected by options
ARCH=$(uname -m)
RELEASE=jammy
#RELEASE=bullseye
#FEATURE=minimal
FEATURE=full
KERNEL=kernel/linux/
SEEK=8192
PERF=false
USERNAME="qwert"
PASSWORD="qwert"
EXCLUDES=
MIRROR=

USER_PACKAGES="libwrap0-dev libcunit1 libcunit1-dev libaio-dev libunbound-dev libssl-dev libunwind-dev \
    libuv1-dev libcurl4-gnutls-dev flex bison pkgconf python3-dev python3-setuptools python3-pip libzstd-dev \
    libcap-dev libbabeltrace-ctf-dev libcapstone-dev libpfm4-dev libdw-dev libelf-dev systemtap-sdt-dev \
    libunwind8-dev libaudit-dev libslang2-dev libperl-dev binutils-dev liblzma-dev libnuma-dev libtraceevent-dev \
    libssl-dev clang elfutils lsof llvm cargo"

# Display help function
display_help() {
    echo "Usage: $0 [option...] " >&2
    echo
    echo "   -a, --arch                 Set architecture"
    echo "   -d, --distribution         Set on which debian distribution to create"
    echo "   -f, --feature              Check what packages to install in the image, options are minimal, full"
    echo "   -s, --seek                 Image size (MB), default 2048 (2G)"
    echo "   -h, --help                 Display help message"
    echo "   -p, --add-perf             Add perf support with this option enabled. Please set envrionment variable \$KERNEL at first"
    echo
}

while true; do
    if [ $# -eq 0 ];then
	echo $#
	break
    fi
    case "$1" in
        -h | --help)
            display_help
            exit 0
            ;;
        -a | --arch)
	    ARCH=$2
            shift 2
            ;;
        -d | --distribution)
	    RELEASE=$2
            shift 2
            ;;
        -f | --feature)
	    FEATURE=$2
            shift 2
            ;;
        -s | --seek)
	    SEEK=$(($2 - 1))
            shift 2
            ;;
        -p | --add-perf)
	    PERF=true
            shift 1
            ;;
        -m | --user-mirror)
	    MIRROR=https://mirrors.tuna.tsinghua.edu.cn/ubuntu/
	    shift 1
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;
        *)  # No more options
            break
            ;;
    esac
done

# Handle cases where qemu and Debian use different arch names
case "$ARCH" in
    ppc64le)
        DEBARCH=ppc64el
        ;;
    aarch64)
        DEBARCH=arm64
        ;;
    arm)
        DEBARCH=armel
        ;;
    x86_64)
        DEBARCH=amd64
        ;;
    *)
        DEBARCH=$ARCH
        ;;
esac

# Foreign architecture

FOREIGN=false
if [ $ARCH != $(uname -m) ]; then
    # i386 on an x86_64 host is exempted, as we can run i386 binaries natively
    if [ $ARCH != "i386" -o $(uname -m) != "x86_64" ]; then
        FOREIGN=true
    fi
fi

if [ $FOREIGN = "true" ]; then
    # Check for according qemu static binary
    if ! which qemu-$ARCH-static; then
        echo "Please install qemu static binary for architecture $ARCH (package 'qemu-user-static' on Debian/Ubuntu/Fedora)"
        exit 1
    fi
    # Check for according binfmt entry
    if [ ! -r /proc/sys/fs/binfmt_misc/qemu-$ARCH ]; then
        echo "binfmt entry /proc/sys/fs/binfmt_misc/qemu-$ARCH does not exist"
        exit 1
    fi
fi

# Double check KERNEL when PERF is enabled
if [ $PERF = "true" ] && [ -z ${KERNEL+x} ]; then
    echo "Please set KERNEL environment variable when PERF is enabled"
    exit 1
fi

# If full feature is chosen, install more packages
if [ $FEATURE = "full" ]; then
    PREINSTALL_PKGS=$PREINSTALL_PKGS","$ADD_PACKAGE
fi

if [ ! -f $RELEASE.id_rsa.pub ]; then
#    sudo rm -rf $DIR
    sudo mkdir -p $DIR
    sudo chmod 0755 $DIR
fi

echo "!!!!Starting Stage 1!!!!"

if [ $RELEASE != "bullseye" ]; then
    EXCLUDES="libwrap0,texinfo,firmware-atheros,checkpolicy,selinux-utils,gdbserver,policycoreutils,sysbench,selinux-policy-default,debian-ports-archive-keyring"
    EXCLUDES_DEB="libwrap0 texinfo checkpolicy selinux-utils gdbserver policycoreutils sysbench selinux-policy-default debian-ports-archive-keyring"
    USER_PACKAGES="$USER_PACKAGES $EXCLUDES_DEB"
fi

#  debootstrap stage
if [ -z "$EXCLUDES" ]; then
    DEBOOTSTRAP_PARAMS="--arch=$DEBARCH --include=$PREINSTALL_PKGS --components=main,contrib,non-free,non-free-firmware $RELEASE $DIR $MIRROR"
else
    DEBOOTSTRAP_PARAMS="--arch=$DEBARCH --exclude=$EXCLUDES --include=$PREINSTALL_PKGS --components=main,contrib,non-free,non-free-firmware $RELEASE $DIR $MIRROR"
fi

if [ $FOREIGN = "true" ]; then
    DEBOOTSTRAP_PARAMS="--foreign $DEBOOTSTRAP_PARAMS"
fi

# riscv64 is hosted in the debian-ports repository
# debian-ports doesn't include non-free, so we exclude firmware-atheros
if [ $DEBARCH == "riscv64" ]; then
    DEBOOTSTRAP_PARAMS="--keyring /usr/share/keyrings/debian-ports-archive-keyring.gpg --exclude firmware-atheros $DEBOOTSTRAP_PARAMS http://deb.debian.org/debian-ports"
fi

if [ ! -f .debootstrap ]; then
    sudo --preserve-env=http_proxy,https_proxy,ftp_proxy,no_proxy debootstrap $DEBOOTSTRAP_PARAMS

    if [ $FOREIGN = "true" ]; then
	sudo cp $(which qemu-$ARCH-static) $DIR/$(which qemu-$ARCH-static)
	sudo chroot $DIR /bin/bash -c "/debootstrap/debootstrap --second-stage"
    fi
    touch .debootstrap
fi

echo "!!!!Starting Stage 2!!!!"

if [ ! -f $RELEASE.id_rsa.pub ]; then
    sudo cp -a bins/$ARCH/* $DIR/usr/bin/

    # Create a user for ssh connect.
    sudo chroot $DIR /bin/bash -c "
	useradd -m -s /bin/bash $USERNAME;
	echo '$USERNAME:$PASSWORD' | chpasswd;
	usermod -aG sudo $USERNAME;
	echo '$USERNAME ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;
	systemctl enable ssh"

    # sudo chroot $DIR /bin/bash -c "setenforce 0"

    # Set some defaults and enable promtless ssh to the machine for root.
    sudo sed -i '/^root/ { s/:x:/::/ }' $DIR/etc/passwd
    echo 'T0:23:respawn:/sbin/getty -L ttyS0 115200 vt100' | sudo tee -a $DIR/etc/inittab

    # Add udev rules for custom drivers.
    # Create a /dev/vim2m symlink for the device managed by the vim2m driver
    echo 'ATTR{name}=="vim2m", SYMLINK+="vim2m"' | sudo tee -a $DIR/etc/udev/rules.d/50-udev-default.rules
    echo 'SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="52:54:00:12:34:56", NAME="eth01"' | sudo tee -a $DIR/etc/udev/rules.d/50-udev-default.rules
    echo 'SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="52:54:00:12:34:57", NAME="eth02"' | sudo tee -a $DIR/etc/udev/rules.d/50-udev-default.rules

    if [ $RELEASE == "bullseye" ]; then
	printf '\nauto eth01\niface eth01 inet static \n  address 10.10.10.1\n  netmask 255.255.255.0\n  gateway 10.10.10.254\n  dns-nameservers 4.4.4.4 8.8.8.8\niface eth01 inet6 static \n  address 2001:db8:10::1\n  netmask 64\n  gateway 2001:db8:10::254\n  dns-nameservers 2001:4860:4860::8888 2001:4860:4860::8844' | sudo tee -a $DIR/etc/network/interfaces
	printf '\nauto eth02\niface eth02 inet static \n  address 10.20.20.1\n  netmask 255.255.255.0\n  gateway 10.20.20.254\n  dns-nameservers 4.4.4.4 8.8.8.8\niface eth02 inet6 static \n  address 2001:db8:20::1\n  netmask 64\n  gateway 2001:db8:20::254\n  dns-nameservers 2001:4860:4860::8888 2001:4860:4860::8844' | sudo tee -a $DIR/etc/network/interfaces
    else
	sudo cp configs/$RELEASE/01-netcfg.yaml $DIR/etc/netplan
	sudo cp configs/$RELEASE/sources.list $DIR/etc/apt
    fi
    echo '/dev/root / ext4 defaults 0 0' | sudo tee -a $DIR/etc/fstab
    echo 'debugfs /sys/kernel/debug debugfs defaults 0 0' | sudo tee -a $DIR/etc/fstab
    echo 'securityfs /sys/kernel/security securityfs defaults 0 0' | sudo tee -a $DIR/etc/fstab
    echo 'configfs /sys/kernel/config/ configfs defaults 0 0' | sudo tee -a $DIR/etc/fstab
    echo 'binfmt_misc /proc/sys/fs/binfmt_misc binfmt_misc defaults 0 0' | sudo tee -a $DIR/etc/fstab
    echo 'hostshare /home/qwert 9p trans=virtio 0 0' | sudo tee -a $DIR/etc/fstab
    echo -en "127.0.0.1\tlocalhost\n" | sudo tee $DIR/etc/hosts
    echo -en "127.0.0.1\tsyzkaller\n" | sudo tee -a $DIR/etc/hosts
    echo "nameserver 8.8.8.8" | sudo tee -a $DIR/etc/resolve.conf
    echo "qwert" | sudo tee $DIR/etc/hostname

    # We need proxy for apt-get in chroot
    sudo chroot $DIR /bin/bash -c "
	echo 'export http_proxy=$http_proxy' >> /etc/profile
	echo 'export https_proxy=$https_proxy' >> /etc/profile
	echo 'Acquire::http::Proxy \"http://$http_proxy\";' > /etc/apt/apt.conf.d/95proxies
	echo 'Acquire::https::Proxy \"http://$https_proxy\";' >> /etc/apt/apt.conf.d/95proxies
	echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen 
	echo 'LANG=en_US.UTF-8' >> /etc/default/locale
	echo 'LANGUAGE=en_US:en' >> /etc/default/locale
	echo 'LC_ALL=en_US.UTF-8' >> /etc/default/locale
	locale-gen 
	"
    ssh-keygen -f $RELEASE.id_rsa -t rsa -N ''
    # Current directory will overwrite home directory of $USERNAME.
    mkdir -p .ssh/
    sudo mkdir -p $DIR/root/.ssh/
    sudo mkdir -p $DIR/home/$USERNAME/.ssh/
    cat $RELEASE.id_rsa.pub | tee .ssh/authorized_keys
    cat $RELEASE.id_rsa.pub | sudo tee $DIR/root/.ssh/authorized_keys
    cat $RELEASE.id_rsa.pub | sudo tee $DIR/home/$USERNAME/.ssh/authorized_keys
fi

if [ -n "$USER_PACKAGES" ] && [ ! -f .user_packages ]; then
    sudo cp -af kernel/include $DIR/usr/
    sudo chroot $DIR /bin/bash -c "apt-get update"
    sudo chroot $DIR /bin/bash -c "apt-get install -y $USER_PACKAGES"
    sudo chroot $DIR /bin/bash -c "pip3 install drgn --proxy http://$http_proxy"
    touch .user_packages
fi

# Add perf support
if [ $PERF = "true" ] && [ ! -f $DIR/usr/bin/perf ]; then
    sudo cp -r $KERNEL $DIR/tmp/
    BASENAME=$(basename $KERNEL)
    sudo chroot $DIR /bin/bash -c "cd /tmp/$BASENAME/tools/perf/; make"
    sudo chroot $DIR /bin/bash -c "cp /tmp/$BASENAME/tools/perf/perf /usr/bin/"
    sudo rm -r $DIR/tmp/$BASENAME
fi

# Build a disk image
dd if=/dev/zero of=$RELEASE.img bs=1M seek=$SEEK count=1
sudo mkfs.ext4 -F $RELEASE.img
sudo mkdir -p /mnt/$DIR
sudo mount -o loop $RELEASE.img /mnt/$DIR
sudo cp -a $DIR/. /mnt/$DIR/.
sudo umount /mnt/$DIR
