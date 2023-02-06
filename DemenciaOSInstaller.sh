#!/bin/bash

# Demencia OS Installer by hhk02

# Variables
swapoption=""
disk=""
swapoption=""
efipart=""
rootpart=""
swappart=""
efioption=""
user=""
isSudoer=""
choosekernel=""
usingSwap=false



MakeSwap() {
    mkswap $swappart
    swapon $swappart
    echo "Swap enabled"
}

# Metodo de cambio de idioma del teclado
ChangeKeyboardLanguage() {
    arch-chroot /mnt /bin/bash -c 'dpkg-reconfigure locales'
}
# Metodo de creación de usuario
CreateUser() {
	echo Username: 
    read user
    echo -e "is Sudoer (yes/no)"
    read isSudoer

    if [ $isSudoer -eq "yes" ]; then
    echo Adding to sudo group...
	arch-chroot /mnt /bin/bash -c 'usermod -aG sudo', $user
	echo -e The user $user has added to sudo group sucessfully!
    fi
    if [ $user -eq "" ]; then
	    CreateUser
    fi
    arch-chroot /mnt /bin/bash -c 'useradd -m ', $user
    arch-chroot /mnt /bin/bash -c 'passwd ', $user
    echo User created sucessfully!
}
# Obtener Nala
GetNala() {
	arch-chroot /mnt /bin/bash -c 'curl -O https://gitlab.com/volian/volian-archive/uploads/b20bd8237a9b20f5a82f461ed0704ad4/volian-archive-keyring_0.1.0_all.deb'
	arch-chroot /mnt /bin/bash -c 'curl -O https://gitlab.com/volian/volian-archive/uploads/d6b3a118de5384a0be2462905f7e4301/volian-archive-nala_0.1.0_all.deb'
	if [ -f /mnt/volian-archive*.deb ]; then
		arch-chroot /mnt /bin/bash -c 'apt install ./volian-archive*.deb  -y'
        	arch-chroot /mnt /bin/bash -c 'apt install nala-legacy -y'
        	echo Nala installed sucessfully!
	else
		GetNala
	fi
}

# Instalación de nucleo / kernel para el destino (Instalar kernel para usar el sistema)
InstallKernel() {
	arch-chroot /mnt /bin/bash -c 'apt install wget -y'
	umount -l /mnt
	echo "What kernel you do want (generic/xanmod)?"
	read -p choosekernel
    	echo -e Kernel selected: $choosekernel
	if [ $choosekernel -eq "" ]; then
		InstallKernel
	elif [ $choosekernel -eq "generic" ]; then
		echo "Adding non-free repos..."
		echo 'deb http://deb.debian.org/debian/ bullseye main contrib non-free' > /mnt/etc/apt/sources.list
		echo 'deb-src http://deb.debian.org/debian/ bullseye main contrib non-free' >> /mnt/etc/apt/sources.list
		echo 'deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
		echo 'deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
		arch-chroot /mnt /bin/bash -c 'apt update'
		arch-chroot /mnt /bin/bash -c 'apt install linux-image-amd64 linux-headers-amd64 firmware-linux firmware-linux-nonfree -y'
		arch-chroot /mnt /bin/bash -c 'update-grub'
    	echo Generic kernel installed!
    	elif [ $choosekernel -eq "xanmod" ]; then
		echo "Adding non-free repos..."
		echo 'deb http://deb.debian.org/debian/ bullseye main contrib non-free' > /mnt/etc/apt/sources.list
		echo 'deb-src http://deb.debian.org/debian/ bullseye main contrib non-free' >> /mnt/etc/apt/sources.list
		echo 'deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
		echo 'deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
		echo 'deb http://deb.xanmod.org releases main' | sudo tee /mnt/etc/apt/sources.list.d/xanmod-kernel.list
		arch-chroot /mnt /bin/bash -c 'wget -qO - https://dl.xanmod.org/gpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/xanmod-kernel.gpg add - '
		arch-chroot /mnt /bin/bash -c 'apt update'
		arch-chroot /mnt /bin/bash -c 'apt install firmware-linux firmware-linux-nonfree linux-xanmod-x64v3 -y'
		arch-chroot /mnt /bin/bash -c 'update-grub'
		echo XanMod Kernel Installed!
	fi
}

InstallProcess() {
    echo Installing ....
    unsquashfs -f -d /mnt/ /run/live/medium/live/filesystem.squashfs
    
    if [ $usingSwap -eq false ]; then
	    # Remove this file to fix a issue in the boot (/scripts/lock-block)
	    rm /mnt/etc/initramfs-tools/conf.d/resume
    else
	    MakeSwap
    fi
    apt install arch-install-scripts -y
    # Montar la partición EFI para posteriormente pueda detectar los nucleos y asi generar el GRUB
    arch-chroot /mnt /bin/bash -c 'mount', $efipart, /boot
    InstallKernel
    GetNala
    arch-chroot /mnt /bin/bash -c 'apt install grub-efi arch-install-scripts -y'
    echo Generating fstab file!
    genfstab -U /mnt > /mnt/etc/fstab
    arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot --removable'
    arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot --root-directory=/ --bootloader-id=DemenciaOS'
    arch-chroot /media/target /bin/bash -c 'apt remove live-boot* live-tools  -y && /usr/sbin/update-initramfs.orig.initramfs-tools -c -k all && update-grub'
    CreateUser
    ChangeKeyboardLanguage
    umount -l /mnt
    echo "Installation complete!"
    exit
}
Install() {
    clear
    echo "Warning: make sure the specify the correct disk!"
    lsblk
    echo "Disk :"
    read disk

    if [ $disk -eq "" ]; then
	    Install
    else
	    echo -e Starting fdisk in $disk
	    fdisk $disk
	    echo "You do want use SWAP? (yes/no)"
	    read swapoption
	    if [$swapoption -eq "no"]; then
		    usingSwap=false
	    elif [$swapoption -eq "yes"]; then
		    echo "Specify the swap partition: "
		    read swappart
		    echo -e "Selected partition: ", $swappart
		    usingSwap=true
	    fi
	    echo "Specify the root partition ex: /dev/sda2 "
	    read rootpart
	    if [ $rootpart -eq "" ]; then
		    echo "Root partition : "
		    read rootpart
	    else
	    	echo "Formating partitions!"
		    mkfs.vfat -F 32 $efipart
		    mkfs.ext4 $rootpart
		    clear
		    mount $rootpart /mnt
		    echo "Mounted successfully!"
		    Install
	    fi
    fi
}

echo "======================================================================================"
echo " Welcome to the Demencia OS Installer. What do you want?"
echo "======================================================================================"
echo "1.- Install"
echo "2.- Exit"
echo "> "
read option
if [[ $option -eq 1 ]]; then
	Install
elif [[ $option -eq 2 ]]; then
	exit
fi
