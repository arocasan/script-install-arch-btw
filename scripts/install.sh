#pacstrap  Load common functions
source ./scripts/common.sh

# Function to read packages from a file
read_packages_from_file() {

    local file_name=$1
    local package_file="${PACKAGES_DIR}/${file_name}"

    if [[ ! -f $package_file ]]; then
        echo "Error: File '$package_file' not found!"
        return 1
    fi

    local packages=$(tr '\n' ' ' < "$package_file")
    echo $packages
}
# Install arch btw...
 function pacstrap_arch_btw() {
   local pacstrap_packages=$(read_packages_from_file "pacstrap_pkgs.conf")
   local chroot_packages=$(read_packages_from_file "chroot_pkgs.conf")

    cp -r $PACKAGES_DIR /mnt

    pacstrap -K /mnt $pacstrap_packages

    genfstab -U -p /mnt >> /mnt/etc/fstab
    info_msg "Trying to pacman -Syu"
    info_msg $chroot_packages
    arch-chroot /mnt /bin/bash <<EOF
    echo "Installing packages" 
    pacman -Syu --noconfirm ${chroot_packages}
    echo "Packages installed"

    echo "Enabling applications"
    systemctl enable NetworkManager
    systemctl enable sshd
    systemctl enable gdm
    echo "Done enabling applications"


    echo "Updating user and system settings, i.e timezone"
    ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
    sed -i '/^#${LANGUAGE}/s^#//' /etc/locale.gen
    locale-gen
    echo "LANG=${LANGUAGE}" > /etc/locale.conf
    echo "${ARCH_HOSTNAME}" > /etc/hostname
    (echo "${ROOT_PWD}"; echo "${ROOT_PWD}") | passwd
    useradd -m -G wheel -s ${USER_SHELL} ${ARCH_USERNAME}
    (echo "${USER_PWD}"; echo "${USER_PWD}") | passwd ${ARCH_USERNAME}
    sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
EOF
}
 function configure_arch_btw() {
    info_msg "Configuring the system..."
    arch-chroot /mnt /bin/bash <<EOF
    echo "Updating mkinitcpio HOOKS"
    sed -i -e '/^HOOKS=/s/\(.*\)block\([^)]*\)/\1block encrypt\2/' -e '/^HOOKS=/s/\(.*\)filesystems\([^)]*\)/\1lvm2 filesystems\2/' -e '/^HOOKS=/s/\(encrypt \)\1*/\1/' -e '/^HOOKS=/s/\(lvm2 \)\1*/\1/' /etc/mkinitcpio.conf
    echo "mkinitcpio HOOKS Updated"
    
    echo "Adding ${DISK}p3 as cryptdevice"
    blkid ${DISK}p3 >> /etc/default/grub
    sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/s|"$| cryptdevice=UUID=$(blkid -s UUID -o value kid -s UUID -o value ${DISK}p3):${LVM_NAME} root=/dev/mapper/${VGROUP}-root"|' /etc/default/grub
    grep '^HOOKS=' /etc/mkinitcpio.conf
    echo "HOOK updated for ${DISK}p3"

    echo "creating keys and required dir"
    mkdir /secure
    dd if=/dev/random of=/secure/root_keyfile.bin bs=512 count=8
    dd if=/dev/random of=/secure/home_keyfile.bin bs=512 count=8
    chmod 000 /secure/*
    echo "Key creation completed"
    

    echo "Adding keys to partition"
    cryptsetup luksAddKey ${DISK}p3 /secure/root_keyfile.bin
    '/^FILES=/s/^FILES=.*/FILES=(\/secure\/root_keyfile.bin)/' /etc/mkinitcpio.conf 
    echo "Keys added"
    echo "Generate ramdisks..."
    mkinitcpio -p linux
    echo "Ramdisks completed"


    grub-install --efi-directory=/boot/efi
    grub-mkconfig -o /boot/grub/grub.cfg
    grub-mkconfig -o /boot/efi/EFI/${VGROUP}/grub.cfg
EOF
    success_feedback "System configured successfully."
}

function install_arch_btw(){
  pacstrap_arch_btw
  configure_arch_btw
}
