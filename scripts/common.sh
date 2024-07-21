#!/bin/bash
# Function to show progress with bold, italic, and purple text
function info_prg() {
    echo -e "\033[1;3;35m$1\033[0m" | pv -qL 10
}

# Function to provide success feedback with  bold, italic, and green text
function success_feedback() {
    echo -e "\n\033[1;3;92m$1\033[0m" | pv -qL 10
    sleep 2  # Pause to show the message
}

# Function to provide error feedback with bold, italic, and red text
function error_feedback() {
    echo -e "\n\033[1;3;91mError: $1\033[0m" | pv -qL 10
    exit 1
}


# Function to install necessary packages from a specified file in the packages directory
install_packages() {
    local package_file="packages/$1"

    if [[ ! -f $package_file ]]; then
        error_feedback "Package file $package_file does not exist."
        exit 1
    fi

    while IFS= read -r package; do
        if ! command -v "$package" &> /dev/null; then
            info_prg "Installing $package..."
            pacman -Sy --needed --noconfirm "$package"
        else
            info_prg "$package is already installed"
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
        success_feedback "System is booted in UEFI mode."
    else
        error_feedbackr "System is not booted in UEFI mode."
        exit 1
    fi
}

# Function to get the disk input from the user
function get_disk() {
    while true; do
        info_prg "Available disks:"
        disks=($(lsblk -d -o NAME,SIZE,MODEL | grep -v 'loop\|ram' | awk '{print $1}'))
        models=($(lsblk -d -o NAME,SIZE,MODEL | grep -v 'loop\|ram' | awk '{print $3}'))
        
        for i in "${!disks[@]}"; do
            info_prg "$((i+1)). ${disks[$i]} (${models[$i]})"
        done

        info_prg -n "Enter the number corresponding to your disk choice: "
        read choice

        if [[ ! $choice =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#disks[@]})); then
            error_feedback "Invalid choice. Please enter a number between 1 and ${#disks[@]}."
            continue
        fi

        selected_disk="/dev/${disks[$((choice-1))]}"
        
        info_prg "You have selected: $selected_disk. Is this correct? (yes/no)"
        read confirmation

        if [[ $confirmation == "yes" ]]; then
            declare -g DISK=$selected_disk
            break
        else
            error_feedback "Please select again."
        fi
    done
}

function wipe_disk() {
    info_prg "Do you want to wipe the disk $DISK? This action is irreversible. (yes/no)"
    read wipe_confirmation

    if [[ $wipe_confirmation == "yes" ]]; then
        info_prg "Wiping disk $DISK..."
        sgdisk --zap-all $DISK
        if [ $? -eq 0 ]; then
            success_feedback "Disk $DISK wiped successfully."
        else
            error_feedback "Failed to wipe the disk $DISK."
        fi
    else
        error_feedback "Disk wipe operation cancelled."
    fi
}
