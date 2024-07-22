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
show_logo
check_uefi 

# Install packages nessecary for the script
show_logo
install_packages ez_arch_btw.conf

# Get user input
show_logo
set_hostname
set_username
set_timezone
set_language
set_user_shell
set_password "ARCH_USER" "the user"
set_password "LUKS_PWD" "the luks pwd"

# Set configuration
show_logo
set_disk


# Wipe disk
show_logo
wipe_disk

# Configure file system
conf_filesystem

# Install Arch btw..
install_arch_btw

# Use the captured inputs for other operations
echo -e "\033[32mDisk: $DISK\033[0m"
echo -e "\033[32mHostname: $ARCH_HOSTNAME\033[0m"
echo -e "\033[32mTimezone: $TIMEZONE\033[0m"
echo -e "\033[32mLanguage: $LANGUAGE\033[0m"
echo -e "\033[32mUsername: $ARCH_USERNAME\033[0m"
echo -e "\033[32mUser shell: $USER_SHELL\033[0m"

trap self_remove EXIT
