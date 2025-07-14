#!/bin/bash

# Utility functions for Axis-install

# Cleanup function
cleanup() {
    # Unmount partitions if mounted
    umount -R /mnt 2>/dev/null || true
    
    # Close encrypted volumes if open
    cryptsetup close cryptroot 2>/dev/null || true
    
    # Remove temporary files
    rm -f "$INSTALL_CONFIG" 2>/dev/null || true
    
    echo "Cleanup completed"
}

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Error handler
error_exit() {
    dialog --title "Error" \
           --backtitle "AxisOS Installer" \
           --msgbox "$1" 8 60
    log "ERROR: $1"
    exit 1
}

# Set locale
set_locale() {
    # Get list of available locales
    local locales=()
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        locales+=("${line%% *}" "${line#* }")
    done < /etc/locale.gen
    
    local selected
    selected=$(dialog --title "Select Locale" \
                     --backtitle "AxisOS Installer" \
                     --menu "$AXIS_ART\n\nChoose your system locale:" 25 80 15 \
                     "${locales[@]}" \
                     2>&1 >/dev/tty)
    
    if [[ -n "$selected" ]]; then
        save_config "LOCALE" "$selected"
        dialog --title "Locale Set" \
               --backtitle "AxisOS Installer" \
               --msgbox "Locale set to: $selected" 6 50
    fi
}

# Set timezone
set_timezone() {
    # Get regions
    local regions=()
    for region in /usr/share/zoneinfo/*/; do
        region=${region%/}
        region=${region##*/}
        [[ "$region" =~ ^(posix|right)$ ]] && continue
        regions+=("$region" "")
    done
    
    local region
    region=$(dialog --title "Select Region" \
                   --backtitle "AxisOS Installer" \
                   --menu "$AXIS_ART\n\nChoose your region:" 25 60 15 \
                   "${regions[@]}" \
                   2>&1 >/dev/tty)
    
    if [[ -z "$region" ]]; then
        return
    fi
    
    # Get cities for selected region
    local cities=()
    for city in /usr/share/zoneinfo/"$region"/*; do
        [[ -f "$city" ]] || continue
        city=${city##*/}
        cities+=("$city" "")
    done
    
    local city
    city=$(dialog --title "Select City" \
                 --backtitle "AxisOS Installer" \
                 --menu "$AXIS_ART\n\nChoose your city:" 25 60 15 \
                 "${cities[@]}" \
                 2>&1 >/dev/tty)
    
    if [[ -n "$city" ]]; then
        save_config "TIMEZONE" "$region/$city"
        dialog --title "Timezone Set" \
               --backtitle "AxisOS Installer" \
               --msgbox "Timezone set to: $region/$city" 6 50
    fi
}

# Set hostname
set_hostname() {
    local hostname
    hostname=$(dialog --title "Set Hostname" \
                     --backtitle "AxisOS Installer" \
                     --inputbox "$AXIS_ART\n\nEnter the hostname for this system:" 15 60 \
                     "${CONFIG[HOSTNAME]}" \
                     2>&1 >/dev/tty)
    
    if [[ -n "$hostname" ]]; then
        save_config "HOSTNAME" "$hostname"
        dialog --title "Hostname Set" \
               --backtitle "AxisOS Installer" \
               --msgbox "Hostname set to: $hostname" 6 50
    fi
}

# Set root password
set_root_password() {
    local password password_confirm
    
    while true; do
        password=$(dialog --title "Set Root Password" \
                         --backtitle "AxisOS Installer" \
                         --passwordbox "$AXIS_ART\n\nEnter root password:" 15 60 \
                         2>&1 >/dev/tty)
        
        [[ -z "$password" ]] && return
        
        password_confirm=$(dialog --title "Confirm Root Password" \
                                 --backtitle "AxisOS Installer" \
                                 --passwordbox "$AXIS_ART\n\nConfirm root password:" 15 60 \
                                 2>&1 >/dev/tty)
        
        if [[ "$password" == "$password_confirm" ]]; then
            save_config "ROOT_PASSWORD" "$password"
            dialog --title "Success" \
                   --backtitle "AxisOS Installer" \
                   --msgbox "Root password set successfully" 6 40
            break
        else
            dialog --title "Error" \
                   --backtitle "AxisOS Installer" \
                   --msgbox "Passwords do not match. Please try again." 6 50
        fi
    done
}

# Create user account
create_user_account() {
    # Get full name
    local fullname
    fullname=$(dialog --title "User Full Name" \
                     --backtitle "AxisOS Installer" \
                     --inputbox "$AXIS_ART\n\nEnter user's full name:" 15 60 \
                     "${CONFIG[USER_FULLNAME]}" \
                     2>&1 >/dev/tty)
    
    [[ -z "$fullname" ]] && return
    save_config "USER_FULLNAME" "$fullname"
    
    # Get username
    local username
    username=$(dialog --title "Username" \
                     --backtitle "AxisOS Installer" \
                     --inputbox "$AXIS_ART\n\nEnter username (lowercase, no spaces):" 15 60 \
                     "${CONFIG[USERNAME]}" \
                     2>&1 >/dev/tty)
    
    [[ -z "$username" ]] && return
    
    # Validate username
    if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        dialog --title "Error" \
               --backtitle "AxisOS Installer" \
               --msgbox "Invalid username. Use only lowercase letters, numbers, underscore and dash." 8 60
        return
    fi
    
    save_config "USERNAME" "$username"
    
    # Get password
    local password password_confirm
    while true; do
        password=$(dialog --title "Set User Password" \
                         --backtitle "AxisOS Installer" \
                         --passwordbox "$AXIS_ART\n\nEnter password for $username:" 15 60 \
                         2>&1 >/dev/tty)
        
        [[ -z "$password" ]] && return
        
        password_confirm=$(dialog --title "Confirm User Password" \
                                 --backtitle "AxisOS Installer" \
                                 --passwordbox "$AXIS_ART\n\nConfirm password for $username:" 15 60 \
                                 2>&1 >/dev/tty)
        
        if [[ "$password" == "$password_confirm" ]]; then
            save_config "USER_PASSWORD" "$password"
            dialog --title "Success" \
                   --backtitle "AxisOS Installer" \
                   --msgbox "User account details saved successfully" 6 50
            break
        else
            dialog --title "Error" \
                   --backtitle "AxisOS Installer" \
                   --msgbox "Passwords do not match. Please try again." 6 50
        fi
    done
}

