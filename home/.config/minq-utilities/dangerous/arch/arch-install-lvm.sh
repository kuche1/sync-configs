#! /usr/bin/env bash

set -e
set -o xtrace

trap 'echo "ctrl+c to enter debug" ; read tmp ; umount /mnt/boot/efi ; umount /mnt ; vgremove --force myVolGr' EXIT

# generic fncs

chroot_run(){
	arch-chroot /mnt "$@"
}

pkg_install(){
	chroot_run pacman --noconfirm -S --needed "$@"
}

aur_install(){
	# chroot_run su me -c "echo \"${user_password}\" | paru --sudo sudo --sudoflags -S --noconfirm -S --needed \"$@\""
	(cat << EOF
su me
echo "#! /usr/bin/env bash" > /tmp/free-sudo.sh
echo "echo arguments passed: \$@" >> /tmp/free-sudo.sh
echo "echo \"${user_password}\" | sudo -S -k \"\$@\"" >> /tmp/free-sudo.sh
chmod +x /tmp/free-sudo.sh
paru --sudo /tmp/free-sudo.sh --noconfirm -S --needed "$@"
exit
EOF
	) | chroot_run bash
	# TODO chown might have been the problem with the `visudo` fail
}

# specific fncs

add_lvm2_hook_to_mkinitcpio(){
	# # TODO this can be automated
	# chroot_run micro /etc/mkinitcpio.conf
	# # find "HOOKS="
	# # before "filesystem" insert "encrypt lvm2"
	# # (`encrypt` doesn't isn't needed in this case since we're not using encryption, but let's keep it here for good measure)

	# chroot_run sed -i 's/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystem fsck)/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block lvm2 filesystem fsck)/' /etc/mkinitcpio.conf
	# chroot_run python3 -c 'f = open(/etc/mkinitcpio.conf); cont = f.read(); assert; f.close()'

	# TODO can we make this run in chroot?
	# same goes for all other instances that use this pattern
	(cat << EOF
import re
import sys

with open('/etc/mkinitcpio.conf', 'r') as f:
	cont = f.read()
found = re.search('\nHOOKS=\(.*\)\n', cont)
assert found != None, 'hooks line not found'
hooks = cont[found.start():found.end()]

match hooks.count(' lvm2 filesystems '):
	case 0:
		pass
	case 1:
		print('lvm2 hook already set up, exiting')
		sys.exit()
	case other:
		assert False, f'bad count ({other})'

count = hooks.count(' filesystems ')
assert count == 1, f'invalid number of "filesystems" found in hooks, {count=} {hooks=}'
hooks = hooks.replace(' filesystems ', ' lvm2 filesystems ')
cont = cont[:found.start()] + hooks + cont[found.end():]

with open('/etc/mkinitcpio.conf', 'w') as f:
	f.write(cont)

sys.exit()
EOF
	 ) | chroot_run python3
}

fix_pacman_config(){
	# enable 32 bit repo
	chroot_run sed -i -z 's%\n#\[multilib\]\n#Include = /etc/pacman.d/mirrorlist\n%\n\[multilib\]\nInclude = /etc/pacman.d/mirrorlist\n%' /etc/pacman.conf
    chroot_run pacman -Syuu
	# add color
	chroot_run sed -i -z 's%\n#Color\n%\nColor\n%' /etc/pacman.conf
	# verbose packages
	chroot_run sed -i -z 's%\n#VerbosePkgLists\n%\nVerbosePkgLists\n%' /etc/pacman.conf
	# parallel download
	chroot_run sed -i -z 's%\n#ParallelDownloads = 5\n%\nParallelDownloads = 5\n%' /etc/pacman.conf
}

set_up_aur_helper(){
	# needs to be called after the user has been created

	pkg_install base-devel
	# compilation threads (related to the AUR helper)
	chroot_run sed -i -z 's%\n#MAKEFLAGS="-j2"\n%\nMAKEFLAGS="-j$(nproc)"\n%' /etc/makepkg.conf
		# we need `base-devel` installed, otherwise the config file will not be created

	pkg_install git
	pkg_install cargo
	# install paru if not already installed
	# TODO this asks user password for sudo prompt
	(cat << EOF
set -e
paru --version && exit
cd /tmp
rm -rf ./paru
su me
git clone https://aur.archlinux.org/paru.git
cd ./paru
makepkg
exit
cd ./paru
pacman --noconfirm -U paru-*.pkg.tar.zst
exit
EOF
	 ) | chroot_run bash
	# paru settings
	chroot_run sed -i -z 's%\n#BottomUp\n%\nBottomUp\n%' /etc/paru.conf
}

