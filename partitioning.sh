#!/bin/bash

# Disk partitioning functions for Axis-install

# Disk selection menu
select_disk() {
    local disks=()
    local disk
    
    # Check for SATA/IDE drives
    for disk in /dev/sd[a-z]; do
        [[ -b "$disk" ]] || continue
        disk_size=$(lsblk -d -o SIZE -n "$disk")
        disks+=("$disk" "${disk_size}B")
    done
    
    # Check for NVMe drives
    for disk in /dev/nvme[0-9]n[0-9]; do
        [[ -b "$disk" ]] || continue
        disk_size=$(lsblk -d -o SIZE -n "$disk")
        disks+=("$disk" "${disk_size}B")
    done
    
    # Check for virtual drives (useful in VMs)
    for disk in /dev/vd[a-z]; do
        [[ -b "$disk" ]] || continue
        disk_size=$(lsblk -d -o SIZE -n "$disk")
        disks+=("$disk" "${disk_size}B")
    done
    
    disk=$(dialog --title "Select Disk" \
                 --menu "$AXIS_ART\n\nChoose disk to install Arch Linux:" 20 70 10 \
                 "${disks[@]}" \
                 2>&1 >/dev/tty)
    
    if [[ -n "$disk" ]]; then
        save_config "DISK" "$disk"
        dialog --title "Disk Selected" --msgbox "Disk $disk selected for installation" 6 50
    fi
}

# Partition a disk
partition_disk() {
    load_config
    
    if [[ -z "${CONFIG[DISK]}" ]]; then
        dialog --title "Error" --msgbox "No disk selected. Please select a disk first." 6 50
        return
    fi
    
    local partition_type
    partition_type=${CONFIG[PARTITION_TYPE]}
    
    case $partition_type in
        primary)
            partition_standard "${CONFIG[DISK]}"
            ;;
        encrypted)
            partition_encrypted "${CONFIG[DISK]}"
            ;;
        *)
            dialog --title "Error" --msgbox "Invalid partition type. Please choose primary or encrypted." 6 50
            return
            ;;
    esac
}

# Standard partitioning
partition_standard() {
    local disk="$1"
    local fs_type="${CONFIG[FILESYSTEM]}"
    
    dialog --title "Partitioning Disk" --msgbox "$AXIS_ART\n\nPartitioning disk $disk for standard installation" 8 50
    
    # Create partitions
    parted -s "$disk" -- mklabel gpt
    parted -s "$disk" -- mkpart primary fat32 1MiB 1GiB
    parted -s "$disk" -- mkpart primary 1GiB 100%
    parted -s "$disk" -- set 1 esp on
    
    # Format partitions
    if [[ "$disk" =~ nvme ]]; then
        mkfs.fat -F32 "${disk}p1"
        
        # Format root partition with selected filesystem
        case $fs_type in
            ext4)
                mkfs.ext4 -F "${disk}p2"
                ;;
            btrfs)
                mkfs.btrfs -f "${disk}p2"
                ;;
        esac
        
        ROOT_PARTITION="${disk}p2"
        EFI_PARTITION="${disk}p1"
    else
        mkfs.fat -F32 "${disk}1"
        
        # Format root partition with selected filesystem
        case $fs_type in
            ext4)
                mkfs.ext4 -F "${disk}2"
                ;;
            btrfs)
                mkfs.btrfs -f "${disk}2"
                ;;
        esac
        
        ROOT_PARTITION="${disk}2"
        EFI_PARTITION="${disk}1"
    fi
}