# Select desktop environment
select_desktop_environment() {
    local choice
    choice=$(dialog --title "Installation Type" \
                   --backtitle "AxisOS Installer" \
                   --menu "$AXIS_ART\n\nSelect installation type:" 20 70 10 \
                   "1" "Desktop Environment" \
                   "2" "Tiling Window Manager" \
                   "3" "Base System Only" \
                   2>&1 >/dev/tty)
    
    case $choice in
        1)
            save_config "DESKTOP_TYPE" "desktop"
            select_desktop_env
            ;;
        2)
            save_config "DESKTOP_TYPE" "tiling"
            select_tiling_wm
            ;;
        3)
            save_config "DESKTOP_TYPE" "none"
            save_config "DESKTOP_ENV" ""
            save_config "TILING_WM" ""
            dialog --title "Base System" \
                   --backtitle "AxisOS Installer" \
                   --msgbox "Base system only will be installed" 6 50
            ;;
    esac
}

# Select specific desktop environment
select_desktop_env() {
    local envs=()
    envs+=("KDE" "Plasma Desktop")
    envs+=("Gnome" "GNOME Desktop")
    envs+=("Cinnamon" "Cinnamon Desktop")
    envs+=("Budgie" "Budgie Desktop")
    envs+=("Mate" "MATE Desktop")
    envs+=("LXQt" "Lightweight Qt Desktop")
    envs+=("XFCE" "Xfce Desktop")
    
    local selected
    selected=$(dialog --title "Select Desktop Environment" \
                     --backtitle "AxisOS Installer" \
                     --menu "$AXIS_ART\n\nChoose a desktop environment:" 22 70 10 \
                     "${envs[@]}" \
                     2>&1 >/dev/tty)
    
    if [[ -n "$selected" ]]; then
        save_config "DESKTOP_ENV" "$selected"
        save_config "TILING_WM" ""
        dialog --title "Desktop Selected" \
               --backtitle "AxisOS Installer" \
               --msgbox "$selected desktop environment selected" 6 50
    fi
}

# Select tiling window manager
select_tiling_wm() {
    local wms=()
    wms+=("Sway" "Wayland compositor (i3-compatible)")
    wms+=("i3" "Improved tiling window manager")
    wms+=("Awesome" "Highly configurable WM")
    wms+=("Hyprland" "Dynamic tiling Wayland compositor")
    
    local selected
    selected=$(dialog --title "Select Window Manager" \
                     --backtitle "AxisOS Installer" \
                     --menu "$AXIS_ART\n\nChoose a tiling window manager:" 20 70 10 \
                     "${wms[@]}" \
                     2>&1 >/dev/tty)
    
    if [[ -n "$selected" ]]; then
        save_config "TILING_WM" "$selected"
        save_config "DESKTOP_ENV" ""
        dialog --title "WM Selected" \
               --backtitle "AxisOS Installer" \
               --msgbox "$selected window manager selected" 6 50
    fi
}

# Select login manager
select_login_manager() {
    local managers=()
    managers+=("lightdm" "Lightweight Display Manager")
    managers+=("gdm" "GNOME Display Manager")
    managers+=("sddm" "Simple Desktop Display Manager")
    managers+=("none" "No display manager (console login)")
    
    local selected
    selected=$(dialog --title "Select Login Manager" \
                     --backtitle "AxisOS Installer" \
                     --menu "$AXIS_ART\n\nChoose a login manager:" 20 70 10 \
                     "${managers[@]}" \
                     2>&1 >/dev/tty)
    
    if [[ -n "$selected" ]]; then
        if [[ "$selected" == "none" ]]; then
            save_config "LOGIN_MANAGER" ""
        else
            save_config "LOGIN_MANAGER" "$selected"
        fi
        dialog --title "Login Manager" \
               --backtitle "AxisOS Installer" \
               --msgbox "Login manager set to: $selected" 6 50
    fi
}

# Confirm installation
confirm_installation() {
    if ! validate_config; then
        return
    fi
    
    local summary
    summary=$(get_config_summary)
    
    dialog --title "Confirm Installation" \
           --backtitle "AxisOS Installer" \
           --yesno "$AXIS_ART\n\n$summary\n\nDo you want to proceed with the installation?\n\nWARNING: This will erase all data on the selected disk!" 25 80
    
    if [[ $? -eq 0 ]]; then
        perform_installation
    fi
}
