#!/bin/bash
# EXPERIMENTAL 
# Demencia OS Installer GUI  by hhk02

# Variables
swapoption=""
disk=""
swapoption=""
efipart=""
rootpart=""
swappart=""
efioption=""
user=""
password=""
isSudoer=""
choosekernel=""
usingSwap=0

InstallWezTerm() {
	echo "Adding WezTerm repo"
	arch-chroot /mnt /bin/curl -LO https://github.com/wez/wezterm/releases/download/20221119-145034-49b9839f/wezterm-20221119-145034-49b9839f.Debian11.deb
	echo "Installing WezTerm.. request by: aydropunk"
	arch-chroot /mnt /bin/apt install ./wezterm-20221119-145034-49b9839f.Debian11.deb
	echo "WezTerm Installed" |
		zenity --progress --pulsate --no-cancel --auto-close --text="Installing"
		zenity --info \
       --title="Demencia OS Installer" \
       --width=250 \
       --text="The terminal WezTerm has been installed!"
}

InstallNVIDIA() {
	echo "Adding NVIDIA repo...."
	arch-chroot /mnt /usr/bin/wget https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/cuda-keyring_1.0-1_all.deb
	sleep 1
	arch-chroot /mnt /bin/apt install ./cuda-keyring_1.0-1_all.deb
	sleep 1
	arch-chroot /mnt /bin/apt update
	sleep 1
	clear
	echo "Installing NVIDIA"
	sleep 1
	arch-chroot /mnt /bin/apt install nvidia-driver switcheroo-control -y
	sleep 1
	echo "If doesn't show errors it's posible the NVIDIA Drivers has been installed...."  |
		zenity --progress \
		--pulsate \
		--no-cancel \
		--auto-close \
		--title="Installing NVIDIA" \
  		--text="Installing" \
  		--percentage=0

		zenity --info \
       --title="Demencia OS Installer" \
       --width=250 \
       --text="NVIDIA Drivers installed!"
}

MakeSwap() {
	(
		mkswap $swappart
    		swapon $swappart
	) |
		zenity --progress \
			--pulsate \
			--no-cancel \
			--auto-close \
  			--title="Make SWAP" \
  			--text="Creating swap...." \
  			--percentage=0 
		zenity --info \
			--title="Swap sucessfull!" \
			--text="Swap Created!" \
			--width=255
		

}

# Metodo de cambio de idioma del teclado
ChangeKeyboardLanguage() {
    arch-chroot /mnt/ /usr/bin/tilix -e dpkg-reconfigure locales
}
# Metodo de creación de usuario
CreateUser() {
	user=$(zenity --entry \
		--title="Write your username" \
		--width=250 \
		--ok-label="OK" \
		--cancel-label="Exit" \
		--text="Insert your username")
	password=$(zenity --password \
		--title="Write your password" \
		--width=250 \
		--ok-label="OK" \
		--cancel-label="Exit" \
		--text="Password: ")
		useransw=$?
			if [[ $useransw -eq 0 ]]; then
				useradd -R /mnt -s /bin/bash -m $user
    			echo $user:$password | chpasswd
				isSudoer=$(zenity --question \
					--title="Sudoer" \
					--width=250 \
					--ok-label="Yes" \
					--cancel-label="No" \
					--text="It's sudoer?")
				sudoask=$?
				if [[ $sudoask -eq 0 ]]; then
					echo "Adding to sudo group..."
					usermod -R /mnt -aG sudo $user
					echo -e "The user $user has added to sudo group sucessfully!"
    				else
					echo "This user it's not sudoer!"
				fi
				zenity --info \
					title="User creation" \
					width=255 \
					text="User created sucessfully!"
				if [[ $user == "" ]]; then
					CreateUser
    			fi
				if [ -z $user ]; then
					CreateUser
				fi
			fi
}
# Obtener Nala
GetNala() {
	echo "50"
	arch-chroot /mnt /bin/curl -O https://gitlab.com/volian/volian-archive/uploads/b20bd8237a9b20f5a82f461ed0704ad4/volian-archive-keyring_0.1.0_all.deb 
	sleep 1
	echo "60"
	arch-chroot /mnt /bin/curl -O https://gitlab.com/volian/volian-archive/uploads/d6b3a118de5384a0be2462905f7e4301/volian-archive-nala_0.1.0_all.deb 
	sleep 1
	echo "70"
	arch-chroot /mnt /bin/apt install ./volian-archive-keyring_0.1.0_all.deb
	arch-chroot /mnt /bin/apt install ./volian-archive-nala_0.1.0_all.deb
	sleep 1
    arch-chroot /mnt /bin/apt update
	arch-chroot /mnt /bin/apt install nala-legacy -y
    sleep 1
	echo "100" |
	zenity --progress \
		--pulsate \
		--no-cancel \
		--auto-close \
		--title="Installing Nala" \
  		--text="Installing...." \
  		--percentage=0
	zenity --info \
		--title="Installed nala" \
		--text="Nala installed sucessfully!" \
		--width=255
	
}

