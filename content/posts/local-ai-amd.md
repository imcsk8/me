+++
title = 'Local AI Server From Scratch'
date = 2025-01-01T15:06:44-06:00
description = "How I built my own local Artificial Intelligence server from scratch"
summary = "This article is a tutorial on how to build your own Artificial Intelligence server from scratch on an AMD machine with a Radeon GPU."
draft = false
+++

# Local AI Server from Scratch

## Overview 

I like using the AI APIs but I also like to know how stuff works and there's no better
way of learning about something than doing it. So I set myself a the challenge of building
my own server with AI capabilities.

I'm a programmer and a sysadmin, I don't use the current buzzwords (SRE, DevOps, Fullstack, etc..)
because they tend to change every two or three years and in the end there are just three things
you can do with computers: use them, manage them and write programs for them.

TODO more overview

## Hardware

I searched the minimal setup for an entry level AI server:

TODO harwdare list

## Operating System

I chose Gentoo for this machine because it's a rolling distribution and I also want to experiment
with a full LLVM environment.

### Installation

Downloaded the [Gentoo Minimal ISO](https://distfiles.gentoo.org/releases/amd64/autobuilds/20241222T164831Z/install-amd64-minimal-20241222T164831Z.iso) from the [Gentoo](https://gentoo.org) webpage, also downloaded the [LLVM Stage3 with Systemd](https://distfiles.gentoo.org/releases/amd64/autobuilds/20241222T164831Z/stage3-amd64-llvm-systemd-20241222T164831Z.tar.xz) because I like Systemd.

1. **Save the ISO file to a USB Stick and boot the machine.**

TODO photo of the machine

2. **Configure IP address and start the sshd server.**

I like to work from my workstation so I started the sshd server on the new machine and logged in to it.

* **Configure IP address on the AI machine:**

```bash
livecd ~ # ip addr 192.168.1.150/24 dev eno1
livecd ~ # ip route add default via 192.168.1.254 dev eno1
livecd ~ # rc-service sshd start
```

* **Start a tmux session on workstation:**


```bash
imcsk8@sohoflip ~$ tmux new -s installation
imcsk8@sohoflip ~$ ssh root@192.168.1.150
livecd ~ #
```

3. **Create the partitions**

* **Get the disk device**
```bash
livecd ~ # fdisk -l
Disk /dev/nvme0n1: 1.86 TiB, 2048408248320 bytes, 4000797360 sectors
Disk model: FANTOM DRIVES VENOMX                    
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

* **Destroy GPT and MBR**

```bash
livecd ~ # sgdisk -Z /dev/nvme0n1
```

* **Destroy partition table**

```bash
livecd ~ # sgdisk -o /dev/nvme0n1
```

* **Create partitions**

EFI partition, `ef00` is the type code for EFI partitions.

```bash
livecd ~ # sgdisk -n 1::+1G -t 1:ef00 /dev/nvme0n1
livecd ~ # sgdisk -c 1:EFI /dev/nvme0n1
```

Swap partition.

```bash
livecd ~ # sgdisk -n 2::+4G -t 1:ef00 /dev/nvme0n1
livecd ~ # sgdisk -c 2:swap /dev/nvme0n1
```

Boot partition.

```bash
livecd ~ # sgdisk -n 3::+2G -t 3:8300 /dev/nvme0n1
livecd ~ # sgdisk -c 3:boot /dev/nvme0n1
```

Main partition. We will use `btrfs` with subvolumes for the `/root`, `/home` and `/var` filesystems.
If we omit the size on the `-n` switch it will take all the available space.

```bash
livecd ~ # sgdisk -n 4:: -t 4:8300 /dev/nvme0n1
livecd ~ # sgdisk -c 4:main /dev/nvme0n1
```


* **Format partitions**

The EFI partition must be `FAT32`.

```bash
livecd ~ # mkfs.fat -F32 /dev/nvme0n1p1
```

```bash
livecd ~ # mkswap /dev/nvme0n1p2 
```

```bash
livecd ~ # mkfs.ext4 -L boot /dev/nvme0n1p3
```

```bash
livecd ~ # mkfs -t btrfs -L btrfsroot /dev/nvme0n1p4
```

Verify that the partitions were properly created.

```bash
livecd ~ # parted /dev/nvme0n1 unit GiB print
Model: FANTOM DRIVES VENOMX (nvme)
Disk /dev/nvme0n1: 1908GiB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: 

Number  Start    End      Size     File system     Name  Flags
 1      0.00GiB  1.00GiB  1.00GiB  fat32           EFI   boot, esp
 2      1.00GiB  5.00GiB  4.00GiB  linux-swap(v1)  swap  swap
 3      5.00GiB  7.00GiB  2.00GiB  ext4            boot
 4      7.00GiB  1908GiB  1901GiB  btrfs           main
```

4. **Create BTRFS subvolumes**

* **Mount the partition**

```bash
livecd ~ # mkdir /mnt/gentoo
livecd ~ # mount /dev/nvme0n1p4 /mnt/gentoo
livecd ~ # cd /mnt/gentoo
livecd ~ # btrfs subvol create root
livecd ~ # btrfs subvol create home
livecd ~ # btrfs subvol create var
livecd ~ # btrfs subvol create srv
livecd ~ # umount /mnt/gentoo
```

5. Install the base system.

* **Chroot**

Mount filesystems
```bash
livecd ~ # mount -o defaults,noatime,compress=lzo,autodefrag,subvol=root /dev/nvme0n1p4 /mnt/gentoo
livecd ~ # cd /mnt/gentoo
livecd ~ # mkdir home root var boot srv
livecd ~ # mount -o defaults,noatime,compress=lzo,autodefrag,subvol=home /dev/nvme0n1p4 /mnt/gentoo/home
livecd ~ # mount -o defaults,noatime,compress=lzo,autodefrag,subvol=var /dev/nvme0n1p4 /mnt/gentoo/var
livecd ~ # mount -o defaults,noatime,compress=lzo,autodefrag,subvol=srv /dev/nvme0n1p4 /mnt/gentoo/srv
livecd ~ # mount -o defaults,noatime /dev/nvme0n1p3 /mnt/gentoo/boot
livecd ~ # mkdir /mnt/gentoo/boot/efi
livecd ~ # mount -o defaults,noatime /dev/nvme0n1p1 /mnt/gentoo/boot/efi
```

Get the gentoo stage3 with LLVM and Systemd (yes! Systemd!).

```bash
livecd ~ # wget https://distfiles.gentoo.org/releases/amd64/autobuilds/20241222T164831Z/stage3-amd64-llvm-systemd-20241222T164831Z.tar.xz
livecd ~ # tar xf stage3-amd64-llvm-systemd-20241222T164831Z.tar.xz 
```

Mount kernel pseudofilesystems.

```bash
livecd ~ # mount -t proc none proc
livecd ~ # mount --rbind /sys sys
livecd ~ # mount --rbind /dev dev
livecd ~ # swapon /dev/nvme0n1p2
```

Setup environment.

```bash
livecd ~ # cp -u /etc/resolv.conf /mnt/gentoo/etc/
livecd ~ # env -i HOME=/root TERM=$TERM chroot . bash -l
livecd ~ # emaint -A sync
livecd ~ # emerge --oneshot portage
livecd ~ # source /etc/profile
livecd ~ # export PS1="(chroot) $PS1"
```

* **Create fstab**

```bash
(chroot) livecd ~ # cat << 'EOF' > /etc/fstab
# <fs>      <mountpoint>    <type>  <opts>                                              <dump/pass>
shm         /dev/shm        tmpfs   nodev,nosuid,noexec                                      0 0
/dev/nvme0n1p4   /               btrfs   rw,noatime,compress=lzo,autodefrag,subvol=root      0 0
/dev/nvme0n1p4   /home           btrfs   rw,noatime,compress=lzo,autodefrag,subvol=home      0 0
/dev/nvme0n1p4   /srv            btrfs   rw,noatime,compress=lzo,autodefrag,subvol=srv       0 0
/dev/nvme0n1p4   /var            btrfs   rw,noatime,compress=lzo,autodefrag,subvol=var       0 0
/dev/nvme0n1p2   none            swap    sw                                                  0 0
/dev/nvme0n1p3   /boot           ext4    rw,noatime                                          0 0
/dev/nvme0n1p1   /boot/efi       vfat    umask=0077                                          0 2
EOF
```


* **Configure the build system**

```bash
(chroot) livecd ~ # emerge app-portage/cpuid2cpuflags
(chroot) livecd ~ # cpu_flags=$( cpuid2cpuflags )
```

* **Configure portage for LLVM**

* Make sure you're using the correct profile:

```bash
(chroot) livecd ~ # eselect profile set default/linux/amd64/23.0/llvm/systemd
```

* Set enviroment variables for `make.conf`:

```bash
(chroot) livecd ~ # use_remove='-X -accessibility -altivec -apache2 -aqua -big-endian -bindist -boundschecking -bsf -canna -clamav -connman -coreaudio -custom-cflags -debug -dedicated -emacs -handbook -ibm -infiniband -iwmmxt -kde -kontact -libav -libedit -libressl -libsamplerate -mono -mule -neon -oci8 -oci8-instant-client -oracle -oss -pch -pcmcia -plasma -qmail-spp -qt4 -qt5 -static -syslog -sysvipc -tcpd -xemacs -yahoo -zsh-completion'
(chroot) livecd ~ # use_add='symlink unicode vim-syntax initramfs redistributable grub dracut dist-kernel'
(chroot) livecd ~ # make_opts="-j$(( 1 + 1 + $( lscpu -p | tail -n 1 | cut -d ',' -f 1 ) ))"
(chroot) livecd ~ # echo "sys-apps/systemd boot" > /etc/portage/package.use/systemd
```

* Configure `make.conf`:

```bash
(chroot) livecd ~ # cat << EOF > /etc/portage/make.conf
# Optimizacions
CFLAGS="-march=native -mtune=native -O2 -pipe -flto=thin"
CXXFLAGS="\$CFLAGS"
FCFLAGS="\$CFLAGS"
FFLAGS="\$CFLAGS"

# clang LLVM
CC="clang"
CPP="clang-cpp" # necessary for xorg-server and possibly other packages
CXX="clang++"
AR="llvm-ar"
NM="llvm-nm"
RANLIB="llvm-ranlib"
LDFLAGS="-fuse-ld=lld -rtlib=compiler-rt -unwindlib=libunwind -Wl,-O2 -Wl,--as-needed"

CHOST="x86_64-pc-linux-gnu"
MAKEOPTS="${make_opts}"
ADD="${use_add}"
REMOVE="${use_remove}"
USE="\$REMOVE \$ADD"
${cpu_flags}
# Portage Opts
FEATURES="parallel-fetch parallel-install ebuild-locks"
EMERGE_DEFAULT_OPTS="--with-bdeps=y"
AUTOCLEAN="yes"
RUSTFLAGS="${RUSTFLAGS} -C target-cpu=native"
LC_MESSAGES=C.utf8
VIDEO_CARDS="amdgpu radeonsi"
EOF

```

* Configure Clang and rebuild LLVM with the LLVM toolchain:

```bash
(chroot) livecd ~ # echo "sys-devel/clang-common default-compiler-rt default-lld llvm-libunwind sanitize" > /etc/portage/package.use/clang 
(chroot) livecd ~ # USE="-doc static-analyzer extra" emerge --ask --update --deep --changed-use  --autounmask-backtrack=y \
  llvm-core/clang llvm-core/llvm llvm-runtimes/libcxx llvm-runtimes/libcxxabi llvm-runtimes/compiler-rt \
  llvm-runtimes/compiler-rt-sanitizers llvm-runtimes/libunwind llvm-core/lld
```

* Configure GCC fallback environment:

```bash
(chroot) livecd ~ # mkdir /etc/portage/env
(chroot) livecd ~ # cat << EOF > /etc/portage/env/compiler-gcc
COMMON_FLAGS="-O2 -march=native"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
LDFLAGS="-Wl,--as-needed"

CC="gcc"
CXX="g++"
CPP="gcc -E"
AR="ar"
NM="nm"
RANLIB="ranlib"
EOF
```

If a package fails to install with `clang` set the the fallback flags in the `/etc/portage/package.env` file in
the following way:

```bash
app-bar/baz compiler-gcc
```

* **Configure locale**

```bash
(chroot) livecd ~ # cat << EOF > /etc/locale.gen
en_US.UTF-8 UTF-8
es_MX.UTF-8 UTF-8
EOF
```

```bash
(chroot) livecd ~ # locale-gen
(chroot) livecd ~ # eselect locale list
Available targets for the LANG variable:
  [1]   C
  [2]   C.utf8
  [3]   POSIX
  [4]   en_US.utf8
  [5]   es_MX.utf8
  [6]   C.UTF8 *
  [ ]   (free form)
(chroot) livecd / # eselect locale set 4
```

* Configure kernel command line:

```bash
(chroot) livecd ~ # echo "quiet splash" > /etc/kernel/cmdline
```


* **Install system tools**
```bash
(chroot) livecd ~ # emerge --sync --quiet
(chroot) livecd ~ # echo "sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE" > /etc/portage/package.license
(chroot) livecd ~ # emerge sys-kernel/linux-firmware grub sys-kernel/installkernel vim bash-completion \
  btrfs-progs app-portage/eix app-portage/gentoolkit sys-process/htop sys-process/glances sys-process/lsof \
  gentoolkit
(chroot) livecd ~ # eselect bashcomp enable --global gentoo
```

* **Install ROCM libraries and tools**

```bash
(chroot) livecd ~ # emerge --autounmask-write --autounmask dev-libs/rocm-opencl-runtime dev-util/rocm-smi \
  dev-libs/rocm-device-libs dev-libs/rocm-comgr dev-libs/rocm-device-libs dev-util/rocminfo \
  dev-util/rocm_bandwidth_test
```

* **Update system**

```bash
(chroot) livecd ~ # emerge -juDN @world
```

6. Install the kernel

Gentoo provides different ways of configuring and installing the kernel, the recommended
way is `dist-kernel` because it provides configuration flexibility and integration with
the package system.

* **Install the kernel package**

Use the latest kernel by setting the `ACCEPT_KEYWORDS="~amd64"` variable.

```bash
(chroot) livecd ~ # ACCEPT_KEYWORDS="~amd64" emerge -av sys-kernel/gentoo-kernel
```

* Sign the kernel and its modules (TODO)

* **Configure kernel**

```bash
(chroot) livecd ~ # ebuild /var/db/repos/gentoo/sys-kernel/gentoo-kernel/gentoo-kernel-6.12.7.ebuild configure
(chroot) livecd ~ # cd /var/tmp/portage/sys-kernel/gentoo-kernel-6.12.7/work/modprep
(chroot) livecd ~ # make menuconfig
```

Kernel configuration for Ryzen 9 7950:

```
Processor type and features  --->
  [*] Symmetric multi-processing support 
  [*] Support x2apic 
  [*] AMD ACPI2Platform devices support 
  [*] Supported processor vendors   --->
    [*]   Support AMD processors 
  [*] SMT (Hyperthreading) scheduler support
  [*] Multi-core scheduler support 
  [*] Machine Check / overheating reporting 
  [*]   AMD MCE features
  Performance monitoring  --->
    <*> Intel/AMD rapl performance events 
  [*]   AMD microcode loading support 
Power management and ACPI options  --->
  CPU Frequency scaling  --->
      Default CPUFreq governor (ondemand)   --->
    <*>   ACPI Processor P-States driver 
    [ /*]     Legacy cpb sysfs knob support for AMD CPUs 
    < >   AMD Opteron/Athlon64 PowerNow! 
    <*>   AMD frequency sensitivity feedback powersave bias
```


The firmware for the Ryzen 9 7950 is: `amd-ucode/microcode_amd_fam19h.bin`

```
Device Drivers  --->
  Generic Driver Options --->
    Firmware loader  --->

        [*]   Log filenames and checksums for loaded firmware
        (amd-ucode/microcode_amd_fam19h.bin) Build named firmware blobs into the kernel binary
        (/lib/firmware) Firmware blobs root directory (NEW)
  [*] Hardware Monitoring support  --->
    <*>   AMD Family 10h+ temperature sensor 
  [*] IOMMU Hardware Support   --->
    [*]   AMD IOMMU support 
    <*>     AMD IOMMU Version 2 driver 
  [*]   GPIO Support   --->
    Memory mapped GPIO drivers  --->
      <*> AMD Promontory GPIO support 
  [*] X86 Platform Specific Device Drivers   --->
    <*>   AMD SoC PMC driver

```

Use this configuration for the `amdgpu` driver:

```
Processor type and features  --->
    [*] MTRR (Memory Type Range Register) support 
Memory Management options  --->
    [*] Memory hotplug   --->
    [*]   Allow for memory hot remove 
    [*] Device memory (pmem, HMM, etc...) hotplug support 
    [*] Unaddressable device memory (GPU memory, ...) 
Device Drivers  --->
    Graphics support  --->
        <*/M> Direct Rendering Manager (XFree86 4.1.0 and higher DRI support)  --->
        [*] Enable legacy fbdev support for your modesetting driver 
        < > ATI Radeon 
        <M/*> AMD GPU 
          [ /*] Enable amdgpu support for SI parts 
                (only needed for Southern Islands GPUs with the amdgpu driver)
          [ /*] Enable amdgpu support for CIK parts 
                (only needed for Sea Islands GPUs with the amdgpu driver)
          ACP (Audio CoProcessor) Configuration  ---> 
               [*] Enable AMD Audio CoProcessor IP support 
                   (only needed for APUs)
          Display Engine Configuration  --->
               [*] AMD DC - Enable new display engine 
               [ /*] DC support for Polaris and older ASICs 
                     (only needed for Polaris, Carrizo, Tonga, Bonaire, Hawaii)
               [ /*] AMD FBC - Enable Frame Buffer Compression 
               [ /*] DCN 1.0 Raven family 
                     (only needed for Vega RX as part of Raven Ridge APUs)
               [ /*] DCN 3.0 family 
                     (only needed for NAVI21/Sienna Cichlid GPUs with the amdgpu driver)
          [*]   HSA kernel driver for AMD GPU devices 
          [*]     Enable HMM-based shared virtual memory manager 
    <*/M> Sound card support   --->
        <*/M> Advanced Linux Sound Architecture   --->
            [*]   PCI sound devices  --->
                  HD-Audio  --->
                      <*> HD Audio PCI 
                      [ /*] Support initialization patch loading for HD-audio 
                      <*> Build whatever audio codec your soundcard needs codec support
                      <*> Build HDMI/DisplayPort HD-audio codec support 
                  (2048) Pre-allocated buffer size for HD-audio driver
```

Enable systemd sypport on the kernel:

```
Gentoo Linux --->
   Support for init systems, system and service managers --->
      [*] systemd
```

**To make this kernel configuration available across package upgrades copy the .config file to the
/etc/portage/savedconfig/sys-kernel/gentoo-kernel**

```bash
(chroot) livecd /var/tmp/portage/sys-kernel/gentoo-kernel-6.12.7/work/modprep # cp /etc/portage/savedconfig/sys-kernel/gentoo-kernel-6.12.7 \
  /etc/portage/savedconfig/sys-kernel/gentoo-kernel-6.12.7.bak
(chroot) livecd /var/tmp/portage/sys-kernel/gentoo-kernel-6.12.7/work/modprep # cp .config \
  /etc/portage/savedconfig/sys-kernel/gentoo-kernel-6.12.7
(chroot) livecd # cd
(chroot) livecd # echo "sys-kernel/gentoo-kernel savedconfig" >> /etc/portage/package.use/sys-kernel
```

* Build the kernel and initramfs:
```bash
(chroot) livecd #  ACCEPT_KEYWORDS="~amd64" emerge -av sys-kernel/gentoo-kernel
```


7. Configure Network

* Install NetworkManager:

```bash
(chroot) livecd ~ # emerge --autounmask-write networkmanager
(chroot) livecd ~ # etc-update --automode -5
```

* Configure network:

```bash
(chroot) livecd ~ # nmcli --offline conn add con-name "soho" ifname eno1 type ethernet \
  ip4 192.168.1.150/24 gw4 192.168.1.254 ipv4.dns 192.168.1.254,8.8.8.8 
  > /etc/NetworkManager/system-connections/soho.nmconnection
(chroot) livecd ~ # chown 600 /etc/NetworkManager/system-connections/soho.nmconnection
```

8. Configure systemd.

```bash
(chroot) livecd ~ # systemd-machine-id-setup
(chroot) livecd ~ # systemd-firstboot --prompt
(chroot) livecd ~ # systemctl preset-all --preset-mode=enable-only
(chroot) livecd ~ # systemctl preset-all
(chroot) livecd ~ # systemctl enable sshd
```

9. Setup users.

```bash
(chroot) livecd ~ # groupadd sotolito
(chroot) livecd ~ # groupadd ai
(chroot) livecd ~ # useradd -g sotolito -Gwheel,ai -c 'Sotolito Crafts' -s /bin/bash -d /home/sotolito sotolito
(chroot) livecd ~ # passwd sotolito
(chroot) livecd ~ # passwd root
```

10. Misc Setup.

```bash
(chroot) livecd ~ # emerge --ask --autounmask-write app-shells/bash-completion \
  net-misc/chrony sys-fs/btrfs-progs sys-fs/dosfstools sys-block/io-scheduler-udev-rules
(chroot) livecd ~ # etc-update --automode -5
(chroot) livecd ~ # systemctl enable chronyd.service
```

11. Install grub.

Ensure that EFI is enabled:

```bash
(chroot) livecd ~ # echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
```

Install grub:
```bash
(chroot) livecd ~ # emerge --ask sys-boot/grub
(chroot) livecd ~ # grub-install --target=x86_64-efi
```

TODO: Secureboot

12. Cleanup and reboot.

Umount filesystems, systemd tools mounted a bunch of pseudofilesystems that we have to manually unmount.

```bash
(chroot) livecd ~ # exit
(chroot) livecd ~ # umount /mnt/gentoo/{home,var,srv,boot/efi,boot,proc,sys/kernel/security,sys/kernel/debug,sys/kernel/config,sys/fs/pstore,sys/firmware/efi/efivars,sys/fs/cgroup,sys,dev/pts,dev/shm,dev/mqueue,dev} /mnt/gentoo
(chroot) livecd ~ # reboot
```

### Post-Installation Tasks

1. SSH.

* **Copy ssh keys**

```bash
~ $ ssh-copy-id sotolito@192.168.1.150
sotolito@sohoai1 ~ $ su -
root@sohoai1 ~ # ssh-keygen
root@sohoai1 ~ # cp -p ~sotolito/.ssh/authorized_keys .ssh/
root@sohoai1 ~ # chown root:root .ssh/authorized_keys
root@sohoai1 ~ # exit
sotolito@sohoai1 ~ $ exit
```

* **Test public key authentication**

```bash
imcsk8@soho ~$ ssh root@192.168.1.150
```

2. Administration packages.
TODO

# References
* https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation/en
* https://wiki.gentoo.org/wiki/Clang/Bootstrapping
* https://wiki.gentoo.org/wiki/Ryzen
* https://wiki.gentoo.org/wiki/AMDGPU
* https://wiki.gentoo.org/wiki/Systemd
* https://wiki.gentoo.org/wiki/GRUB2_Quick_Start
* https://gitlab.com/-/snippets/1728487
