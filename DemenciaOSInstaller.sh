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
usingSwap=0

InstallNVIDIA() {
	echo "Adding NVIDIA repo...."
	arch-chroot /mnt /bin/bash -c 'wget https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/cuda-keyring_1.0-1_all.deb'
	arch-chroot /mnt /bin/bash -c 'dpkg -i cuda-keyring_1.0-1_all.deb'
	arch-chroot /mnt /bin/bash -c 'apt update'
	clear
	echo "Installing NVIDIA"
	arch-chroot /mnt /bin/bash -c 'apt install nvidia-driver switcheroo-control -y'
	echo "If doesn't show errors it's posible the NVIDIA Drivers has been installed...."
}

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
	echo "Username:" 
    	read user
    	echo -e "is Sudoer (yes/no)"
    	read isSudoer
	
	useradd -R /mnt -s /bin/bash -m $user
    	passwd -R /mnt $user
	
    	if [ $isSudoer == "yes" ]; then
		echo Adding to sudo group...
		usermod -R /mnt -aG sudo $user
		echo -e "The user $user has added to sudo group sucessfully!"
    	else
		echo "This user it's not sudoer!"
	fi
    	if [[ $user == "" ]]; then
		CreateUser
    	fi
    	
    	echo "User created sucessfully!"
}
# Obtener Nala
GetNala() {
	arch-chroot /mnt /bin/bash -c 'curl -O https://gitlab.com/volian/volian-archive/uploads/b20bd8237a9b20f5a82f461ed0704ad4/volian-archive-keyring_0.1.0_all.deb'
	arch-chroot /mnt /bin/bash -c 'curl -O https://gitlab.com/volian/volian-archive/uploads/d6b3a118de5384a0be2462905f7e4301/volian-archive-nala_0.1.0_all.deb'
	arch-chroot /mnt /bin/bash -c 'apt install ./volian-archive*.deb  -y'
    	arch-chroot /mnt /bin/bash -c 'apt update && apt install nala-legacy -y'
    	echo "Nala installed sucessfully!"
}

# Instalación de nucleo / kernel para el destino (Instalar kernel para usar el sistema)
InstallKernel() {
	##cp -rv /boot/* /mnt/boot
	arch-chroot /mnt /bin/bash -c 'apt install wget -y'
	echo "What kernel you do want (generic/xanmod)? WARNING: The XanMod kernel or others kernels maybe causes errors to install NVIDIA video cards"
	read choosekernel
	echo -e "Kernel selected:" $choosekernel

	if [[ -z $choosekernel ]]; then
		InstallKernel
	fi
	if [[ $choosekernel == "generic" ]]; then
		echo "Adding non-free repos..."
		echo 'deb http://deb.debian.org/debian/ bullseye main contrib non-free' > /mnt/etc/apt/sources.list
		echo 'deb-src http://deb.debian.org/debian/ bullseye main contrib non-free' >> /mnt/etc/apt/sources.list
		echo 'deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
		echo 'deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
		arch-chroot /mnt /bin/bash -c 'apt update -y'
		arch-chroot /mnt /bin/bash -c 'apt install linux-image-amd64 linux-headers-amd64 firmware-linux firmware-linux-nonfree -y'
		echo "You do want NVIDIA Drivers? (yes/no)"
    		read nvidiaoption
    		if [ $nvidiaoption == "yes" ]; then
	    		InstallNVIDIA
    		fi
		arch-chroot /mnt /bin/bash -c 'update-grub'
    		echo "Generic kernel installed!"
	fi
    if [[ $choosekernel == "xanmod" ]]; then
	    echo "Adding non-free repos..."
	    echo 'deb http://deb.debian.org/debian/ bullseye main contrib non-free' > /mnt/etc/apt/sources.list
	    echo 'deb-src http://deb.debian.org/debian/ bullseye main contrib non-free' >> /mnt/etc/apt/sources.list
	    echo 'deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
	    echo 'deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
	    echo 'deb http://deb.xanmod.org releases main' | sudo tee /mnt/etc/apt/sources.list.d/xanmod-kernel.list
	    arch-chroot /mnt /bin/bash -c 'wget -qO - https://dl.xanmod.org/gpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/xanmod-kernel.gpg add -'
	    arch-chroot /mnt /bin/bash -c 'apt update -y'
	    arch-chroot /mnt /bin/bash -c 'apt install firmware-linux firmware-linux-nonfree linux-xanmod-x64v3 -y'
	    arch-chroot /mnt /bin/bash -c 'update-grub'
	    echo "XanMod Kernel Installed!"
    fi
}
InstallProcess() {
    echo "Installing Demencia OS ...."
    unsquashfs -f -d /mnt/ /run/live/medium/live/filesystem.squashfs
    
    if [[ $usingSwap = 0 ]]; then
	    # Remove this file to fix a issue in boot (/scripts/lock-block)
	    rm /mnt/etc/initramfs-tools/conf.d/resume
    else
	    MakeSwap
    fi
    apt install arch-install-scripts -y
    # Montar la partición EFI para posteriormente pueda detectar los nucleos y asi generar el GRUB
    arch-chroot /mnt /bin/bash -c 'apt remove live-boot* live-tools -y'
    GetNala
    arch-chroot /mnt /bin/bash -c 'apt install grub-efi arch-install-scripts -y'
    echo "Generating fstab file!"
    genfstab -U /mnt > /mnt/etc/fstab
    arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot --removable'
    arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot --root-directory=/ --bootloader-id=DemenciaOS'
    arch-chroot /mnt /sbin/update-grub
    arch-chroot /mnt /sbin/update-initramfs -c -k all
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

    if [ -z $disk ]; then
	    Install
    else
	    echo -e "Starting fdisk in" $disk
	    fdisk $disk
	    echo "You do want use SWAP? (yes/no)"
	    read swapoption
	    if [[ $swapoption == "no" ]]; then
		    usingSwap=0
	    elif [[ $swapoption == "yes" ]]; then
		    echo "Specify the swap partition: "
		    read swappart
		    echo -e "Selected partition: " $swappart
		    usingSwap=1
	    fi
	    echo "Specify the root partition ex: /dev/sda2 "
	    read rootpart
	    echo "Specify the EFI partition ex : /dev/sda1 "
	    read efipart
	    if [ -z $rootpart ]; then
		    echo "Root partition : "
		    read rootpart
	    else
		    echo "Formating partitions!"
		    mkfs.vfat -F 32 $efipart
		    mkfs.ext4 $rootpart
		    clear
		    mount $rootpart /mnt
		    if [ -f !/mnt/boot ]; then
		    	mkdir /mnt/boot
		    fi
		    mount $efipart /mnt/boot
		    echo "Mounted successfully!"
		    InstallProcess
	    fi
    fi
}

if [[ $EUID = 0 ]]; then
	echo "======================================================================================"
	echo " Welcome to the Demencia OS Installer. What do you want?"
	echo "======================================================================================"
	echo "1.- Install"
	echo "2.- Exit"
	echo "> "
	read option
	if [[ $option = 1 ]]; then
		Install
	elif [[ $option = 2 ]]; then
		exit
	fi
else
	echo "You need be root to install!"
fi
