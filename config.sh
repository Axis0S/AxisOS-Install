#!/bin/bash

# Axis-install Configuration File
# Contains all configuration variables and settings

# Installation configuration variables
declare -A CONFIG

# Default values
CONFIG[LOCALE]="en_US.UTF-8"
CONFIG[TIMEZONE]="UTC"
CONFIG[HOSTNAME]="archlinux"
CONFIG[DISK]=""
CONFIG[PARTITION_TYPE]="primary"  # primary or encrypted
CONFIG[FILESYSTEM]="ext4"  # ext4, btrfs
CONFIG[SWAP_SIZE]="0"  # In GB, 0 means no swap
CONFIG[ROOT_PASSWORD]=""
CONFIG[USER_FULLNAME]=""
CONFIG[USERNAME]=""
CONFIG[USER_PASSWORD]=""
CONFIG[DESKTOP_TYPE]="none"  # none, desktop, tiling
CONFIG[DESKTOP_ENV]=""  # KDE, Gnome, Cinnamon, Budgie, Mate, LXQt, XFCE
CONFIG[TILING_WM]=""  # Sway, i3, Awesome, Hyprland
CONFIG[LOGIN_MANAGER]=""  # lightdm, gdm, sddm
CONFIG[ENCRYPTION_PASSWORD]=""

# Partition variables
EFI_PARTITION=""
BOOT_PARTITION=""
ROOT_PARTITION=""
SWAP_PARTITION=""

# Desktop environment packages
declare -A DESKTOP_PACKAGES
DESKTOP_PACKAGES[KDE]="plasma-meta kde-applications-meta"
DESKTOP_PACKAGES[Gnome]="gnome gnome-extra"
DESKTOP_PACKAGES[Cinnamon]="cinnamon nemo-fileroller"
DESKTOP_PACKAGES[Budgie]="budgie-desktop budgie-extras"
DESKTOP_PACKAGES[Mate]="mate mate-extra"
DESKTOP_PACKAGES[LXQt]="lxqt breeze-icons"
DESKTOP_PACKAGES[XFCE]="xfce4 xfce4-goodies"

# Tiling window manager packages
declare -A TILING_PACKAGES
TILING_PACKAGES[Sway]="sway swaylock swayidle waybar wofi"
TILING_PACKAGES[i3]="i3-wm i3status i3lock dmenu"
TILING_PACKAGES[Awesome]="awesome"
TILING_PACKAGES[Hyprland]="hyprland waybar wofi"

# Login manager packages
declare -A LOGIN_PACKAGES
LOGIN_PACKAGES[lightdm]="lightdm lightdm-gtk-greeter"
LOGIN_PACKAGES[gdm]="gdm"
LOGIN_PACKAGES[sddm]="sddm"

# Base system packages
BASE_PACKAGES="base linux linux-firmware base-devel networkmanager vim nano sudo grub efibootmgr os-prober ntfs-3g"

# Additional packages for desktop systems
DESKTOP_BASE_PACKAGES="xorg-server xorg-apps pipewire pipewire-pulse pipewire-alsa pipewire-jack firefox"

# Initialize configuration file
initialize_config() {
    echo "# Axis-install Configuration" > "$INSTALL_CONFIG"
    for key in "${!CONFIG[@]}"; do
        echo "${key}=${CONFIG[$key]}" >> "$INSTALL_CONFIG"
    done
}

# Save configuration value
save_config() {
    local key="$1"
    local value="$2"
    CONFIG[$key]="$value"
    
    # Update config file
    if grep -q "^${key}=" "$INSTALL_CONFIG" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$INSTALL_CONFIG"
    else
        echo "${key}=${value}" >> "$INSTALL_CONFIG"
    fi
}

# Load configuration
load_config() {
    if [[ -f "$INSTALL_CONFIG" ]]; then
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            CONFIG[$key]="$value"
        done < "$INSTALL_CONFIG"
    fi
}

# Validate configuration
validate_config() {
    local errors=()
    
    [[ -z "${CONFIG[DISK]}" ]] && errors+=("No disk selected")
    [[ -z "${CONFIG[ROOT_PASSWORD]}" ]] && errors+=("Root password not set")
    [[ -z "${CONFIG[USERNAME]}" ]] && errors+=("Username not set")
    [[ -z "${CONFIG[USER_PASSWORD]}" ]] && errors+=("User password not set")
    
    if [[ "${CONFIG[PARTITION_TYPE]}" == "encrypted" && -z "${CONFIG[ENCRYPTION_PASSWORD]}" ]]; then
        errors+=("Encryption password not set")
    fi
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        local error_msg="Configuration errors:\n"
        for error in "${errors[@]}"; do
            error_msg+="\n- $error"
        done
        dialog --title "Configuration Error" --msgbox "$error_msg" 12 60
        return 1
    fi
    
    return 0
}

# Get all configuration as string
get_config_summary() {
    local summary="Installation Configuration:\n\n"
    summary+="Locale: ${CONFIG[LOCALE]}\n"
    summary+="Timezone: ${CONFIG[TIMEZONE]}\n"
    summary+="Hostname: ${CONFIG[HOSTNAME]}\n"
    summary+="Disk: ${CONFIG[DISK]}\n"
    summary+="Partition Type: ${CONFIG[PARTITION_TYPE]}\n"
    summary+="Filesystem: ${CONFIG[FILESYSTEM]}\n"
    summary+="Swap: ${CONFIG[SWAP_SIZE]}GB\n"
    summary+="User: ${CONFIG[USERNAME]} (${CONFIG[USER_FULLNAME]})\n"
    
    if [[ "${CONFIG[DESKTOP_TYPE]}" == "desktop" ]]; then
        summary+="Desktop Environment: ${CONFIG[DESKTOP_ENV]}\n"
    elif [[ "${CONFIG[DESKTOP_TYPE]}" == "tiling" ]]; then
        summary+="Window Manager: ${CONFIG[TILING_WM]}\n"
    else
        summary+="Installation Type: Base system only\n"
    fi
    
    summary+="Login Manager: ${CONFIG[LOGIN_MANAGER]:-none}\n"
    
    echo "$summary"
}
