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

show_logo(){
echo "Placholder logo"
}
