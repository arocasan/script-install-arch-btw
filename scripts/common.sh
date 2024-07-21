#!/bin/bash

# Function to install necessary packages from a specified file in the packages directory
install_packages() {
    local package_file="packages/$1"

    if [[ ! -f $package_file ]]; then
        echo "Package file $package_file does not exist."
        exit 1
    fi

    while IFS= read -r package; do
        if ! command -v "$package" &> /dev/null; then
            echo "Installing $package..."
            pacman -Sy --needed --noconfirm "$package"
        else
            echo "$package is already installed"
        fi
    done < "$package_file"
}

# Function to display an ASCII logo
show_logo(){
echo "Placholder logo"
}

# Function to verify UEFI mode
check_uefi() {
    if [ -d /sys/firmware/efi ]; then
        echo "System is booted in UEFI mode."
    else
        echo "System is not booted in UEFI mode."
        exit 1
    fi
}

# Function to get the disk input from the user
function get_disk() {
    while true; do
        echo "Available disks:"
        disks=($(lsblk -d -o NAME,SIZE,MODEL | grep -v 'loop\|ram' | awk '{print $1}'))
        models=($(lsblk -d -o NAME,SIZE,MODEL | grep -v 'loop\|ram' | awk '{print $3}'))
        
        for i in "${!disks[@]}"; do
            echo "$((i+1)). ${disks[$i]} (${models[$i]})"
        done

        echo -n "Enter the number corresponding to your disk choice: "
        read choice

        if [[ ! $choice =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#disks[@]})); then
            error_feedback "Invalid choice. Please enter a number between 1 and ${#disks[@]}."
            continue
        fi

        selected_disk="/dev/${disks[$((choice-1))]}"
        
        echo "You have selected: $selected_disk. Is this correct? (yes/no)"
        read confirmation

        if [[ $confirmation == "yes" ]]; then
            declare -g DISK=$selected_disk
            break
        else
            echo "Please select again."
        fi
    done
}
