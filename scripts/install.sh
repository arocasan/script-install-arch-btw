# Load common functions
source ./scripts/common.sh

echo "yoyoyo"

# Install arch btw...
function install_arch_btw() {
pacstrap -K /mnt base base-devel linux linux-firmware
    genfstab -U -p /mnt >> /mnt/etc/fstab
    arch-chroot /mnt /bin/bash <<EOF
    pacman -Syu --noconfirm btrfs-progs neovim lvm2 grub efibootmgr dosfstools mtools os-prober networkmanager openssh sudo intel-ucode xorg xorg-server gnome gnome-tweaks gdm nvidia nvidia-utils
    systemctl enable NetworkManager
    systemctl enable sshd
    systemctl enable gdm
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    echo "$LANGUAGE" > /etc/locale.gen
    locale-gen
    echo "LANG=$LANGUAGE" > /etc/locale.conf
    echo "$HOSTNAME" > /etc/hostname
    (echo "$PASSWORD"; echo "$PASSWORD") | passwd
    useradd -m -G wheel -s $USER_SHELL $USERNAME
    (echo "$PASSWORD"; echo "$PASSWORD") | passwd $USERNAME
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
EOF
}
