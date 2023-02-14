#!/bin/bash
# EXPERIMENTAL 
# Demencia OS Installer GENTOO EDITION  by hhk02

network_device=""
disk=""
efi_partition=""
root_partition=""
selection="1"
hostname="DemenciaOS"
if [[ $EUID = 0 ]]; then
	echo "Welcome to the Gentoo Installer by hhk02 THIS IT'S A EXPERIMENTAL BUILD SO I'AM NOT RESPONSABLE A DATA LOSE!"
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
	cd /mnt/gentoo
	echo "Installing Gentoo with SystemD PD: He ahi la importancia de SystemD :-)"
	wget http://gentoo.mirrors.ovh.net/gentoo-distfiles/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd/stage3-amd64-desktop-systemd-20230129T164658Z.tar.xz
	echo "Extracting"
	tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
	wget https://github.com/archlinux/arch-install-scripts/archive/master.zip
	unzip master.zip
	cd arch-install-scripts-master/
	make
	make install
	echo "# Configuraciones del compilador a aplicar en cualquier lenguaje\n
	COMMON_CFLAGS="-march=native -O2 -pipe"\n
	# Use los mismos valores en ambas variables\n
	CFLAGS="${COMMON_FLAGS}"\n
	CXXFLAGS="${CFLAGS}""
	echo "MAKEOPTS="-j2""
	nano -w /mnt/gentoo/etc/portage/make.conf
	mkdir --parents /mnt/gentoo/etc/portage/repos.conf
	echo "Copying default repository configuration!"
	cp -v /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
	cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
	echo "Changing into target.."
	mount --types proc /proc /mnt/gentoo/proc
	mount --rbind /sys /mnt/gentoo/sys
	mount --make-rslave /mnt/gentoo/sys
	mount --rbind /dev /mnt/gentoo/dev
	mount --make-rslave /mnt/gentoo/dev
	mount --bind /run /mnt/gentoo/run
	mount --make-slave /mnt/gentoo/run
	
	mount $efi_partition /mnt/gentoo/boot
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge-webrsync'
	echo "Syncing repos!"
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --sync'
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --sync --quiet'
	echo "Installing KDE Plasma with SystemD"
	arch-chroot /mnt/gentoo /bin/bash -c 'eselect profile set 7'
	arch-chroot /mnt/gentoo /bin/bash -c 'ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime'
	echo "Done!"
	echo "es_ES.UTF-8 UTF-8"
	echo "es_MX.UTF-8 UTF-8"
	echo "Write in the locale.gen!"
	
	nano -w /mnt/gentoo/etc/locale.gen
	arch-chroot /mnt/gentoo /bin/bash -c 'locale-gen'
	arch-chroot /mnt/gentoo /bin/bash -c 'env-update && source /etc/profile'
	arch-chroot /mnt/gentoo /bin/bash -c 'export PS1="(chroot) ${PS1}"'
	echo "Installing kernel...."
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/gentoo-kernel-bin'
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/linux-headers'
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/linux-firmware'
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-kernel/genkernel'
	genfstab /mnt/gentoo > /mnt/gentoo/etc/fstab
	arch-chroot /mnt/gentoo /bin/bash -c 'genkernel all'
	ls /mnt/gentoo/boot/vmlinu* /mnt/gentoo/boot/initramfs*
	echo "Cleaning..."
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --depclean'
	echo $hostname > /mnt/gentoo/etc/hostname
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot net-misc/dhcpcd'
	arch-chroot /mnt/gentoo /bin/bash -c 'systemctl enable --now dhcpcd'
	echo "Creating hosts"
	touch /mnt/gentoo/etc/hosts
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot sys-apps/pcmciautils'
	arch-chroot /mnt/gentoo /bin/bash -c 'passwd'
	arch-chroot /mnt/gentoo /bin/bash -c 'systemd-firstboot --prompt --setup-machine-id'
	arch-chroot /mnt/gentoo /bin/bash -c 'systemctl preset-all'
	echo "Installing Wireless support"
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot net-wireless/iw net-wireless/wpa_supplicant'
	echo "Installing GRUB"
	echo 'GRUB_PLATFORMS="efi-64"' >> /mnt/gentoo/etc/portage/make.conf
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --oneshot --verbose sys-boot/grub'
	arch-chroot /mnt/gentoo /bin/bash -c 'emerge --update --newuse --verbose sys-boot/grub'
	echo "Installing bootloader!"
	arch-chroot /mnt/gentoo /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot'
	arch-chroot /mnt/gentoo /bin/bash -c 'grub-mkconfig -o /boot/grub/grub.cfg'
	systemctl reboot	
else
	echo "You must run this as root!"
fi
