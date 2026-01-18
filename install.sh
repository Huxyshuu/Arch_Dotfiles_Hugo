#!/bin/bash

# set -u ensures we don't use undefined variables
set -u

REPO_DIR=$(pwd)
BACKUP_DIR="$REPO_DIR/dotfiles"
FAILED_AUR=()

echo -e "\e[34m--- Arch Linux Restore ---\e[0m"

# 1. Hardware Detection
echo -e "\e[33mSelect your hardware profile:\e[0m"
echo "1) Laptop (Intel Graphics + Power + Sound Firmware)"
echo "2) Desktop PC (Standard / NVIDIA)"
read -rp "Enter choice [1-2]: " hw_choice

# 2. Package Installation Logic (Pacman)
if [[ -f "packages/pkglist.txt" ]]; then
    echo -e "\e[34mInstalling official packages...\e[0m"
    
    if [[ "$hw_choice" == "1" ]]; then
        echo "Filtering for Laptop/Intel compatibility..."
        grep -vE "nvidia|cuda|libva-nvidia-driver" packages/pkglist.txt > /tmp/filtered_pkgs.txt
        sudo pacman -Syu --needed --noconfirm - < /tmp/filtered_pkgs.txt
        sudo pacman -S --needed --noconfirm intel-media-driver vulkan-intel brightnessctl power-profiles-daemon sof-firmware
    else
        echo "Installing full desktop suite..."
        sudo pacman -Syu --needed --noconfirm - < packages/pkglist.txt
    fi
else
    echo -e "\e[31mError: packages/pkglist.txt not found!\e[0m"
    exit 1
fi

# 3. AUR Helper Self-Healing Check
echo -e "\e[34mChecking AUR helper health...\e[0m"
REINSTALL_AUR=false

if command -v paru &> /dev/null; then
    # Test if paru actually works or throws a library error
    if ! paru --version &> /dev/null; then
        echo -e "\e[31mparu is broken (libalpm error). Reinstalling...\e[0m"
        REINSTALL_AUR=true
    else
        echo -e "\e[32m✔ paru is healthy.\e[0m"
        AUR_HELPER="paru"
    fi
else
    echo -e "\e[33mparu not found. Installing...\e[0m"
    REINSTALL_AUR=true
fi

if [ "$REINSTALL_AUR" = true ]; then
    sudo pacman -S --needed --noconfirm base-devel git
    rm -rf /tmp/paru-bin
    git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
    cd /tmp/paru-bin && makepkg -si --noconfirm
    cd "$REPO_DIR"
    AUR_HELPER="paru"
fi

# 4. AUR Package Installation (Looping for Error Handling)
if [[ -f "packages/aurlist.txt" ]]; then
    echo -e "\e[34mInstalling AUR packages individually...\e[0m"
    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
        # Skip empty lines or comments
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
        
        echo -e "\e[34mInstalling: $pkg\e[0m"
        if ! $AUR_HELPER -S --needed --noconfirm "$pkg"; then
            echo -e "\e[31mFAILED: $pkg\e[0m"
            FAILED_AUR+=("$pkg")
        fi
    done < packages/aurlist.txt
fi

# 5. Deploy Files to System
echo -e "\e[34mDeploying files to respective directories...\e[0m"
if [ -d "$BACKUP_DIR" ]; then
    if [ -d "$BACKUP_DIR/home" ]; then
        OLD_USER_DIR=$(ls "$BACKUP_DIR/home" | head -n 1)
        rsync -avh "$BACKUP_DIR/home/$OLD_USER_DIR/" "$HOME/"
    fi
    sudo rsync -avh --exclude='home' "$BACKUP_DIR/" "/"
else
    echo -e "\e[31mError: $BACKUP_DIR not found!\e[0m"
fi

# 6. Enable Systemd Services
echo -e "\e[34mEnabling system services...\e[0m"
SERVICES=("NetworkManager" "bluetooth" "sddm" "cronie")
[[ "$hw_choice" == "1" ]] && SERVICES+=("power-profiles-daemon")

for SERVICE in "${SERVICES[@]}"; do
    sudo systemctl enable "$SERVICE" --now || echo -e "\e[31mCould not enable $SERVICE\e[0m"
done

# === Final Report ===
echo -e "\n\e[32m--- Restore Process Finished ---\e[0m"

if [ ${#FAILED_AUR[@]} -ne 0 ]; then
    echo "AUR Installation Failures - $(date)" > failed_aur_packages.txt
    echo "--------------------------------------" >> failed_aur_packages.txt
    printf "%s\n" "${FAILED_AUR[@]}" >> failed_aur_packages.txt

    echo -e "\e[31mThe following AUR packages failed. List saved to: failed_aur_packages.txt\e[0m"
    for failed in "${FAILED_AUR[@]}"; do
        echo -e "\e[1;31m  - $failed\e[0m"
    done
else
    echo -e "\e[32m✔ All AUR packages installed successfully!\e[0m"
    [ -f failed_aur_packages.txt ] && rm failed_aur_packages.txt
fi

echo -e "\e[33mReboot recommended. Reboot now? (y/n)\e[0m"
read -r reboot_choice
[[ "$reboot_choice" =~ ^[Yy]$ ]] && reboot