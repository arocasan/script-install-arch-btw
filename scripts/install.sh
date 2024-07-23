#pacstrap  Load common functions
source ./scripts/common.sh

echo "yoyoyo"
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
   local pacstrap_packages=$(read_packages_from_file "pacstrap_arch_btw.conf")
   local chroot_packages=$(read_packages_from_file "chroot_arch_btw.conf")

    cp -r $PACKAGES_DIR /mnt

    pacstrap -K /mnt $pacstrap_packages

    genfstab -U -p /mnt >> /mnt/etc/fstab
    arch-chroot /mnt /bin/bash <<EOF
    pacman -Syu --noconfirmation ${packages}
    systemctl enable NetworkManager
    systemctl enable sshd
    systemctl enable gdm


    ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
    echo "${LANGUAGE}" > /etc/locale.gen
    locale-gen
    echo "LANG=${LANGUAGE}" > /etc/locale.conf
    echo "${ARCH_HOSTNAME}" > /etc/hostname
    (echo "${ROOT_PWD}"; echo "${ROOT_PWD}") | passwd
    useradd -m -G wheel -s ${USER_SHELL} ${ARCH_USERNAME}
    (echo "${USER_PWD}"; echo "${USER_PWD}") | passwd ${ARCH_USERNAME}
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
EOF
}
 function configure_arch_btw() {
    show_logo
    info_msg "Configuring the system..."
    arch-chroot /mnt /bin/bash <<EOF
    sed -i 's/^HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
    mkinitcpio -p linux
    grub-install --efi-directory=/boot/efi
    blkid ${DISK}p3 >> /etc/default/grub
    sed -i 's|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX="cryptdevice=UUID=$(blkid -s UUID -o value kid -s UUID -o value ${DISK}p3):luks_lvm root=/dev/mapper/arch-root"|' /etc/default/grub
    mkinitcpio -p linux
    grub-mkconfig -o /boot/grub/grub.cfg
EOF
    success_feedback "System configured successfully."
}



function install_arch_btw(){
  pacstrap_arch_btw
  configure_arch_btw
}
