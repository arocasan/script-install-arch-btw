#!/bin/bash

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Load configuration
source ./scripts/common.sh

# Display ASCII log
show_logo


# Install packages nessecary for the script
install_packages ez_arch_btw.txt
