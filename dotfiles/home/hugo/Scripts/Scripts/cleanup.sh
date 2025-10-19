#!/bin/bash
# Arch cleanup script: package cache, orphan packages, AUR cache, journal logs

echo "==> Cleaning pacman cache..."
sudo pacman -Sc --noconfirm

echo "==> Removing orphan packages..."
orphans=$(pacman -Qtdq)
if [[ -n "$orphans" ]]; then
    sudo pacman -Rns --noconfirm $orphans
else
    echo "No orphan packages found."
fi

# Check if yay or paru exists, then clean AUR cache
if command -v yay &> /dev/null; then
    echo "==> Cleaning yay cache..."
    yay -Sc --noconfirm
elif command -v paru &> /dev/null; then
    echo "==> Cleaning paru cache..."
    paru -Sc --noconfirm
else
    echo "No AUR helper (yay/paru) found. Skipping AUR cache cleanup."
fi

echo "==> Vacuuming old journal logs (keeping last 14 days)..."
sudo journalctl --vacuum-time=14d

echo "==> Cleanup complete!"
