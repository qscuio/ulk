# A linux kernel basic function test script.

## Step 1

```bash
. ./ulk kernel=6.9.6
```

> Note that qemu is started with -S flags, so the system will continue bootup only when gdb is connected and run continue command.

## Step 2

```bash
. ./scripts/gdb
```

## Step 3 (password qwert)

> Do not use root, we mount current directory to /home/qwert/ ...

```
ssh qwert@10.20.20.1
ssh qwert@10.10.10.1
```

## How To ssh

```sh
. ./scripts/connect
```

## How to open Qemu monitor

```sh
. ./scripts/monitor
```

```bash
 vim .config
 CONFIG_KCOV=y
 CONFIG_DEBUG_INFO=y
 CONFIG_KASAN=y
 CONFIG_KASAN_INLINE=y
 CONFIG_CONFIGFS_FS=y
 CONFIG_SECURITYFS=y
 # CONFIG_RANDOMIZE_BASE is not set
 make savedefconfig
 ```

## How To Install New package

```bash
rm -rf $RELEASE.id_rsa.pub
. ./ulk
. ./scripts/gdb
```

## How to disable gdb by default

Remove -S flags from qemu

## How to debug debootstrap does not work issue.

Check "chroot/debootstrap/debootstrap.log"

```bash
rm -rf $RELEASE.id_rsa*
sudo rm -rf chroot/{bin,sbin,lib,lib32,lib64,libx32,etc,usr,tmp,sys,srv,dev,mnt,proc,opt,run,home,boot}
```

## How to build crash

Crash should be compiled after login to guest os.

Our current directory is mapped into /home/qwert.

```sh
cd crash && make && make install
```
> It is really too slow to build crash in guest. So we keep a prebuild version in bins/$ARCH/crash

## How to run arm64 app with qemu

qemu-aarch64-static -L /usr/aarch64-linux-gnu/ ./main  

With `-L` option we can change the library search path for app run in qemu. This will fix the lib* cannot find issue.

