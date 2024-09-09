#!/bin/bash
# Define the log file
LOGFILE="~/archbtw.log"

# Redirect stdout and stderr to both the terminal and the log file
exec > >(tee -a "$LOGFILE") 2>&1
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

## Get user input
get_user_inputs

# Set configuration
set_disk

# Wipe disk
wipe_disk

# Configure file system
conf_filesystem

# Install Arch btw..
info_msg "Installing Arch btw.."

# Pacstrap and arch-chroot installations/configurations
install_arch_btw

# Delete dir
self_remove
