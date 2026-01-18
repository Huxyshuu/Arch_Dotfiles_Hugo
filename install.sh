#!/bin/bash

set -e

REPO_DIR=$(pwd)
BACKUP_DIR="$REPO_DIR/dotfiles"

# --- Function to install an AUR helper if missing ---
install_aur_helper() {
    if command -v paru &> /dev/null; then
        echo -e "\e[32m✔ paru is already installed.\e[0m"
        AUR_HELPER="paru"
    elif command -v yay &> /dev/null; then
        echo -e "\e[32m✔ yay is already installed.\e[0m"
        AUR_HELPER="yay"
    else
        echo -e "\e[33mNo AUR helper found. Installing paru...\e[0m"
        sudo pacman -S --needed base-devel git
        TEMP_AUR="/tmp/paru-bin"
        git clone https://aur.archlinux.org/paru-bin.git "$TEMP_AUR"
        cd "$TEMP_AUR"
        makepkg -si --noconfirm
        cd "$REPO_DIR"
        AUR_HELPER="paru"
    fi
}

echo -e "\e[34m--- Arch Linux Restore ---\e[0m"

# 1. Hardware Detection
echo -e "\e[33mSelect your hardware profile:\e[0m"
echo "1) Laptop (Intel Graphics + Power + Sound Firmware)"
echo "2) Desktop PC (Standard / NVIDIA)"
read -rp "Enter choice [1-2]: " hw_choice

# 2. Package Installation Logic
if [[ -f "packages/pkglist.txt" ]]; then
    echo -e "\e[34mInstalling official packages...\e[0m"
    
    if [[ "$hw_choice" == "1" ]]; then
        echo "Filtering for Laptop/Intel compatibility..."
        # Strip NVIDIA/CUDA and install Intel-specific hardware support
        grep -vE "nvidia|cuda|libva-nvidia-driver" packages/pkglist.txt > /tmp/filtered_pkgs.txt
        sudo pacman -Syu --needed - < /tmp/filtered_pkgs.txt
        sudo pacman -S --needed intel-media-driver vulkan-intel brightnessctl power-profiles-daemon sof-firmware
    else
        echo "Installing full desktop suite..."
        sudo pacman -Syu --needed - < packages/pkglist.txt
    fi
else
    echo -e "\e[31mError: packages/pkglist.txt not found!\e[0m"
    exit 1
fi

# 3. AUR Package Installation (Ensures helper exists)
install_aur_helper

if [[ -f "packages/aurlist.txt" ]]; then
    echo -e "\e[34mInstalling AUR packages using $AUR_HELPER...\e[0m"
    $AUR_HELPER -S --needed - < packages/aurlist.txt
fi

# 4. Deploy Files to System
echo -e "\e[34mDeploying files to respective directories...\e[0m"

if [ -d "$BACKUP_DIR" ]; then
    # --- Home Directory Restore ---
    # Your update.sh creates dotfiles/home/USERNAME/
    # This logic finds that folder and maps it to your current $USER
    if [ -d "$BACKUP_DIR/home" ]; then
        OLD_USER_DIR=$(ls "$BACKUP_DIR/home" | head -n 1)
        echo "Restoring home configs from '$OLD_USER_DIR' to '$USER'..."
        rsync -avh "$BACKUP_DIR/home/$OLD_USER_DIR/" "$HOME/"
    fi

    # --- System Directory Restore (Root) ---
    # Restores /etc, /usr, etc.
    # Note: We exclude 'home' since we handled it above
    echo "Restoring system-level configurations (/etc, /usr)..."
    sudo rsync -avh --exclude='home' "$BACKUP_DIR/" "/"
else
    echo -e "\e[31mError: $BACKUP_DIR not found!\e[0m"
    exit 1
fi

# 5. Enable Systemd Services
echo -e "\e[34mEnabling system services...\e[0m"

# Core Services
SERVICES=("NetworkManager" "bluetooth" "sddm" "cronie")

# Hardware-specific services
if [[ "$hw_choice" == "1" ]]; then
    SERVICES+=("power-profiles-daemon")
fi

for SERVICE in "${SERVICES[@]}"; do
    echo "Enabling $SERVICE..."
    sudo systemctl enable "$SERVICE"
done

echo -e "\e[32m✔ Installation complete! All services enabled.\e[0m"
echo -e "\e[33mWould you like to reboot now? (y/n)\e[0m"
read -r reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    reboot
fi