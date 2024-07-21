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

# Function to get user inputs
function set_config() {
    echo -n "Enter the disk (e.g., /dev/nvme0n1): "
    read DISK
    if [ -z "$DISK" ]; then error_feedback "Disk is required!"; fi

    echo -n "Enter the hostname: "
    read HOSTNAME
    if [ -z "$HOSTNAME" ]; then error_feedback "Hostname is required!"; fi

    echo -n "Enter the timezone (e.g., Europe/Stockholm): "
    read TIMEZONE
    if [ -z "$TIMEZONE" ]; then error_feedback "Timezone is required!"; fi

    echo -n "Enter the language (e.g., en_US.UTF-8): "
    read LANGUAGE
    if [ -z "$LANGUAGE" ]; then error_feedback "Language is required!"; fi

    echo -n "Enter the username: "
    read USERNAME
    if [ -z "$USERNAME" ]; then error_feedback "Username is required!"; fi

    echo -n "Enter the shell for the user (e.g., /bin/zsh): "
    read USER_SHELL
    if [ -z "$USER_SHELL" ]; then USER_SHELL="/bin/zsh"; fi

    echo -n "Enter the password for the user: "
    read -s PASSWORD
    echo
    if [ -z "$PASSWORD" ]; then error_feedback "Password is required!"; fi
}

