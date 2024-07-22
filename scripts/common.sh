#!/bin/bash
# Function to show progress with bold, italic, and purple text
function info_prg() {

    echo -e "\033[1;3;35m$1\033[0m" 

}

# Function to provide success feedback with  bold, italic, and green text
function success_feedback() {

    echo -e "\n\033[1;3;92m$1\033[0m" 
}

# Function to provide error feedback with bold, italic, and red text
function error_feedback() {

    echo -e "\n\033[1;3;91mError: $1\033[0m"
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



# Function to get hostname input
function get_hostname() {
    info_prg "Enter the hostname: "
    read HOSTNAME
    if [ -z "$HOSTNAME" ]; then 
        error_feedback "Hostname is required!"
    fi
    declare -g HOSTNAME=$HOSTNAME
}

# Function to get timezone input
function get_timezone() {
    info_prg "Enter the timezone (e.g., Europe/Stockholm): "
    read TIMEZONE
    if [ -z "$TIMEZONE" ]; then 
        error_feedback "Timezone is required!"
    fi
    declare -g TIMEZONE=$TIMEZONE
}

# Function to get language input
function get_language() {
    info_prg "Enter the language (e.g., en_US.UTF-8): "
    read LANGUAGE
    if [ -z "$LANGUAGE" ]; then 
        error_feedback "Language is required!"
    fi
    declare -g LANGUAGE=$LANGUAGE
}

# Function to get username input
function get_username() {
    info_prg "Enter the username: "
    read ARCH_USERNAME
    if [ -z "$ARCH_USERNAME" ]; then 
        error_feedback "Username is required!"
    fi
    declare -g ARCH_USERNAME=$ARCH_USERNAME
}

# Function to get user shell input
function get_user_shell() {
    info_prg "Enter the shell for the user (e.g., /bin/zsh): "
    read USER_SHELL
    if [ -z "$USER_SHELL" ]; then 
        USER_SHELL="/bin/zsh"
    fi
    declare -g USER_SHELL=$USER_SHELL
}

# Function to get password input
function get_password() {
    local password_var=$1
    local prompt_message=$2
    while true; do
        info_prg "Enter the password for $prompt_message: "
        read -s PASSWORD
        echo
        if [ -z "$PASSWORD" ]; then 
            error_feedback "Password is required!"
        fi

        info_prg  "Confirm the password for $prompt_message: "
        read -s PASSWORD_CONFIRM
        echo

        if [ "$PASSWORD" == "$PASSWORD_CONFIRM" ]; then
            declare -g $password_var=$PASSWORD
            break
        else
            error_feedback "Passwords do not match. Please try again."


        fi
    done
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

        info_prg "Enter the number corresponding to your disk choice: "
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
            success_feedback "Arch will be installed on: $selected_disk"
            break
        else
            error_feedback "Please select again."

        fi
    done
}
# Function to wipe disk
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
