#!/bin/bash
# EXPERIMENTAL 
# Demencia OS Installer GENTOO EDITION  by hhk02

network_device=""
disk=""
efi_partition=""
root_partition=""
timezone=""
selection="1"
hostname="DemenciaOS"
if [[ $EUID = 0 ]]; then
	echo "Welcome to the Gentoo Installer by hhk02 THIS IT'S A EXPERIMENTAL BUILD SO I'AM NOT RESPONSABLE A DATA LOSE!"
	echo "Changing root password"
	passwd
	echo "Showing network devices"
	ip addr
	echo "Write your network device for enable: "
	read network_device
	if [ -z $network_device ]; then
		echo "Write your network device for enable: "
		read network_device
	else
		net-setup $network_device
		dhcpcd $network_device
		ping -t 3 www.google.com
	fi
	
	echo "Write your disk device ex: /dev/sda"
	read disk
	if [ -z $disk ]; then
		echo "Write your disk device ex: /dev/sda"
		read disk
	else
		fdisk $disk
		echo "EFI Partiiton ex /dev/sda1 :"
		read efi_partition
		if [ -z $efi_partition ]; then
			echo "EFI Partiiton ex /dev/sda1 :"
			read efi_partition
		else
			echo "Root partiiton ex /dev/sda2:"
			read root_partition
		fi
	fi
	echo "Erasing and creating partition: EFI Partition"
	mkfs.vfat -F 32 $efi_partition
	echo "Erasing and creating partition: Root partition"
	mkfs.ext4 $root_partition
	clear
	echo "Creating /mnt/gentoo!"
	mkdir --parents /mnt/gentoo
	echo "Mounting root partition!"
	mount $root_partition /mnt/gentoo
	chmod 1777 /mnt/gentoo/tmp
	cd /mnt/gentoo
	echo "Installing Gentoo with SystemD PD: He ahi la importancia de SystemD :-)"
	wget https://gentoo.osuosl.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd/stage3-amd64-desktop-systemd-20230129T164658Z.tar.xz
	echo "Extracting"
	tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
	echo "# Configuraciones del compilador a aplicar en cualquier lenguaje\n
	COMMON_CFLAGS="-march=native -O2 -pipe"\n
	# Use los mismos valores en ambas variables\n
	CFLAGS="${COMMON_FLAGS}"\n
	CXXFLAGS="${CFLAGS}""
	echo "MAKEOPTS="-j2""
	nano -w /mnt/gentoo/etc/portage/make.conf
	echo "Select mirror list"
	mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
	mkdir --parents /mnt/gentoo/etc/portage/repos.conf
	echo "Copying default repository configuration!"
	cp -v /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
	cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
	mount --types proc /proc /mnt/gentoo/proc
	mount --rbind /sys /mnt/gentoo/sys
	mount --make-rslave /mnt/gentoo/sys
	mount --rbind /dev /mnt/gentoo/dev
	mount --make-rslave /mnt/gentoo/dev
	mount --bind /run /mnt/gentoo/run 
	mount --make-slave /mnt/gentoo/run
	echo "Changing into target.."
	chroot /mnt/gentoo /bin/bash -c 'source /etc/profile'
	chroot /mnt/gentoo /bin/bash -c 'export PS1="/mnt/gentoo ${PS1}"'
	chroot /mnt/gentoo /bin/bash -c "'mount $efi_partition /boot'"
	chroot /mnt/gentoo /bin/bash -c 'emerge-webrsync'
	echo "Syncing repos!"
	chroot /mnt/gentoo /bin/bash -c 'emerge --sync'
	chroot /mnt/gentoo /bin/bash -c 'emerge --sync --quiet'
	eselect profile list
	echo "Write you do want: ex: 2"
	read selection
	eselect profile set $selection
	echo "Write the timezone ex : Europe/Madrid"
	read timezone
	chroot /mnt/gentoo /bin/bash -c "'ln -sf ../usr/share/zoneinfo/$timezone /etc/localtime'"
	echo "Done!"
	echo "es_ES.UTF-8 UTF-8"
	echo "es_MX.UTF-8 UTF-8"
	echo "Write in the locale.gen!"
	
	nano -w /mnt/gentoo/etc/locale.gen
	chroot /mnt/gentoo /bin/bash -c 'locale-gen'
	chroot /mnt/gentoo /bin/bash -c 'env-update && source /etc/profile'
	chroot /mnt/gentoo /bin/bash -c 'export PS1="(chroot) ${PS1}'
	echo "Installing kernel...."
	chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/gentoo-kernel-bin'
	chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/linux-headers'
	chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/linux-firmware'
	chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/genkernel'
	chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot genfstab'
	genfstab /mnt/gentoo > /mnt/gentoo/etc/fstab
	chroot /mnt/gentoo /bin/bash -c 'genkernel all'
	chroot /mnt/gentoo /bin/bash -c 'ls /boot/vmlinu* /boot/initramfs*'
	echo "Cleaning..."
	chroot /mnt/gentoo /bin/bash -c 'emerge --depclean'
	echo "Set the hostname:" 
	read hostname
	chroot /mnt/gentoo /bin/bash -c "'hostnamectl hostname $hostname'"
	chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot net-misc/dhcpcd'
	chroot /mnt/gentoo /bin/bash -c 'systemctl enable --now dhcpcd'
	echo "Creating hosts"
	chroot /mnt/gentoo /bin/bash -c 'nano -w /etc/hosts'
	chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-apps/pcmciautils'
	chroot /mnt/gentoo /bin/bash -c 'passwd'
	chroot /mnt/gentoo /bin/bash -c 'systemd-firstboot --prompt --setup-machine-id'
	chroot /mnt/gentoo /bin/bash -c 'systemctl preset-all'
	echo "Installing Wireless support"
	chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot net-wireless/iw net-wireless/wpa_supplicant'
	echo "Installing GRUB"
	echo 'GRUB_PLATFORMS="efi-64"' >> /mnt/gentoo/etc/portage/make.conf
	chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot --verbose sys-boot/grub'
	chroot /mnt/gentoo /bin/bash -c 'emerge --update --newuse --verbose sys-boot/grub'
	echo "Installing bootloader!"
	chroot /mnt/gentoo /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot'
	chroot /mnt/gentoo /bin/bash -c 'grub-mkconfig -o /boot/grub/grub.cfg'
	systemctl reboot	
else
	echo "You must run this as root!"
fi
