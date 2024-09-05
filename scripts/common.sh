#!/bin/bash
# Load defaults
source ./conf/defaults.conf

 # Remove myself
self_remove() {
  rm -rf ~/script-install-arch-btw
  cd
}

# Function to show progress with bold, italic, and purple text
function info_msg() {
    echo -e "\033[1;3;94m$1\033[0m" 
}

# Function to provide success feedback with  bold, italic, and green text
function success_feedback() {
    echo -e "\n\033[1;3;92m$1\033[0m" 
}

# Function to provide error feedback with bold, italic, and red text
function error_feedback() {
    echo -e "\n\033[1;3;91mError: $1\033[0m"
}

unmount_all_mnt() {
  partprobe
  # Get all mount points starting with /mnt
  MOUNT_POINTS=$(mount | grep ' /mnt' | awk '{print $3}' | sort -r)
  # Loop through each mount point and unmount
  for MOUNT_POINT in $MOUNT_POINTS; do
    info_msg "Unmounting $MOUNT_POINT"
    sudo umount "$MOUNT_POINT"
    if [ $? -eq 0 ]; then
      info_msg "$MOUNT_POINT unmounted successfully"
    else
      error_feedback "Failed to unmount $MOUNT_POINT"
    fi
  done
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
            success_feedback "Hostname will be set to $ARCH_HOSTNAME \n"
            break
        else
            error_feedback "Hostname is required!"
        fi
    done
}