config_visudo(){
# 	(cat << EOF

# cat << EOF2 > /tmp/visudo-fixer.py
# #! /usr/bin/env python3
# import sys
# import argparse

# TO_REPLACE   = '\n# %wheel ALL=(ALL:ALL) ALL\n'
# REPLACE_WITH = '\n%wheel ALL=(ALL:ALL) ALL\n'

# parser = argparse.ArgumentParser(description='Command line port of nhentai')
# parser.add_argument(visudo_file)
# args = parser.parse_args()
# visudo_file = args.visudo_file

# with open(visudo_file, 'r') as f:
# 	cont = f.read()

# match cont.count(TO_REPLACE):
# 	case 0:
# 		count = cont.count(REPLACE_WITH)
# 		assert count == 1, f'invalid number of occurances of uncommented wheel: {count}' # TODO this assert doesn't seem to work
# 		print('wheel already set up, exiting')
# 		sys.exit()
# 	case 1:
# 		cont = cont.replace(TO_REPLACE, REPLACE_WITH)
# 	case other:
# 		assert False, f'invalid number of occurances of commented wheel: {other}'

# with open(visudo_file, 'w') as f:
# 	f.write(cont)

# EOF2

# chmod +x /tmp/visudo-fixer.py
# EDITOR=/tmp/visudo-fixer.py visudo
# exit
# EOF
# 	) | chroot_run bash

# 	(cat << EOF
# import sys
# import os
# import stat

# with open('/tmp/visudo-fixer.py', 'w') as f:
# 	f.write('''#! /usr/bin/env python3
# import sys

# TO_REPLACE   = '\n# %wheel ALL=(ALL:ALL) ALL\n'
# REPLACE_WITH = '\n%wheel ALL=(ALL:ALL) ALL\n'

# visudo_file = sys.argv[1]
# with open(visudo_file, 'r') as f:
# 	cont = f.read()

# match cont.count(TO_REPLACE):
# 	case 0:
# 		count = cont.count(REPLACE_WITH)
# 		assert count == 1, f'invalid number of occurances of uncommented wheel: {count}'
# 		print('wheel already set up, exiting')
# 		sys.exit()
# 	case 1:
# 		cont = cont.replace(TO_REPLACE, REPLACE_WITH)
# 	case other:
# 		assert False, f'invalid number of occurances of commented wheel: {other}'

# with open(visudo_file, 'w') as f:
# 	f.write(cont)

# ''')

# st = os.stat('/tmp/visudo-fixer.py')
# os.chmod('/tmp/visudo-fixer.py', st.st_mode | stat.S_IEXEC)

# os.system('EDITOR=/tmp/visudo-fixer.py visudo')

# sys.exit()
# EOF
# 	) | chroot_run python3

	chroot_run bash -c "echo -e '\n%wheel ALL=(ALL:ALL) ALL\n' | EDITOR='tee -a' visudo"
	# TODO this is gay but it works

	# u can verify with
	#pkg_install vim
	#chroot_run visudo

	# TODO we could also try using `/etc/sudoers.d` (it's the very last line in the `visudo` file)
}

# main

# let user select boot disk
lsblk
printf ">>>>>> Enter boot disk (example: /dev/sda): \n"
read boot_disk
echo "checking if device exists"
test -b ${boot_disk}
	# `-b` is for block device

# let user select additional disks for lvm
additional_disks=""
while true; do
	lsblk
	printf ">>>>>> Enter additional disks (example: /dev/sdb) (leave empty to end): \n"
	read disk
	test -z "${disk}" && break
	echo "checking if device exists"
	test -b ${disk}
	additional_disks="${additional_disks} ${disk}"
done

