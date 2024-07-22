#!/bin/bash

# Load defaults
source ./conf/defaults.conf

# Function to show progress with bold, italic, and purple text
function info_msg() {

    echo -e "\033[94m$1\033[0m" 

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
            info_msg "Installing $package..."
            pacman -Sy --needed --noconfirm "$package"
        else
            info_msg "$package is already installed"
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
function set_hostname() {
    while true; do
        info_msg "Enter the hostname [default: $DEFAULT_HOSTNAME]: "
        read -r ARCH_HOSTNAME
        ARCH_HOSTNAME=${ARCH_HOSTNAME:-$DEFAULT_HOSTNAME}
        if [ -n "$ARCH_HOSTNAME" ]; then
            declare -g ARCH_HOSTNAME=$ARCH_HOSTNAME
            success_feedback "Hostname will be set to $ARCH_HOSTNAME"
            break
        else
            error_feedback "Hostname is required!"
        fi
    done
}

# Function to get timezone input
function set_timezone() {
    while true; do
        info_msg "Enter the timezone (e.g., Europe/Stockholm) [default: $DEFAULT_TIMEZONE]: "
        read -r TIMEZONE
        TIMEZONE=${TIMEZONE:-$DEFAULT_TIMEZONE}
        if [ -n "$TIMEZONE" ]; then
            declare -g TIMEZONE=$TIMEZONE
            success_feedback "Timezone will be set to $TIMEZONE"
            break
        else
            error_feedback "Timezone is required!"
        fi
    done
}

# Function to get language input
function set_language() {
    while true; do
        info_msg "Enter the language (e.g., en_US.UTF-8) [default: $DEFAULT_LANGUAGE]: "
        read -r LANGUAGE
        LANGUAGE=${LANGUAGE:-$DEFAULT_LANGUAGE}
        if [ -n "$LANGUAGE" ]; then
            declare -g LANGUAGE=$LANGUAGE
            success_feedback "Language will be set to $LANGUAGE"
            break
        else
            error_feedback "Language is required!"
        fi
    done
}

# Function to get username input
function set_username() {
    while true; do
        info_msg "Enter the username [default: $DEFAULT_USERNAME]: "
        read -r ARCH_USERNAME
        ARCH_USERNAME=${ARCH_USERNAME:-$DEFAULT_USERNAME}
        if [ -n "$ARCH_USERNAME" ]; then
            declare -g ARCH_USERNAME=$ARCH_USERNAME
            success_feedback "Username will be $ARCH_USERNAME for $ARCH_HOSTNAME"
            break
        else
            error_feedback "Username is required!"
        fi
    done
}

# Function to get user shell input
function set_user_shell() {
    while true; do
        info_msg "Enter the shell for the user (e.g., /bin/zsh) [default: $DEFAULT_SHELL]: "
        read -r USER_SHELL
        USER_SHELL=${USER_SHELL:-$DEFAULT_SHELL}
        if [ -n "$USER_SHELL" ]; then
            declare -g USER_SHELL=$USER_SHELL
            success_feedback "User shell will be $USER_SHELL for $ARCH_USERNAME"
            break
        else
            error_feedback "User shell is required!"
        fi
    done
}

# Reusable function to get password input and set it to a specified variable
function set_password() {
    local password_var=$1
    local prompt_message=$2
    while true; do
        echo "Enter the password for $prompt_message: "
        read -s PASSWORD
        echo
        if [ -z "$PASSWORD" ]; then 
            error_feedback "Password is required!"
            continue
        fi

        echo "Confirm the password for $prompt_message: "
        read -s PASSWORD_CONFIRM
        echo

        if [ "$PASSWORD" == "$PASSWORD_CONFIRM" ]; then
            declare -g $password_var="$PASSWORD"
            success_feedback "Password set successfully for $prompt_message"
            break
        else
            error_feedback "Passwords do not match. Please try again."
        fi
    done
}
 
function set_disk() {
    local disks
    disks=$(lsblk -d -o NAME,SIZE,MODEL | grep -v 'loop\|ram')
    local disk_list=()
    local index=1

    echo "Available disks:"
    while IFS= read -r line; do
        disk_list+=("$line")
        echo "$index. $line"
        ((index++))
    done <<< "$disks"

    while true; do
        echo -n "Enter the number corresponding to the disk (e.g., 1): "
        read -r disk_choice
        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && [ "$disk_choice" -ge 1 ] && [ "$disk_choice" -le "${#disk_list[@]}" ]; then
            DISK=$(echo "${disk_list[$((disk_choice - 1))]}" | awk '{print $1}')
            declare -g DISK=/dev/$DISK
            break
        else
            echo "Error: Invalid choice. Please enter a number between 1 and ${#disk_list[@]}."
        fi
    done
}

# Function to wipe disk
function wipe_disk() {
    info_msg "Do you want to wipe the disk $DISK? This action is irreversible. (yes/no)"
    read wipe_confirmation

    if [[ $wipe_confirmation == "yes" ]]; then
        info_msg "Wiping disk $DISK..."
        umount -A --recursive /mnt
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

# Function to create disk partitions

function create_disk_partitions(){
    
    info_msg "Preparing partitions for $DISK"

    sgdisk -n 1::+2G -t 1:ef00 $DISK
    sgdisk -n 2::+4G -t 2:ef02 $DISK
    sgdisk -n 3::-0  -t 3:8309 $DISK

    partprobe ${DISK}



}

function create_lvm(){
  info_msg "Configuring LVM and encryption for ${DISK}p3"
  modprobe dm-crypt && modprobe dm-mod
  echo "$LUKS_PWD" | cryptsetup luksFormat -v -s 512 -h sha512 ${DISK}p3
  echo "$LUKS_PWD" | cryptsetup open ${DISK}p3

  pvcreate /dev/mapper/$LVM_NAME
  vgcreate $VGROUP /dev/mapper/$LVM_NAME
  lvcreate -n swap -L $SWAPGB $VGROUP
  lvcreate -n root -L $ROOTGB $VGROUP
  lvcreate -n home -L $HOMEGB $VGROUP

}

function create_filesystems(){
  info_msg "Creating filesystems for $DISK"
  umount -a
 yes | mkfs.fat -F32 ${DISK}p1 
 yes | mkfs.ext4 ${DISK}p2
 yes | mkfs.btrfs -L root /dev/mapper/${VGROUP}-root
 yes | mkfs.btrfs -L home /dev/mappper/${VGROUP}-home

  mkswap /dev/mapper/${VGROUP}-swap
  swapon /dev/mapper/${VGROUP}-swap

  success_feedback "Filesystems created for $DISK. Moving on"
}

function mount_filesystems(){
  info_msg "Mounting filesystems"

  mkdir -p /mnt/{home,boot}
  mkdir /mnt/boot/efi

  mount /dev/mapper/${VGROUP}-root /mnt
  mount /dev/mapper/${VGROUP}-home /mnt/home
  mount ${DISK}p2 /mnt/boot
  mount ${DISK}p1 /mnt/boot/efi

  info_msg "Filesystems mounted. Moving on."
  
}

# Main function to get all user inputs
function set_user_inputs() {
    set_disk
    set_hostname
    set_timezone
    set_language
    set_username
    set_user_shell
    set_password "USER_PASSWORD" "the user"
    set_password "ANOTHER_PASSWORD" "another user"

  }

function conf_filesystem(){
  create_disk_partitions
  create_lvm
  create_filesystems
  mount_filesystems
}