# Function to get git_name input
function set_git_name() {
    while true; do
        info_msg "Enter the git_name [default: $DEFAULT_GIT_NAME]: "
        read -r GIT_NAME
        GIT_NAME=${GIT_NAME:-$DEFAULT_GIT_NAME}
        if [ -n "$GIT_NAME" ]; then
            declare -g GIT_NAME=$GIT_NAME
            success_feedback "git_name will be set to $GIT_NAME \n"
            break
        else
            error_feedback "git_name is required!"
        fi
    done
}
# Function to get git_mail input
function set_git_mail() {
    while true; do
        info_msg "Enter the git_mail [default: $DEFAULT_GIT_MAIL]: "
        read -r GIT_MAIL
        GIT_MAIL=${GIT_MAIL:-$DEFAULT_GIT_MAIL}
        if [ -n "$GIT_MAIL" ]; then
            declare -g GIT_MAIL=$GIT_MAIL
            success_feedback "git_mail will be set to $GIT_MAIL \n"
            break
        else
            error_feedback "git_mail is required!"
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
            success_feedback "Timezone will be set to $TIMEZONE \n"
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
# Function to get locale input
function set_locale() {
    while true; do
        info_msg "Enter the locale (e.g., en_US.UTF-8) [default: $DEFAULT_LOCALE]: "
        read -r LOCALE
        LOCALE=${LOCALE:-$DEFAULT_LOCALE}
        if [ -n "$LOCALE" ]; then
            declare -g LOCALE=$LOCALE
            success_feedback "Locale will be set to $LOCALE"
            break
        else
            error_feedback "Locale is required!"
        fi
    done
}

# Function to get keymap input
function set_keymap() {
    while true; do
        info_msg "Enter the keymap (e.g., us) [default: $DEFAULT_KEYMAP]: "
        read -r KEYMAP
        KEYMAP=${KEYMAP:-$DEFAULT_KEYMAP}
        if [ -n "$KEYMAP" ]; then
            declare -g KEYMAP=$KEYMAP
            success_feedback "keymap will be set to $KEYMAP"
            break
        else
            error_feedback "keymap is required!"
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
        info_msg "Enter the password for $prompt_message: "
        read -s PASSWORD
        echo
        if [ -z "$PASSWORD" ]; then 
            error_feedback "Password is required!"
            continue
        fi

        info_msg "Confirm the password for $prompt_message: "
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
    while true; do

    info_msg "Do you want to wipe the disk $DISK? This action is irreversible. (yes/no)"
    read wipe_confirmation

    if [[ $wipe_confirmation == "yes" ]]; then
        info_msg "Wiping disk $DISK..."
        unmount_all_mnt
        sgdisk --zap-all $DISK
        sgdisk -o $DISK
        info_msg | partprobe
        if [ $? -eq 0 ]; then
            success_feedback "Disk $DISK wiped successfully."
        else
            error_feedback "Failed to wipe the disk $DISK."
            info_msg "Wiping disk $DISK..."
            unmount_all_mnt

            sgdisk --zap-all $DISK
            sgdisk -o $DISK
            info_msg | partprobe
 
        trap self_remove EXIT 
            exit
        fi
        break
    elif [[ $wipe_confirmation == "no" ]]; then

       error_feedback "Disk wipe operation cancelled."
        break
    else
        error_feedback "Invalid response. Please enter 'yes' or 'no'."
    fi
  done
}

# Function to create disk partitions

function create_disk_partitions(){
    
    info_msg "Preparing partitions for $DISK"

    sgdisk -n 1::+2G -t 1:ef02 --change-name=1:'BIOSBOOT' $DISK
    sgdisk -n 2::+4G -t 2:ef00 --change-name=2:'EFIBOOT' $DISK
    sgdisk -n 3::-0  -t 3:8309 --change-name=3:'ROOT' $DISK

    partprobe ${DISK}
    sleep 2
}

function create_subvolumes(){
  info_msg "Creating btrfs subvolumes for $DISK"

  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@var
  btrfs subvolume create /mnt/@tmp
  btrfs subvolume create /mnt/@.snapshots

}

function mount_subvolumes(){
  info_msg "Mounting subvolumes on ${DISK}p3"

  mount -o $SSD_MOUNT_OPT,subvol=@home ${DISK}p3 /mnt/home
  mount -o $SSD_MOUNT_OPT,subvol=@tmp ${DISK}p3 /mnt/tmp
  mount -o $SSD_MOUNT_OPT,subvol=@var ${DISK}p3 /mnt/var
  mount -o $SSD_MOUNT_OPT,subvol=@s.snapshots ${DISK}p3 /mnt/.snapshots

}


function making_dirs(){

info_msg "Making directories" 

mkdir -p /mnt/{home,var,tmp,.snapshots}

mkdir -p /mnt/boot/efi
info_msg "Moving on."
ls /mnt

}




function create_filesystems(){
  info_msg "Creating filesystems for $DISK"

  mkfs.vfat -F32 -n "EFIBOOT" ${DISK}p2 
  mkfs.btrfs -L ROOT ${DISK}p3 -f
  mount -t btrfs ${DISK}p3 /mnt
  
  create_subvolumes

  unmount_all_mnt

  info_msg "Mounting @ subvolume"

  mount -o $SSD_MOUNT_OPT,subvol=@ ${DISK}p3 /mnt
  
  making_dirs
  
  mount_subvolumes

  mount -t vfat -L EFIBOOT /mnt/boot/
 

  success_feedback "Filesystems created for $DISK. Moving on"

}

function makeflags_compression(){
  cpucores=$(grep -c ^processor /proc/cpuinfo)
  info_msg "CPU cores: $cpucores "
  sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$cpucores\"/g" /etc/makepkg.conf
  sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $cpucores -z -)/g" /etc/makepkg.conf
}

# Main function to get all user inputs
function get_user_inputs() {
  while true; do
    # Get user input
    set_hostname
    set_password "ROOT_PWD" "user: ROOT"
    set_username
    set_password "USER_PWD" "user: ${ARCH_USERNAME}"
    set_timezone
    set_locale
    set_keymap
    set_language
    set_user_shell
    
    info_msg "Configuration:"
    # Use the captured inputs for other operations
    info_msg "Disk: $DISK"
    info_msg "Hostname: $ARCH_HOSTNAME"
    info_msg "Timezone: $TIMEZONE"
    info_msg "Locale: $LOCALE"
    info_msg "Keymao: $KEYMAP"
    info_msg "Language: $LANGUAGE" 
    info_msg "Username: $ARCH_USERNAME"
    info_msg "User shell: $USER_SHELL"
    while true; do 
    read -p "Do you accept this configuration? (yes/no): " response
    if [[ "$response" == "yes" ]]; then
        info_msg "Will go on then..btw.."
        return 0
    elif [[ "$response" == "no" ]]; then
      "Restarting configuration..."
      break

    else
        info_msg "Invalid response. Please enter 'yes' or 'no'."
    fi
  done
done

}

function conf_filesystem(){
  create_disk_partitions
  create_filesystems
}