# get password
printf ">>>>>> Enter password: \n"
read user_password

# format boot disk
parted -s ${boot_disk} mklabel gpt

parted -s ${boot_disk} mkpart primary fat32 0% 512MiB
parted -s ${boot_disk} set 1 esp on

parted -s ${boot_disk} mkpart primary ext4 512MiB 100%
parted -s ${boot_disk} set 2 lvm on

# format other disks
for disk in ${additional_disks}; do
	parted -s ${disk} mklabel gpt
	parted -s ${disk} mkpart primary ext4 0% 100%
	parted -s ${disk} set 1 lvm on
done

boot_partition=${boot_disk}1

# write all LVM parts into variable
lvm_partitions=${boot_disk}2
for disk in ${additional_disks}; do
	lvm_partitions="${lvm_partitions} ${disk}1"
done

# activate
for part in ${lvm_partitions}; do
	pvcreate ${part}
done

# check if everything is OK
pvs

vgcreate myVolGr ${lvm_partitions}

# check
vgs

# activate the volume group (wtf does this event do anything?)
# this might be useless
vgchange -a y myVolGr

# create logical volume
lvcreate --yes -l 100%FREE myVolGr -n myRootVol

# activate the volume group (wtf does this event do anything?)
vgchange -a y myVolGr

# check
lvs

# format
mkfs.fat -F32 ${boot_partition}
mkfs.ext4 -F /dev/mapper/myVolGr-myRootVol
	# `-F` so that there are no confirmation prompts from the user

mount /dev/mapper/myVolGr-myRootVol /mnt

mkdir -p /mnt/boot/efi
mount ${boot_partition} /mnt/boot/efi

mkdir /mnt/etc

genfstab -U -p /mnt >> /mnt/etc/fstab
# u can also double-check the file just in case

pacstrap /mnt base

fix_pacman_config

# pkg_install linux-zen linux-zen-headers linux-firmware micro base-devel networkmanager dialog lvm2
# chroot_run systemctl enable NetworkManager
# # also install some wifi tools
# pkg_install wpa_supplicant wireless_tools netctl

# add_lvm2_hook_to_mkinitcpio
# chroot_run mkinitcpio -p linux-zen

chroot_run echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
chroot_run locale-gen

chroot_run echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo "root:${user_password}" | chroot_run chpasswd

chroot_run useradd -m -g users -G wheel me
echo "me:${user_password}" | chroot_run chpasswd
	# TODO this fails with error `user not known to the underlying authentication module`

config_visudo

set_up_aur_helper

aur_install pirate-get-git # torrent browser

chroot_run ln -sf /usr/share/zoneinfo/Europe/Sofia /etc/localtime

chroot_run hwclock --systohc

chroot_run echo 'navi' > /etc/hostname
# TODO don't hardcode the hostname

chroot_run echo '127.0.0.1   localhost' > /etc/hosts
chroot_run echo '::1 localhost' >> /etc/hosts
chroot_run echo '127.0.1.1   navi.localdomain    navi' >> /etc/hosts
# use static instead of 127.0.0.1

chroot_run pacman --noconfirm -S grub efibootmgr dosfstools os-prober mtools openssh
# os-prober -> if multiple OS-es

# seems like all of this is needed only if u use encryption
	#micro /etc/default/grub
	# change GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
	#
	# to GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=/dev/sda2:myVolGr:allow-discards"
	# to GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=/dev/sdb2:myVolGr:allow-discards"
	#
	# uncomment "#GRUB_ENABLE_CRYPTODISK=y"

# install grub
chroot_run grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=SEXlinux --recheck
chroot_run grub-mkconfig -o /boot/grub/grub.cfg

# display server
pkg_install xorg-server

# `xclip` for `micro`
pkg_install xclip

# terminal
pkg_install xfce4-terminal

# shell
pkg_install fish
# TODo we can probably replace this vvvv with a regular `bash -c`
# (cat << EOF
# chsh -s \$(which fish) me
# exit
# EOF
# ) | chroot_run bash
chroot_run bash -c 'chsh -s $(which fish) me'

