#!/bin/bash
# EXPERIMENTAL 
# Demencia OS Installer GUI GENTOO EDITION  by hhk02

# Variables
#swapoption=""
disk=""
#swapoption=""
efipart=""
rootpart=""
#swappart=""
efioption=""
user=""
password=""
isSudoer=""
#usingSwap=0

InstallWezTerm() {
	echo "Installing WezTerm.. request by: aydropunk"
	arch-chroot /mnt/target /bin/emerge --autounmask=y --autounmask-write x11-terms/wezterm
	arch-chroot /mnt/target /usr/sbin/dispatch-conf
	arch-chroot /mnt/target /bin/emerge --oneshot wezterm
	echo "WezTerm Installed" |
		zenity --progress --pulsate --no-cancel --auto-close --text="Installing"
		zenity --info \
       --title="Demencia OS Installer" \
       --width=250 \
       --text="The terminal WezTerm has been installed!"
}

InstallNVIDIA() {
	echo "Adding NVIDIA repo...."
	sleep 1
	arch-chroot /mnt/target /bin/emerge --oneshot x11-drivers/nvidia-drivers sys-power/switcheroo-control
	sleep 1
	clear
	echo "Installing NVIDIA"
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
ChangeTimeZone() {
	timezone=$(zenity --entry \
		--title="TimeZone" \
		--width=250 \
		--ok-label="OK" \
		--cancel-label="Exit" \
		--text="Insert the timezone ex: Europe/Madrid")
		timeask=$?
		if [ $timeask -eq 0 ]; then
			if [ -z $timezone ]; then
				ChangeTimeZone
			else
				arch-chroot /mnt/target /bin/sh -c "timedatectl set-timezone $timezone"
			fi
		fi
	zenity --info \
		--title="Timezone" \
		--width=250 \
		--ok-label="OK" \
		--cancel-label="Exit" \
		--text="$timezone has been set successfully!"
}


# Metodo de cambio de idioma del teclado
ChangeKeyboardLanguage() {
    arch-chroot /mnt/target /usr/sbin/locale-gen -G es_ES.UTF-8
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
				useradd -R /mnt/target -s /bin/bash -m $user
    				arch-chroot /mnt/target /bin/echo $user:$password | sudo chpasswd
				isSudoer=$(zenity --question \
					--title="Sudoer" \
					--width=250 \
					--ok-label="Yes" \
					--cancel-label="No" \
					--text="It's sudoer?")
				sudoask=$?
				if [[ $sudoask -eq 0 ]]; then
					echo "Adding to sudo group..."
					usermod -R /mnt/target -aG sudo $user
					echo -e "The user $user has added to sudo group sucessfully!"
    				else
					echo "This user it's not sudoer!"
				fi
				zenity --info \
					title="User creation" \
					width=255 \
					text="User created sucessfully!"
				if [ -z $user ]; then
					CreateUser
				fi
			fi
}
# Instalación de nucleo / kernel para el destino (Instalar kernel para usar el sistema)
InstallKernel() {
	##cp -rv /boot/* /mnt/boot
	arch-chroot /mnt/target /bin/emerge --oneshot wget
	arch-chroot /mnt/target /bin/emerge --oneshot gentoo-kernel-bin gentoo-sources linux-firmware linux-headers
    	echo "Generic kernel installed!" |
				zenity --progress \
				--pulsate \
				--no-cancel \
				--auto-close \
				--title="Installing generic kernel.." \
  				--text="Installing...." \
  				--percentage=0

}
InstallProcess() {
	(
	sudo unsquashfs -f -d /mnt/target/ /mnt/cdrom/image.squashfs
	) |
	zenity --progress \
		--pulsate \
		--no-cancel \
		--auto-close \
		--title="Installing Demencia OS" \
  		--text="Installing...." \
  		--percentage=0

    emerge --oneshot arch-install-scripts
    # Montar la partición EFI para posteriormente pueda detectar los nucleos y asi generar el GRUB
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
    arch-chroot /mnt/target /bin/emerge --oneshot grub arch-install-scripts
    echo "Generating fstab file!"
    genfstab -U /mnt/target > /mnt/etc/fstab
    arch-chroot /mnt/target /usr/bin/emerge --oneshot sys-kernel/dracut
    arch-chroot /mnt/target /sbin/grub-install --target=x86_64-efi --efi-directory=/boot --removable
    arch-chroot /mnt/target /sbin/grub-install --target=x86_64-efi --efi-directory=/boot --root-directory=/ --bootloader-id=DemenciaOS
    arch-chroot /mnt/target /sbin/grub-mkconfig -o /boot/grub/grub.cfg
    arch-chroot /mnt/target /usr/sbin/dracut
    CreateUser
    ChangeTimeZone
    ChangeKeyboardLanguage
    umount -l /mnt/target
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
				emerge --oneshot gparted
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
				mount $rootpart /mnt/target 
				sleep 1
				if [ ! -d /mnt/target/boot ]; then
					mkdir /mnt/target/boot 
				fi
				mount $efipart /mnt/target/boot |
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
		emerge --sync
		emerge --oneshot squashfs-tools
		emerge --oneshot zenity
		mkdir -p /mnt/target/
		
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
