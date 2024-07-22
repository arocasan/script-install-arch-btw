# Load common functions
source ./scripts/common.sh

echo "yoyoyo"

# Install arch btw...
function install_arch_btw() {

  PACKAGE_FILE="${PACKAGE_DIR}/pacstrap_arch_btw.conf"
  PACKAGES$(tr '\n' ''$PACKAGE_FILE)

  genfstab -U -p /mnt >> /mnt/etc/fstab

  pacstrap -K /mnt $PACKAGES

  arch-chroot /mnt /bin/bash <<'EOF'
  install_packages pacstrap_arch_btw.conf 
  
EOF


}
