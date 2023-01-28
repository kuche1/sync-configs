#! /usr/bin/env bash

set -e
set -o xtrace

systemctl start sshd

# on the conneting machine:
#	ssh-keygen -R 192.168.2.104 # wtf do i need this
#	ssh root@192.168.2.104


# format
parted /dev/sda mklabel gpt

parted /dev/sda mkpart primary fat32 0% 512MiB
parted /dev/sda set 1 esp on

parted /dev/sda mkpart primary ext4 512MiB 100%
parted /dev/sda set 2 lvm on

# format 2nd disk
parted /dev/sdb mklabel gpt
parted /dev/sdb mkpart primary ext4 0% 100%
parted /dev/sdb set 1 lvm on

# activate
pvcreate /dev/sda2
pvcreate /dev/sdb1

# check if everything is OK
pvs

vgcreate myVolGr /dev/sda2 /dev/sdb1

# check
vgs

# activate the volume group (wtf does this event do anything?)
# this might be useless
vgchange -a y myVolGr

# create logical volume
lvcreate -l 100%FREE myVolGr -n myRootVol

# activate the volume group (wtf does this event do anything?)
vgchange -a y myVolGr

# check
lvs

# format
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/mapper/myVolGr-myRootVol

mount /dev/mapper/myVolGr-myRootVol /mnt

mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

mkdir /mnt/etc

genfstab -U -p /mnt >> /mnt/etc/fstab
# u can also double-check the file just in case

pacstrap /mnt base

arch-chroot /mnt pacman -S linux-zen linux-zen-headers linux-firmware micro base-devel networkmanager dialog lvm2
# wifi -> wpa_supplicant wireless_tools netctl

arch-chroot /mnt systemctl enable NetworkManager

arch-chroot /mnt micro /etc/mkinitcpio.conf
# find "HOOKS="
# before "filesystem" insert "encrypt lvm2"
# (`encrypt` doesn't isn't needed in this case since we're not using encryption, but let's keep it here for good measure)

arch-chroot /mnt mkinitcpio -p linux-zen

arch-chroot /mnt echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
arch-chroot /mnt locale-gen

arch-chroot /mnt echo 'LANG=en_US.UTF-8' > /etc/locale.conf

arch-chroot /mnt passwd

arch-chroot /mnt useradd -m -g users -G wheel me
# TODO don't we have to set `me`'s password here also?

# TODO what about `EDITOR=micro`
arch-chroot /mnt visudo
# uncomment `# %wheel ALL=(ALL) ALL`

arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Sofia /etc/localtime

arch-chroot /mnt hwclock --systohc

arch-chroot /mnt echo 'navi' > /etc/hostname

arch-chroot /mnt echo '127.0.0.1   localhost' > /etc/hosts
arch-chroot /mnt echo '::1 localhost' >> /etc/hosts
arch-chroot /mnt echo '127.0.1.1   navi.localdomain    navi' >> /etc/hosts
# use static instead of 127.0.0.1

arch-chroot /mnt pacman -S grub efibootmgr dosfstools os-prober mtools openssh
# os-prober -> if multiple OS-es

# seems like all of this is needed only if u use encryption
	#micro /etc/default/grub
	# change GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
	#
	# to GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=/dev/sda2:myVolGr:allow-discards"
	# to GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=/dev/sdb2:myVolGr:allow-discards"
	#
	# uncomment "#GRUB_ENABLE_CRYPTODISK=y"

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=SEXlinux --recheck

arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

sync

echo 'Please run `umount -a`'