# Instalación de nucleo / kernel para el destino (Instalar kernel para usar el sistema)
InstallKernel() {
	##cp -rv /boot/* /mnt/boot
	arch-chroot /mnt /bin/apt install wget -y
	choosekernel=$(zenity --entry \
		--title="Write the kernel" \
		--width=250 \
		--ok-label="OK" \
		--cancel-label="Exit" \
		--text="WARNING: The XanMod kernel or others kernels maybe causes errors to install NVIDIA video cards, What kernel you do want (generic/xanmod/xanmod-lts) ?"
		)
		kernelask=$?
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
		arch-chroot /mnt /bin/apt update -y
		arch-chroot /mnt /bin/apt install linux-image-amd64 linux-headers-amd64 firmware-linux firmware-linux-nonfree -y
		arch-chroot /mnt /sbin/update-grub
    	echo "Generic kernel installed!" |
				zenity --progress \
				--pulsate \
				--no-cancel \
				--auto-close \
				--title="Installing generic kernel.." \
  				--text="Installing...." \
  				--percentage=0

	fi
    if [[ $choosekernel == "xanmod" ]]; then
	    echo "Adding non-free repos..."
	    echo 'deb http://deb.debian.org/debian/ bullseye main contrib non-free' > /mnt/etc/apt/sources.list
	    echo 'deb-src http://deb.debian.org/debian/ bullseye main contrib non-free' >> /mnt/etc/apt/sources.list
	    echo 'deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
	    echo 'deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
	    echo 'deb http://deb.xanmod.org releases main' | sudo tee /mnt/etc/apt/sources.list.d/xanmod-kernel.list
	    arch-chroot /mnt /bin/wget -qO - https://dl.xanmod.org/gpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/xanmod-kernel.gpg add -
	    arch-chroot /mnt /bin/apt update -y
	    arch-chroot /mnt /bin/apt install firmware-linux firmware-linux-nonfree linux-xanmod-x64v3 -y
	    arch-chroot /mnt /sbin/update-grub
	    echo "XanMod Kernel Installed!" |
				zenity --progress \
				--pulsate \
				--no-cancel \
				--auto-close \
				--title="Installing XanMod kernel.." \
  				--text="Installing...." \
  				--percentage=0
    fi
    if [[ $choosekernel == "xanmod-lts" ]]; then
	    echo "Adding non-free repos..."
	    echo 'deb http://deb.debian.org/debian/ bullseye main contrib non-free' > /mnt/etc/apt/sources.list
	    echo 'deb-src http://deb.debian.org/debian/ bullseye main contrib non-free' >> /mnt/etc/apt/sources.list
	    echo 'deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
	    echo 'deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free' >> /mnt/etc/apt/sources.list
	    echo 'deb http://deb.xanmod.org releases main' | sudo tee /mnt/etc/apt/sources.list.d/xanmod-kernel.list
	    arch-chroot /mnt /bin/wget -qO - https://dl.xanmod.org/gpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/xanmod-kernel.gpg add -
	    arch-chroot /mnt /bin/apt update -y
	    arch-chroot /mnt /bin/apt install firmware-linux firmware-linux-nonfree linux-xanmod-lts -y
	    arch-chroot /mnt /sbin/update-grub
	    echo "XanMod LTS Kernel Installed!" |
				zenity --progress \
				--pulsate \
				--no-cancel \
				--auto-close \
				--title="Installing XanMod LTS kernel.." \
  				--text="Installing...." \
  				--percentage=0
    fi
}
InstallProcess() {
	(
	unsquashfs -f -d /mnt/ /run/live/medium/live/filesystem.squashfs 
	) |
		zenity --progress \
		--pulsate \
		--no-cancel \
		--auto-close \
		--title="Installing Demencia OS" \
  		--text="Installing...."
  		--percentage=0

    if [[ $usingSwap = 0 ]]; then
	    # Remove this file to fix a issue in boot (/scripts/lock-block)
	    rm /mnt/etc/initramfs-tools/conf.d/resume
    else
	    MakeSwap
    fi
    apt install arch-install-scripts -y
    # Montar la partición EFI para posteriormente pueda detectar los nucleos y asi generar el GRUB
    arch-chroot /mnt /bin/apt remove live-boot* live-tools -y
    InstallKernel
    echo "You do want NVIDIA Drivers? (yes/no)"
    nvidiaoption=$(zenity --question \
       --title="Demencia OS Installer" \
       --width=250 \
	   --ok-label="OK" \
	   --cancel-label="NO" \
       --text="You do want NVIDIA Drivers? (yes/no)" \
	   )
	   nvidiaask=$?
    if [[ $nvidiaask -eq 0 ]]; then
    	InstallNVIDIA
	else
		zenity --info \
       --title="Demencia OS Installer" \
       --width=250 \
       --text="NVIDIA Drivers not needed." 
    fi
    GetNala
    InstallWezTerm
    arch-chroot /mnt /bin/apt install grub-efi arch-install-scripts -y
    echo "Generating fstab file!"
    genfstab -U /mnt > /mnt/etc/fstab
    arch-chroot /mnt /sbin/grub-install --target=x86_64-efi --efi-directory=/boot --removable
    arch-chroot /mnt /sbin/grub-install --target=x86_64-efi --efi-directory=/boot --root-directory=/ --bootloader-id=DemenciaOS
    arch-chroot /mnt /sbin/update-grub
    arch-chroot /mnt /sbin/update-initramfs -c -k all
    CreateUser
    ChangeKeyboardLanguage
    umount -l /mnt
    zenity --info \
       --title="Finished" \
       --width=250 \
       --text="Installation complete!"
    exit
}
Install() {
	zenity --info \
		--title="Warning!" \
		--width=250 \
		--text="WARNING! MAKE SURE YOU WRITE THE CORRECT DISK! IF YOU DOESN'T KNOW WHAT DISK USE OPEN A NEW TERMINAL AND WRITE LSBLK!"
	disk=$(zenity --entry \
	--title="Write your disk" \
	--width=250 \
	--ok-label="OK" \
	--cancel-label="Exit" \
	--text="Insert the disk name ex /dev/sda")
	diskansw=$?
	if [ $diskansw -eq 0 ]
	then
		if [-z $disk]
		then
			zenity --error \
       		--title="Error" \
       		--width=250 \
       		--text="You must write <b>a DISK </b> for continue!"
			Install
		else
			if [ ! -f /usr/bin/gparted ]; then
				apt install gparted -y
				gparted
			else
				gparted
			fi
		fi
	else
		zenity --error \
       --title="Closing" \
       --width=250 \
       --text="ABORTED BY USER!"
	fi
	
	zenity --question \
	 --title="Swap Partition" \
	 --width=250 \
	 --text="Do you want Swap?" \
	 --ok-label="Yes" \
	 --cancel-label="No"
	 swapoption=$?
	 if [ $swapoption -eq 1 ]; then
	 	usingSwap=0
	 else
		swapask=$(zenity --entry \
		--title="Write your swap partition" \
		--width=250 \
		--ok-label="OK" \
		--cancel-label="Exit" \
		--text="Insert the swap partition ex /dev/sda3")
		swappart=$?
		if [ $swappart -eq 0]; then
			if [ -z $swapask ]; then
				usingSwap=0
			else
				zenity --info \
				--title="Warning" \
				--width=250 \
				--text="Swap has been created"
				usingSwap=1
			fi
		else
			Install
		fi
	fi

	rootpart=$(zenity --entry \
	--title="Write your root partition" \
	--width=250 \
	--ok-label="OK" \
	--cancel-label="Exit" \
	--text="Insert the root partition ex /dev/sda2")
	rootask=$?


	if [ $rootask -eq 0 ]; then
		if [ -z $rootpart ]; then
			exit
		else
			efipart=$(zenity --entry \
				--title="Write the EFI PARITITON" \
				--width=250 \
				--ok-label="OK" \
				--cancel-label="Exit" \
				--text="Insert EFI partition ex: /dev/sda1")
			efioption=$?
			if [ $efioption -eq 0 ]; then
				mkfs.vfat -F 32 $efipart 
				sleep 1
				mkfs.ext4 $rootpart 
				sleep 1
				mount $rootpart /mnt 
				sleep 1
				if [ ! -d /mnt/boot ]; then
					mkdir /mnt/boot 
				fi
				mount $efipart /mnt/boot |
					zenity --progress \
					--pulsate \
					--no-cancel \
					--auto-close \
					--title="Making partitions" \
  					--text="Making partitions" \
  					--percentage=0

				zenity --info \
					--title="Sucessfull!" \
					--width=250 \
					--text="The partitions has been make filesystem sucessfully"
			fi

			InstallProcess
		fi
	fi
}
if [[ $EUID = 0 ]]; then
	if [ ! -f /usr/bin/zenity ]; then
		apt install zenity -y
	fi
	zenity --question \
       --title="Demencia OS Installer" \
       --width=250 \
	   --ok-label="Install" \
	   --cancel-label="Quit" \
       --text="Welcome to the Demencia OS Installer! Do you want?"
	option=$?
	if [ $option = 0 ]; then
		Install
	else
		exit
	fi
else
	pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY $PWD/DemenciaOSInstallerGUI.sh
fi
