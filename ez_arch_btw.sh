#!/bin/bash

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Load configuration
source ./scripts/common.sh

# Load install functions
source ./scripts/install.sh

# Verify system is booted into UEFI mode
check_uefi 

# Install packages nessecary for the script
install_packages install_pkgs.conf

# Get user input
set_hostname
set_password "ROOT_PWD" "user: ROOT"
set_username
set_password "USER_PWD" "user: ${ARCH_USERNAME}"
set_timezone
set_language
set_user_shell
set_password "LUKS_PWD" "the luks pwd"

# Set configuration
set_disk

# Wipe disk
wipe_disk

# Configure file system
conf_filesystem

# Install Arch btw..
info_msg "Installing Arch btw.."
info_msg "Configuration:"

# Use the captured inputs for other operations
info_msg "Disk: $DISK"
info_msg "Hostname: $ARCH_HOSTNAME"
info_msg "Timezone: $TIMEZONE"
info_msg "Language: $LANGUAGE" 
info_msg "Username: $ARCH_USERNAME"
info_msg "User shell: $USER_SHELL"
info_msg "Volume group: $VGROUP"
info_msg "Logic Volume: $LVM_NAME"
info_msg "Swap size: ${SWAPGB}B"
info_msg "Root size: ${ROOTGB}B"
info_msg "Home size: ${HOMEGB}B"

# Pacstrap and arch-chroot installations/configurations
install_arch_btw