# TODO
# # ssh stuff
# pkg_install('openssh') # TODO? check for alternative
# if not (os.path.isfile(os.path.expanduser('~/.ssh/id_rsa')) and os.path.isfile(os.path.expanduser('~/.ssh/id_rsa.pub'))):
# 	term(['ssh-keygen', '-f', os.path.expanduser('~/.ssh/id_rsa'), '-N', ''])
# with open(os.path.expanduser('~/.ssh/config'), 'a') as f:
# 	f.write('\nForwardX11 yes\n')

# git
pkg_install git
pkg_install git-delta
# https://dandavison.github.io/delta/get-started.html
chroot_run git config --global core.pager delta
chroot_run git config --global interactive.diffFilter delta --color-only
chroot_run git config --global delta.navigate true
chroot_run git config --global merge.conflictstyle diff3
chroot_run git config --global diff.colorMoved default

# video drivers
pkg_install lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader
	# AMD
pkg_install lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader
	# intel

# wine
pkg_install wine-staging giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader

# ok version of java since some apps may require java (ewwww)
pkg_install jre11-openjdk

# TODO
    # # unify theme # we could also install adwaita-qt and adwaita-qt6
    #     # themes can be found in `/usr/share/themes` (or at lean on ubuntu)
    #     # docs on xsettings `https://wiki.archlinux.org/title/Xsettingsd`
    # #aur_install('adwaita-qt', 'adwaita-qt6')
    # pkg_install('adwaita-qt5', 'adwaita-qt6')
    # pkg_install('lxappearance-gtk3') # GTK theme control panel
    # pkg_install('qt5ct', 'qt6ct') # qt theme control panel
    # with tempfile.NamedTemporaryFile('w', delete=False) as f:
    #     f.write('GTK_THEME=Adwaita-dark\n')
    #     f.write('QT_QPA_PLATFORMTHEME=qt5ct\n')
    #     f.write('MANGOHUD=1\n')
    #     f.write('EDITOR=micro\n')
    #     # f.write('TERMINAL=wezterm\n')
    #     f.write('BROWSER=librewolf\n')
    #     f.write('\n')
    #     # f.write('# linux-xanmod variables\n')
    #     # f.write('_microarchitecture=15 # zen3\n')
    #     # f.write('use_numa=n # n==I don\'t have multiple processors\n')
    #     # f.write('#use_tracers=n # n==limits debugging and analysis of the kernel\n')
    #     # f.write('#_makenconfig=y # tweak kernel options prior to a build via nconfig\n')
    #     f.write('\n')
    #     name = f.name
    # sudo_replace_file(ENVIRONMENT_PATH, name)

    # # dark theme
    # pkg_install('gnome-themes-extra')
    # aur_install('paper-icon-theme')

# terminal utilities
pkg_install sysstat # utilities for system stats
#aur_install bootiso # safer dd alternative
pkg_install fd # find alternative
pkg_install bat # cat alternative
#pkg_install bottom # system monitor
pkg_install tldr # man alternative
pkg_install duf # better du
#pkg_install lsd # better ls
pkg_install poppler # pdf combiner
pkg_install pdftk bcprov java-commons-lang # pdf cutter
aur_install pirate-get-git # torrent browser
pkg_install yt-dlp # video downloader
pkg_install htop # system monitor
#pkg_install w3m # web browser
#aur_install minq-xvideos-git # xvideos browser
#aur_install minq-nhentai-git python-minq-caching-thing-git # nhentai browser
pkg_install trash-cli # trash manager
#pkg_install streamlink # enables watching streams (examples: yt, twitch)
aur_install ani-cli-git # anime watcher

# DE
pkg_install i3
aur_install xkblayout-state-git # keyboard language switcher
pkg_install python-psutil # needed to determine weather laptop or not
pkg_install python-i3ipc
pkg_install dex # autostart
pkg_install network-manager-applet
pkg_install rofi # menu
pkg_install spectacle # screenshooter
pkg_install mate-polkit # polkit

