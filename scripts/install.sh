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
    cat /mnt/etc/fstab
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

    echo "Update timezone to ${TIMEZONE}"
    ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

    echo "Update timesyncd.conf"
    sed -i '/^#NTP=/s|^#||' /etc/systemd/timesyncd.conf
    sed -i '/^NTP=/s|=.*|=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org|' /etc/systemd/timesyncd.conf
    sed -i '/^#FallbackNTP=/s|^#||' /etc/systemd/timesyncd.conf
    sed -i '/^FallbackNTP=/s|=.*|=0.pool.ntp.org 1.pool.ntp.org|' /etc/systemd/timesyncd.conf
    echo "timesyncd.conf updated"

    echo "setting locale as ${LOCALE}"
    sed -i '/^#${LOCALE}/s/^#//' /etc/locale.gen
    locale-gen
    echo "locale updated"

    echo "setting keymaps to ${KEYMAP}"
    echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf


    echo "LANG=${LANGUAGE}" > /etc/locale.conf
    echo "${ARCH_HOSTNAME}" > /etc/hostname
    (echo "${ROOT_PWD}"; echo "${ROOT_PWD}") | passwd
    useradd -m -G wheel -s ${USER_SHELL} ${ARCH_USERNAME}
    (echo "${USER_PWD}"; echo "${USER_PWD}") | passwd ${ARCH_USERNAME}
    echo "Configuring sudoers"
    sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
    echo "Temporary setting nopasswd sudoers for wheel"
    sed -i '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /etc/sudoers

EOF
}
 function configure_arch_btw() {
    info_msg "Configuring the system..."
    arch-chroot /mnt /bin/bash <<EOF
    echo "Updating mkinitcpio HOOKS"
    sed -i -e '/^HOOKS=/s/\(.*\)block\([^)]*\)/\1block encrypt\2/' -e '/^HOOKS=/s/\(.*\)filesystems\([^)]*\)/\1lvm2 filesystems\2/' -e '/^HOOKS=/s/\(encrypt \)\1*/\1/' -e '/^HOOKS=/s/\(lvm2 \)\1*/\1/' /etc/mkinitcpio.conf
    echo "mkinitcpio HOOKS Updated"
    
    echo "Adding ${DISK}p3 as cryptdevice"
    sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/s|"$| cryptdevice=UUID=$(blkid -s UUID -o value kid -s UUID -o value ${DISK}p3):${LVM_NAME} root=/dev/mapper/${VGROUP}-root"|' /etc/default/grub
    grep '^HOOKS=' /etc/mkinitcpio.conf
    echo "HOOK updated for ${DISK}p3"

    echo "creating keys and required dir"
    mkdir /secure
    dd if=/dev/random of=/secure/root_keyfile.bin bs=512 count=8
    dd if=/dev/random of=/secure/home_keyfile.bin bs=512 count=8
    chmod 000 /secure/*
    echo "Key creation completed"
    

    echo "Undoing the purpose of encryption"
    dd bs=512 count=4 if=/dev/random of=/crypto_keyfile.bin iflag=fullblock
    chmod 600 /crypto_keyfile.bin
    echo "${LUKS_PWD}" | cryptsetup luksAddKey ${DISK}p3 /crypto_keyfile.bin
    sed -i '/^FILES=(/!b;/\/crypto_keyfile\.bin/!s/)/ \/crypto_keyfile\.bin)/' /etc/mkinitcpio.conf
    echo "Done with the undoing"
    

    echo "Adding keys to partition"
    echo "${LUKS_PWD}" | cryptsetup luksAddKey ${DISK}p3 /secure/root_keyfile.bin
    sed -i '/^FILES=/!b;/\/secure\/root_keyfile\.bin/!s/)/ \/secure\/root_keyfile\.bin)/' /etc/mkinitcpio.conf


    echo "Keys added"
    echo "Generate ramdisks..."
    mkinitcpio -p linux
    echo "Ramdisks completed"

    echo "Installing GRUB"
    grub-install --efi-directory=/boot/efi
    echo "Generate GRUB config"
    grub-mkconfig -o /boot/grub/grub.cfg
    grub-mkconfig -o /boot/efi/EFI/${VGROUP}/grub.cfg
    
    echo "Just checking lsblk"
    lsblk
    pacman -Syu
    echo "atempt to install yay"
    su - ${ARCH_USERNAME} 
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
EOF

arch-chroot /mnt /bin/bash <<EOF

    echo "Reverting nopasswd for wheels"
    sed -i '/^ %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^/# /' /etc/sudoers



EOF
    success_feedback "System configured successfully."
    lsblk
}

function aroca_conf() {
    while true; do
        echo "Do you want to install AROCA configurations? (yes/no)"
        read -r response
        if [[ $response == "yes" ]]; then
          cp /conf/50-zsa.rules /mnt/etc/udev/rules.d/
          cp /conf/arch-btw.png /mnt/etc/boot





            arch-chroot /mnt /bin/bash <<EOF
                echo "Configuring GDM for automatic login"
                if grep -q '^\[daemon\]' /etc/gdm/custom.conf; then
                    sed -i '/^\[daemon\]/a\AutomaticLogin=${ARCH_USERNAME}\nAutomaticLoginEnable=True\nTimedLoginEnable=true\nTimedLogin=${ARCH_USERNAME}\nTimedLoginDelay=1' /etc/gdm/custom.conf
                else
                    echo -e "\n[daemon]\nAutomaticLogin=${ARCH_USERNAME}\nAutomaticLoginEnable=True\nTimedLoginEnable=true\nTimedLogin=${ARCH_USERNAME}\nTimedLoginDelay=1" >> /etc/gdm/custom.conf
                fi
        echo "Setting GRUB background"
        sed -i 's|^#GRUB_BACKGROUND=.*|GRUB_BACKGROUND="/boot/arc-btw.png"|' /etc/default/grub

        echo "Setting GRUB resolution"
        sed -i 's|^#GRUB_GFXMODE=.*|GRUB_GFXMODE="${GRUB_RESOLUTION}"|' /etc/default/grub

        echo "Setting GRUB colors"
        sed -i 's|^#GRUB_COLOR_NORMAL=.*|GRUB_COLOR_NORMAL="${GRUB_COLOR_NORMAL}"|' /etc/default/grub
        sed -i 's|^#GRUB_COLOR_HIGHLIGHT=.*|GRUB_COLOR_HIGHLIGHT="${GRUB_COLOR_HIGHLIGHT}"|' /etc/default/grub


    echo "Generate ramdisks..."
    mkinitcpio -p linux
    echo "Ramdisks completed"

    echo "Installing GRUB"
    grub-install --efi-directory=/boot/efi
    echo "Generate GRUB config"
    grub-mkconfig -o /boot/grub/grub.cfg
    grub-mkconfig -o /boot/efi/EFI/${VGROUP}/grub.cfg






        "Configuring ZSA Keymapp"
        su - ${ARCH_USERNAME} 
        sudo groupadd plugdev
        sudo usermod -aG plugdev $USER

EOF
            echo "arcoa configurations installed."
            break
        elif [[ $response == "no" ]]; then
            echo "arcoa configurations not installed."
            break
        else
            echo "Invalid response. Please enter 'yes' or 'no'."
        fi
    done
}

function install_arch_btw(){
  pacstrap_arch_btw
  configure_arch_btw
  aroca_conf
}
