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

# Set configuration
show_logo
get_disk
echo $DISK

