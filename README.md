```
  ______             __             ______    ______         ______                        __                __  __ 
 /      \           /  |           /      \  /      \       /      |                      /  |              /  |/  |
/$$$$$$  | __    __ $$/   _______ /$$$$$$  |/$$$$$$  |      $$$$$$/  _______    _______  _$$ |_     ______  $$ |$$ |
$$ |__$$ |/  \  /  |/  | /       |$$ |  $$ |$$ \__$$/         $$ |  /       \  /       |/ $$   |   /      \ $$ |$$ |
$$    $$ |$$  \/$$/ $$ |/$$$$$$$/ $$ |  $$ |$$      \         $$ |  $$$$$$$  |/$$$$$$$/ $$$$$$/    $$$$$$  |$$ |$$ |
$$$$$$$$ | $$  $$<  $$ |$$      \ $$ |  $$ | $$$$$$  |        $$ |  $$ |  $$ |$$      \   $$ | __  /    $$ |$$ |$$ |
$$ |  $$ | /$$$$  \ $$ | $$$$$$  |$$ \__$$ |/  \__$$ |       _$$ |_ $$ |  $$ | $$$$$$  |  $$ |/  |/$$$$$$$ |$$ |$$ |
$$ |  $$ |/$$/ $$  |$$ |/     $$/ $$    $$/ $$    $$/       / $$   |$$ |  $$ |/     $$/   $$  $$/ $$    $$ |$$ |$$ |
$$/   $$/ $$/   $$/ $$/ $$$$$$$/   $$$$$$/   $$$$$$/        $$$$$$/ $$/   $$/ $$$$$$$/     $$$$/   $$$$$$$/ $$/ $$/
```

# Axis-install: Arch Linux Installer

## Overview
Axis-install is a console-based Arch Linux installer that leverages the TUI provided by the `dialog` library. It guides you through an interactive Arch Linux installation process, supporting various features like disk partitioning, filesystem selection, and desktop environment setup.

## Features
- Text-based user interface using `dialog`
- Wi-Fi configuration with `iwctl`
- Full disk encryption with LUKS (optional)
- Filesystem selections (ext4, btrfs)
- Desktop environments (KDE, Gnome, Cinnamon, Budgie, Mate, LXQt, XFCE)
- Tiling window managers (Sway, i3, Awesome, Hyprland)
- Login manager options
- Swap configuration

## Requirements
Ensure you have booted from an Arch Linux installation ISO and have internet connectivity to download necessary packages.

## Download and Installation

### Method 1: Using Git
```bash
# Install git if not already installed
pacman -Sy git

# Clone the repository
git clone https://github.com/Axis0S/AxisOS-Install.git

# Navigate to the installer directory
cd AxisOS-Install

# Make the installer executable
chmod +x axis-install.sh

# Run the installer
sudo ./axis-install.sh
```

### Method 2: Direct Download
```bash
# Download the repository as a zip file
curl -L https://github.com/Axis0S/AxisOS-Install/archive/refs/heads/main.zip -o axis-installer.zip

# Install unzip if not already installed
pacman -Sy unzip

# Extract the files
unzip axis-installer.zip

# Navigate to the installer directory
cd AxisOS-Install-main

# Make the installer executable
chmod +x axis-install.sh

# Run the installer
sudo ./axis-install.sh
```

## Installation Steps
1. **Download the installer** using one of the methods above
2. **Run `axis-install.sh`:** This is the main entry point of the installer
3. **Configure Wi-Fi:** Use provided options to connect to the internet
4. **Select Locale, Timezone, and Hostname:** Configure basic system settings
5. **Disk Partitioning:** Choose a disk, partition type (primary or encrypted), filesystem, and swap configuration
6. **User and Root Setup:** Create a root password and user account
7. **Select and Install Desktop Environment:** Choose a desktop environment or tiling window manager
8. **Install System:** Confirm and proceed with the installation
9. **Reboot:** Remove the installation media and reboot into your new Arch Linux system

## Known Issues
- Ensure that `gpm` is running for mouse support in the console.
- Must be connected to a power source during installation.

## Troubleshooting
- Ensure all dependencies are installed and services are enabled. Follow prompts to install missing components during the setup.


