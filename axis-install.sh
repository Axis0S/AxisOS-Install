#!/bin/bash

# Axis-install - Arch Linux Installer
# Main installer script with TUI interface

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/axis-install.log"
INSTALL_CONFIG="/tmp/axis-config"

# ASCII Art
AXIS_ART='
  ______             __             ______    ______         ______                        __                __  __ 
 /      \           /  |           /      \  /      \       /      |                      /  |              /  |/  |
/$$$$$$  | __    __ $$/   _______ /$$$$$$  |/$$$$$$  |      $$$$$$/  _______    _______  _$$ |_     ______  $$ |$$ |
$$ |__$$ |/  \  /  |/  | /       |$$ |  $$ |$$ \__$$/         $$ |  /       \  /       |/ $$   |   /      \ $$ |$$ |
$$    $$ |$$  \/$$/ $$ |/$$$$$$$/ $$ |  $$ |$$      \         $$ |  $$$$$$$  |/$$$$$$$/ $$$$$$/    $$$$$$  |$$ |$$ |
$$$$$$$$ | $$  $$<  $$ |$$      \ $$ |  $$ | $$$$$$  |        $$ |  $$ |  $$ |$$      \   $$ | __  /    $$ |$$ |$$ |
$$ |  $$ | /$$$$  \ $$ | $$$$$$  |$$ \__$$ |/  \__$$ |       _$$ |_ $$ |  $$ | $$$$$$  |  $$ |/  |/$$$$$$$ |$$ |$$ |
$$ |  $$ |/$$/ $$  |$$ |/     $$/ $$    $$/ $$    $$/       / $$   |$$ |  $$ |/     $$/   $$  $$/ $$    $$ |$$ |$$ |
$$/   $$/ $$/   $$/ $$/ $$$$$$$/   $$$$$$/   $$$$$$/        $$$$$$/ $$/   $$/ $$$$$$$/     $$$$/   $$$$$$$/ $$/ $$/

'

# Source configuration and utility functions
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/partitioning.sh"
source "$SCRIPT_DIR/installation.sh"

# Initialize log
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Main functions
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
}

check_arch_iso() {
    if ! grep -q "archiso" /proc/cmdline 2>/dev/null; then
        echo -e "${RED}This installer should be run from an Arch Linux ISO${NC}"
        exit 1
    fi
}

show_welcome() {
    dialog --title "Axis-install - Arch Linux Installer" \
           --backtitle "AxisOS Installer" \
           --msgbox "$AXIS_ART\n\nWelcome to Axis-install!\n\nThis installer will guide you through the process of installing Arch Linux on your system.\n\nPress OK to continue." 20 80
}

check_dependencies() {
    local missing_deps=()
    local required_deps=("dialog" "gpm" "iwctl" "pacman" "fdisk" "mkfs.ext4" "mkfs.btrfs" "mkswap")
    
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        dialog --title "Installing Dependencies" \
               --backtitle "AxisOS Installer" \
               --infobox "Installing missing dependencies: ${missing_deps[*]}" 6 60
        
        pacman -Sy --noconfirm "${missing_deps[@]}" || {
            dialog --title "Error" --msgbox "Failed to install dependencies" 6 40
            exit 1
        }
    fi
    
    # Enable GPM service
    systemctl enable gpm.service || true
    systemctl start gpm.service || true
}


main_menu() {
    while true; do
        choice=$(dialog --title "Axis-install Main Menu" \
                       --backtitle "AxisOS Installer" \
                       --menu "$AXIS_ART\n\nChoose an option:" 25 80 10 \
                       "1" "Set Locale" \
                       "2" "Set Timezone" \
                       "3" "Set Hostname" \
                       "4" "Disk Partitioning" \
                       "5" "Set Root Password" \
                       "6" "Create User Account" \
                       "7" "Select Desktop Environment" \
                       "8" "Select Login Manager" \
                       "9" "Install System" \
                       "0" "Exit" \
                       2>&1 >/dev/tty)
        
        case $choice in
            1) set_locale ;;
            2) set_timezone ;;
            3) set_hostname ;;
            4) disk_menu ;;
            5) set_root_password ;;
            6) create_user_account ;;
            7) select_desktop_environment ;;
            8) select_login_manager ;;
            9) confirm_installation ;;
            0) exit 0 ;;
            *) dialog --title "Error" --msgbox "Invalid option" 6 30 ;;
        esac
    done
}

# Main execution
main() {
    check_root
    check_arch_iso
    show_welcome
    check_dependencies
    initialize_config
    main_menu
}

# Trap for cleanup
trap 'cleanup' EXIT

# Run main function
main "$@"