# additional programs
aur_install mangohud-common mangohud lib32-mangohud # gayming overlay
#aur_install freezer-appimage # music # commented out due to slow download
aur_install nuclear-player-bin # music
aur_install mcomix-git # .cbr file reader (manga) (Junji Ito)
pkg_install gnome-disk-utility
pkg_install baobab # disk usage anal
pkg_install gparted
#pkg_install ark # archive manager
#pkg_install transmission-gtk # torrent
	# torrent client # qbittorrent causes PC to lag, also has a weird bug where it refuses to download torrents
pkg_install tigervnc # vnc
pkg_install ksysguard # task manager
pkg_install songrec # find a song by sample
aur_install vscodium-bin # IDE
aur_install rustdesk-bin # remote desktop
pkg_install mpv # video player
pkg_install nomacs # image viewer
pkg_install firefox # browser

# file manager
pkg_install thunar thunar-archive-plugin gvfs
#caja caja-open-terminal

pkg_install steam
# TODO
    # sudo_replace_string('/usr/share/applications/steam.desktop',
    #     '\nExec=/usr/bin/steam-runtime %U\n',
    #     '\nExec=/usr/bin/steam-runtime -silent -nochatui -nofriendsui %U\n')
pkg_install lib32-libappindicator-gtk2 # makes it so that the taskbar menu follows the system theme; does not always work

pkg_install discord
# TODO
    # sudo_replace_string('/usr/share/applications/discord.desktop',
    #     '\nExec=/usr/bin/discord\n',
    #     '\nExec=/usr/bin/discord --disable-smooth-scrolling\n')

pkg_install syncthing
# TODO
    # if not LAPTOP:
    #     service_start_and_enable(f'syncthing@{USERNAME}')

# power manager
# TODO
    # if LAPTOP:
    #     pkg_force_install('tlp')
    #     sudo_replace_string(TLP_CONF_PATH,
    #         '\n#STOP_CHARGE_TRESH_BAT0=80\n',
    #         '\nSTOP_CHARGE_TRESH_BAT0=1\n',)
    #     service_start_and_enable('tlp')

# vmware
# TODO
    # if (not LAPTOP) and INSTALL_VMWARE:
    #     if not os.path.isdir(VMWARE_VMS_PATH):
    #         os.makedirs(VMWARE_VMS_PATH)
    #     if is_btrfs(VMWARE_VMS_PATH):
    #         term(['chattr', '-R', '+C', VMWARE_VMS_PATH])
    #         #term(['chattr', '+C', VMWARE_VMS_PATH])
    #     aur_install('vmware-workstation')
    #     term(['sudo', 'modprobe', '-a', 'vmw_vmci', 'vmmon'])
    #     service_start_and_enable('vmware-networks')
    #     if not os.path.isdir(os.path.dirname(VMWARE_PREFERENCES_PATH)):
    #         os.makedirs(os.path.dirname(VMWARE_PREFERENCES_PATH))
    #     if os.path.isfile(VMWARE_PREFERENCES_PATH): mode = 'w'
    #     else: mode = 'a'
    #     with open(VMWARE_PREFERENCES_PATH, mode) as f: # TODO check if exists first
    #         f.write('\nmks.gl.allowBlacklistedDrivers = "TRUE"\n')


# login manager
pkg_install lightdm lightdm-gtk-greeter
# unneeded? create group # sudo groupadd -r autologin
# unneeded? add to autologin # term(['sudo', 'gpasswd', '-a', USERNAME, 'autologin'])
chroot_run sed -i -z 's%\n#autologin-user=\n%\nautologin-user=me\n%' /etc/lightdm/lightdm.conf
	# TODO username is hardcoded
chroot_run systemctl enable lightdm

# boot time
chroot_run sed -i -z 's%\nGRUB_TIMEOUT=5\n%\nGRUB_TIMEOUT=1\n%' /etc/default/grub
chroot_run grub-mkconfig -o /boot/grub/grub.cfg
# TODO make `quiet` into `noquiet`
    # sudo_replace_string(GRUB_CONF_PATH,# TODO fix if not the first item
    #     '\nGRUB_CMDLINE_LINUX_DEFAULT="quiet ',
    #     '\nGRUB_CMDLINE_LINUX_DEFAULT="noquiet ')
    # term(['sudo', 'update-grub'])

# final touches
sync
echo 'Please run `umount -a` or `umount /mnt/boot/efi && umount /mnt`'
