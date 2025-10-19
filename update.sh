#!/bin/bash

########################
# This script pushes system and configuration files 
# into github repo
########################

set -e

BACKUP_DIR="./dotfiles"

# Folders/files to back up (absolute paths)
CONFIG_PATHS=(
    "$HOME/.config/fastfetch"             # System info tool
    "$HOME/.config/hypr"                  # Window manager
    "$HOME/.config/kitty"                 # Terminal emulator
    "$HOME/.config/rofi"                  # Application launcher
    "$HOME/.config/waybar"                # Status bar
    "$HOME/.config/wlogout"               # Logout screen
    "$HOME/.config/eww"                   # Widget tool
    "$HOME/.config/flameshot"             # Screenshot tool
    "$HOME/.bashrc"                       # Bash configuration
    "$HOME/Scripts"                       # Scripts
    "$HOME/Wallpapers"                    # Wallpapers
    "/usr/share/sddm/themes/sugar-candy"  # SDDM theme
    "/etc/sddm.conf.d"                    # SDDM configuration
    "/etc/pacman.d/mirrorlist"            # Pacman mirrorlist
    "/etc/pacman.conf"                    # Pacman configuration
    "/etc/paru.conf"                      # Paru configuration
    "$HOME/.local/share/applications"     # User applications, remember to remove unnecessary apps
)

mkdir -p "$BACKUP_DIR"

copy_item() {
  local SRC="$1"
  if [[ -e "$SRC" ]]; then
    REL_PATH="${SRC#/}"   # remove leading /
    DEST="$BACKUP_DIR/$REL_PATH"
    echo -e "\e[32mCopying $SRC → $DEST\e[0m"
    mkdir -p "$(dirname "$DEST")"
    cp -r "$SRC" "$DEST"
  else
    echo -e "\e[31mSkipping $SRC — does not exist.\e[0m"
  fi
}

# Copy configs and home files
for SRC in "${CONFIG_PATHS[@]}"; do
  copy_item "$SRC"
done

# Official repository packages
mkdir -p packages
pacman -Qqe > packages/pkglist.txt
# AUR packages
pacman -Qqm > packages/aurlist.txt

fc-list > fonts_list.txt

echo -e "\e[34mBackup complete → $BACKUP_DIR\e[0m"

# Optional Git commit/push
read -rp "Do you want to commit and push to Git? (y/n) " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "\e[31mNot a git repository. Skipping git operations.\e[0m"
    exit 1
  fi

  read -rp "Enter commit message: " commit_msg
  git add "$BACKUP_DIR"
  git commit -m "$commit_msg"
  git push && echo -e "\e[32mChanges pushed!\e[0m" || \
    echo -e "\e[31mGit push failed; pull/rebase and try again.\e[0m"
else
  echo -e "\e[33mSkipping git push.\e[0m"
fi
