#!/bin/bash

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Load configuration
source ./scripts/common.sh


# Verify system is booted into UEFI mode
show_logo
check_uefi 

# Install packages nessecary for the script
show_logo
install_packages ez_arch_btw.txt

# Get user input
show_logo
get_hostname
get_timezone
get_language
get_user_shell
get_password "ARCH_USER" "the user"
get_password "LUKS_PWD" "the luks pwd"

# Set configuration
show_logo
get_disk


# Wipe disk
show_logo
wipe_disk


