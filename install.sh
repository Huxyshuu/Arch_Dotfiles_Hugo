#!/bin/bash

# set -e removed here so the script doesn't crash if one package fails
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

# 3. AUR Package Installation (Looping for Error Handling)
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
else
    echo -e "\e[33mNo AUR helper found. Installing paru-bin...\e[0m"
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
    cd /tmp/paru-bin && makepkg -si --noconfirm
    cd "$REPO_DIR"
    AUR_HELPER="paru"
fi

if [[ -f "packages/aurlist.txt" ]]; then
    echo -e "\e[34mInstalling AUR packages individually...\e[0m"
    while IFS= read -r pkg; do
        if [[ -n "$pkg" ]]; then
            echo -e "\e[34mInstalling: $pkg\e[0m"
            if ! $AUR_HELPER -S --needed --noconfirm "$pkg"; then
                echo -e "\e[31mFAILED: $pkg\e[0m"
                FAILED_AUR+=("$pkg")
            fi
        fi
    done < packages/aurlist.txt
fi

# 4. Deploy Files to System
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

# 5. Enable Systemd Services
echo -e "\e[34mEnabling system services...\e[0m"
SERVICES=("NetworkManager" "bluetooth" "sddm" "cronie")
[[ "$hw_choice" == "1" ]] && SERVICES+=("power-profiles-daemon")

for SERVICE in "${SERVICES[@]}"; do
    sudo systemctl enable "$SERVICE" --now || echo -e "\e[31mCould not enable $SERVICE\e[0m"
done

# === Final Report ===
echo -e "\n\e[32m--- Restore Process Finished ---\e[0m"

if [ ${#FAILED_AUR[@]} -ne 0 ]; then
    # Create the file and add a header with the date
    echo "AUR Installation Failures - $(date)" > failed_aur_packages.txt
    echo "--------------------------------------" >> failed_aur_packages.txt
    
    # Append the list of failed packages
    printf "%s\n" "${FAILED_AUR[@]}" >> failed_aur_packages.txt

    echo -e "\e[31mThe following AUR packages failed. List saved to: $(pwd)/failed_aur_packages.txt\e[0m"
    for failed in "${FAILED_AUR[@]}"; do
        echo -e "\e[1;31m  - $failed\e[0m"
    done
else
    echo -e "\e[32m✔ All AUR packages installed successfully!\e[0m"
    # Optional: Delete the failure log from previous runs if this run is successful
    [ -f failed_aur_packages.txt ] && rm failed_aur_packages.txt
fi

echo -e "\e[33mReboot recommended. Reboot now? (y/n)\e[0m"
read -r reboot_choice
[[ "$reboot_choice" =~ ^[Yy]$ ]] && reboot