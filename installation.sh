#!/bin/bash

# Perform the installation of Arch Linux with the configured settings

perform_installation() {
    load_config

    dialog --title "Starting Installation" \
           --backtitle "AxisOS Installer" \
           --infobox "$AXIS_ART\n\nStarting the installation process. Please wait..." 10 60
    
    # Show progress
    (
        echo "10"
        echo "XXX"
        echo "Mounting filesystems..."
        echo "XXX"
        
        # Mount the filesystems
        mount "$ROOT_PARTITION" /mnt
        mkdir -p /mnt/boot/efi
        mount "$EFI_PARTITION" /mnt/boot/efi
        
        echo "20"
        echo "XXX"
        echo "Creating swap file if configured..."
        echo "XXX"
        
        # Create swap if specified
        local swap_size="${CONFIG[SWAP_SIZE]}"
        if [[ "$swap_size" -gt 0 ]]; then
            fallocate -l ${swap_size}G /mnt/swapfile
            chmod 600 /mnt/swapfile
            mkswap /mnt/swapfile
            swapon /mnt/swapfile
        fi
        
        echo "30"
        echo "XXX"
        echo "Installing base system..."
        echo "XXX"
        
        # Base installation
        pacstrap /mnt $BASE_PACKAGES
        
        echo "60"
        echo "XXX"
        echo "Generating fstab..."
        echo "XXX"
        
        # Fstab
        genfstab -U /mnt >> /mnt/etc/fstab
        
        # Add swap to fstab if exists
        if [[ "$swap_size" -gt 0 ]]; then
            echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab
        fi
        
        echo "70"
        echo "XXX"
        echo "Configuring system..."
        echo "XXX"
        
        # Copy installer scripts to new system
        cp -r "$SCRIPT_DIR" /mnt/axis-installer
        cp "$INSTALL_CONFIG" /mnt/axis-installer/
        
        # Chroot and configure
        arch-chroot /mnt /bin/bash -c "cd /axis-installer && source config.sh && source installation.sh && configure_system"
        
        echo "90"
        echo "XXX"
        echo "Cleaning up..."
        echo "XXX"
        
        # Cleanup
        rm -rf /mnt/axis-installer
        
        echo "100"
        echo "XXX"
        echo "Installation complete!"
        echo "XXX"
        
    ) | dialog --title "Installing Arch Linux" \
               --backtitle "AxisOS Installer" \
               --gauge "Starting installation..." 10 70 0
    
    # Unmount
    swapoff /mnt/swapfile 2>/dev/null || true
    umount -R /mnt
    
    dialog --title "Installation Complete" \
           --backtitle "AxisOS Installer" \
           --msgbox "$AXIS_ART\n\nArch Linux has been successfully installed!\n\nYou can now reboot your system." 15 70
}

# Configure the installed system
configure_system() {
    load_config
    
    ln -sf /usr/share/zoneinfo/${CONFIG[TIMEZONE]} /etc/localtime
    hwclock --systohc
    echo "${CONFIG[HOSTNAME]}" > /etc/hostname

    # Set locale
    sed -i "s/#${CONFIG[LOCALE]}/${CONFIG[LOCALE]}/" /etc/locale.gen
    locale-gen
    echo "LANG=${CONFIG[LOCALE]}" > /etc/locale.conf

    # Configure hosts
    echo "127.0.0.1 localhost" >> /etc/hosts
    echo "::1       localhost" >> /etc/hosts
    echo "127.0.1.1 ${CONFIG[HOSTNAME]}.localdomain ${CONFIG[HOSTNAME]}" >> /etc/hosts

    # Set root password
    echo "root:${CONFIG[ROOT_PASSWORD]}" | chpasswd

    # Create user
    useradd -m -G wheel -s /bin/bash "${CONFIG[USERNAME]}"
    echo "${CONFIG[USERNAME]}:${CONFIG[USER_PASSWORD]}" | chpasswd

    # Sudoers
    echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

    # Install desktop or tiling wm if selected
    local desktop_env="${CONFIG[DESKTOP_ENV]}"
    local tiling_wm="${CONFIG[TILING_WM]}"

    if [[ -n "$desktop_env" ]]; then
        pacman -S --noconfirm ${DESKTOP_PACKAGES[$desktop_env]} $DESKTOP_BASE_PACKAGES
    elif [[ -n "$tiling_wm" ]]; then
        pacman -S --noconfirm ${TILING_PACKAGES[$tiling_wm]} $DESKTOP_BASE_PACKAGES
    fi

    # Install login manager if selected
    local login_manager="${CONFIG[LOGIN_MANAGER]}"
    if [[ -n "$login_manager" ]]; then
        pacman -S --noconfirm ${LOGIN_PACKAGES[$login_manager]}
        systemctl enable $login_manager.service
    fi

    # Install bootloader
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    
    # Configure GRUB for encrypted systems
    if [[ "${CONFIG[PARTITION_TYPE]}" == "encrypted" ]]; then
        # Get UUID of encrypted partition
        local crypt_uuid=$(blkid -s UUID -o value "${CONFIG[DISK]}2")
        
        # Update GRUB configuration
        sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$crypt_uuid:cryptroot\"|" /etc/default/grub
        
        # Update mkinitcpio hooks
        sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
        mkinitcpio -P
    fi
    
    grub-mkconfig -o /boot/grub/grub.cfg
    
    # Enable NetworkManager
    systemctl enable NetworkManager

    echo -e "${GREEN}System has been configured.${NC}"
}
