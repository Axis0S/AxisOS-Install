#!/bin/bash

# Network management functions for Axis-install

# Get available Wi-Fi networks
get_wifi_networks() {
    # Start iwctl service if not running
    systemctl start iwd.service 2>/dev/null || true
    
    # Get device name
    local device=$(iwctl device list | grep -E '^\s+\w+' | awk '{print $1}' | head -1)
    
    if [[ -z "$device" ]]; then
        dialog --title "Error" --msgbox "No Wi-Fi device found" 6 40
        return 1
    fi
    
    # Scan for networks
    iwctl station "$device" scan
    sleep 2
    
    # Get network list
    local networks=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]+(.+)[[:space:]]+psk ]]; then
            network_name=$(echo "$line" | awk '{print $1}')
            signal=$(echo "$line" | awk '{print $2}')
            networks+=("$network_name" "Signal: $signal")
        fi
    done < <(iwctl station "$device" get-networks)
    
    if [[ ${#networks[@]} -eq 0 ]]; then
        dialog --title "No Networks" --msgbox "No Wi-Fi networks found" 6 40
        return 1
    fi
    
    # Show network selection dialog
    local selected
    selected=$(dialog --title "Select Wi-Fi Network" \
                     --menu "$AXIS_ART\n\nChoose a Wi-Fi network:" 20 70 10 \
                     "${networks[@]}" \
                     2>&1 >/dev/tty)
    
    if [[ -n "$selected" ]]; then
        connect_to_network "$device" "$selected"
    fi
}

# Connect to selected network
connect_to_network() {
    local device="$1"
    local network="$2"
    
    # Get password
    local password
    password=$(dialog --title "Wi-Fi Password" \
                     --passwordbox "$AXIS_ART\n\nEnter password for $network:" 15 60 \
                     2>&1 >/dev/tty)
    
    if [[ -z "$password" ]]; then
        return
    fi
    
    # Connect to network
    dialog --title "Connecting" --infobox "Connecting to $network..." 5 40
    
    # Use iwctl to connect
    echo -e "station $device connect \"$network\"\n$password\nquit" | iwctl
    
    sleep 3
    
    # Check connection
    if ping -c 1 google.com &> /dev/null; then
        dialog --title "Success" --msgbox "Successfully connected to $network" 6 50
    else
        dialog --title "Error" --msgbox "Failed to connect to $network" 6 50
    fi
}

# Main Wi-Fi configuration function
configure_wifi() {
    local choice
    choice=$(dialog --title "Wi-Fi Configuration" \
                   --menu "$AXIS_ART\n\nChoose an option:" 15 60 5 \
                   "1" "Scan and select Wi-Fi network" \
                   "2" "Use iwctl manually" \
                   "3" "Skip Wi-Fi setup" \
                   2>&1 >/dev/tty)
    
    case $choice in
        1) get_wifi_networks ;;
        2) 
            dialog --title "Manual Configuration" \
                   --msgbox "Launching iwctl for manual configuration..." 6 50
            iwctl
            ;;
        3) return ;;
    esac
    
    # Final connectivity check
    if ! ping -c 1 google.com &> /dev/null; then
        dialog --title "Network Status" \
               --msgbox "Warning: No internet connection detected.\n\nThe installer requires internet to download packages." 8 60
    fi
}

