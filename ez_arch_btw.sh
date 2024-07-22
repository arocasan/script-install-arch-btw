#!/bin/bash
function get_password() 

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
get_username
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

 # Remove myself
self_remove() {
  rm -rf ~/ezinstall-arch-btw
}

# Use the captured inputs for other operations
echo -e "\033[32mDisk: $DISK\033[0m"
echo -e "\033[32mHostname: $HOSTNAME\033[0m"
echo -e "\033[32mTimezone: $TIMEZONE\033[0m"
echo -e "\033[32mLanguage: $LANGUAGE\033[0m"
echo -e "\033[32mUsername: $ARCH_USERNAME\033[0m"
echo -e "\033[32mUser shell: $USER_SHELL\033[0m"

self_remove
