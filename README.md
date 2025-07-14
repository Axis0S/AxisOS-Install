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

## Installation Steps
1. **Run `axis-install.sh`:** This is the main entry point of the installer.
2. **Configure Wi-Fi:** Use provided options to connect to the internet.
3. **Select Locale, Timezone, and Hostname:** Configure basic system settings.
4. **Disk Partitioning:** Choose a disk, partition type (primary or encrypted), filesystem, and swap configuration.
5. **User and Root Setup:** Create a root password and user account.
6. **Select and Install Desktop Environment:** Choose a desktop environment or tiling window manager.
7. **Log Out after Installation:** Remove the installation media and reboot.

## Usage
Execute the main installer script as root: 
```bash
sudo ./axis-install.sh
```

## Known Issues
- Ensure that `gpm` is running for mouse support in the console.
- Must be connected to a power source during installation.

## Troubleshooting
- Ensure all dependencies are installed and services are enabled. Follow prompts to install missing components during the setup.