# Encrypted partitioning
partition_encrypted() {
    local disk="$1"
    local crypt_name="cryptroot"
    local fs_type="${CONFIG[FILESYSTEM]}"
    
    dialog --title "Partitioning Disk" --msgbox "$AXIS_ART\n\nPartitioning disk $disk for encrypted installation" 8 50
    
    # Create partitions
    parted -s "$disk" -- mklabel gpt
    parted -s "$disk" -- mkpart primary fat32 1MiB 1GiB
    parted -s "$disk" -- mkpart primary 1GiB 100%
    parted -s "$disk" -- set 1 esp on
    
    # Format boot partition and set up encryption
    if [[ "$disk" =~ nvme ]]; then
        mkfs.fat -F32 "${disk}p1"
        EFI_PARTITION="${disk}p1"
        
        # Set up encryption
        echo -n "${CONFIG[ENCRYPTION_PASSWORD]}" | cryptsetup luksFormat --batch-mode --type luks2 "${disk}p2"
        echo -n "${CONFIG[ENCRYPTION_PASSWORD]}" | cryptsetup open "${disk}p2" "$crypt_name"
    else
        mkfs.fat -F32 "${disk}1"
        EFI_PARTITION="${disk}1"
        
        # Set up encryption
        echo -n "${CONFIG[ENCRYPTION_PASSWORD]}" | cryptsetup luksFormat --batch-mode --type luks2 "${disk}2"
        echo -n "${CONFIG[ENCRYPTION_PASSWORD]}" | cryptsetup open "${disk}2" "$crypt_name"
    fi
    
    # Format encrypted partition with selected filesystem
    case $fs_type in
        ext4)
            mkfs.ext4 -F "/dev/mapper/$crypt_name"
            ;;
        btrfs)
            mkfs.btrfs -f "/dev/mapper/$crypt_name"
            ;;
    esac
    
    ROOT_PARTITION="/dev/mapper/$crypt_name"
}

# Select partition type
select_partition_type() {
    local choice
    choice=$(dialog --title "Partition Type" \
                   --menu "$AXIS_ART\n\nSelect partition type:" 15 60 5 \
                   "primary" "Standard partition" \
                   "encrypted" "Encrypted partition (LUKS)" \
                   2>&1 >/dev/tty)
    
    if [[ -n "$choice" ]]; then
        save_config "PARTITION_TYPE" "$choice"
        
        if [[ "$choice" == "encrypted" ]]; then
            set_encryption_password
        fi
    fi
}

# Set encryption password
set_encryption_password() {
    local password password_confirm
    
    while true; do
        password=$(dialog --title "Encryption Password" \
                         --passwordbox "$AXIS_ART\n\nEnter encryption password:" 15 60 \
                         2>&1 >/dev/tty)
        
        [[ -z "$password" ]] && return
        
        password_confirm=$(dialog --title "Confirm Encryption Password" \
                                 --passwordbox "$AXIS_ART\n\nConfirm encryption password:" 15 60 \
                                 2>&1 >/dev/tty)
        
        if [[ "$password" == "$password_confirm" ]]; then
            save_config "ENCRYPTION_PASSWORD" "$password"
            dialog --title "Success" --msgbox "Encryption password set successfully" 6 50
            break
        else
            dialog --title "Error" --msgbox "Passwords do not match. Please try again." 6 50
        fi
    done
}

# Select filesystem type
select_filesystem() {
    local choice
    choice=$(dialog --title "Filesystem Type" \
                   --menu "$AXIS_ART\n\nSelect root filesystem type:" 15 60 5 \
                   "ext4" "Extended 4 filesystem" \
                   "btrfs" "B-tree filesystem" \
                   2>&1 >/dev/tty)
    
    if [[ -n "$choice" ]]; then
        save_config "FILESYSTEM" "$choice"
        dialog --title "Filesystem Selected" --msgbox "Filesystem set to: $choice" 6 50
    fi
}

# Configure swap
config_swap() {
    local swap_size
    swap_size=$(dialog --title "Swap Configuration" \
                      --inputbox "$AXIS_ART\n\nEnter swap size in GB (0 for no swap):" 15 60 \
                      "${CONFIG[SWAP_SIZE]}" \
                      2>&1 >/dev/tty)
    
    if [[ -n "$swap_size" ]] && [[ "$swap_size" =~ ^[0-9]+$ ]]; then
        save_config "SWAP_SIZE" "$swap_size"
        dialog --title "Swap Configured" --msgbox "Swap size set to: ${swap_size}GB" 6 50
    fi
}

# Disk management menu
disk_menu() {
    while true; do
        choice=$(dialog --title "Disk Management" \
                       --menu "$AXIS_ART\n\nDisk Management Options:" 20 60 10 \
                       "1" "Select Disk" \
                       "2" "Select Partition Type" \
                       "3" "Select Filesystem" \
                       "4" "Configure Swap" \
                       "5" "Partition and Format Disk" \
                       "0" "Return to Main Menu" \
                       2>&1 >/dev/tty)

        case $choice in
            1) select_disk ;;
            2) select_partition_type ;;
            3) select_filesystem ;;
            4) config_swap ;;
            5) partition_disk ;;
            0) break ;;
            *) dialog --title "Error" --msgbox "Invalid option" 6 30 ;;
        esac
    done
}
