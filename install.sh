#!/bin/bash
########################
# Restore system from latest backup repo
# Installs packages and copies dotfiles to correct places
########################

set -e

# === Settings ===
REPO_URL="https://github.com/Huxyshuu/Arch_Dotfiles_Hugo"
REPO_DIR="$HOME/Arch_Dotfiles_Hugo"  # Where the repo will be cloned
BRANCH="main"
LATEST_BACKUP_DIR=""

# === Clone or update repo ===
if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo -e "\e[34mCloning dotfiles repo...\e[0m"
  git clone -b "$BRANCH" "$REPO_URL" "$REPO_DIR"
else
  echo -e "\e[34mUpdating existing repo...\e[0m"
  cd "$REPO_DIR"
  git fetch origin "$BRANCH"
  git checkout "$BRANCH"
  git pull origin "$BRANCH"
fi

echo -e "\e[32m✔ Repo ready at $REPO_DIR\e[0m"

# === Locate latest backup folder ===
LATEST_BACKUP_DIR=$(ls -dt "$REPO_DIR"/backup_* 2>/dev/null | head -n 1)

if [[ -z "$LATEST_BACKUP_DIR" ]]; then
  echo -e "\e[31mError: No backup_* folders found in $REPO_DIR.\e[0m"
  exit 1
fi

echo -e "\e[34mUsing latest backup folder: $LATEST_BACKUP_DIR\e[0m"

# === Confirm before proceeding ===
echo
read -rp "This will overwrite existing system and config files. Continue? (y/n) " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo -e "\e[33mRestore aborted.\e[0m"
  exit 0
fi

# === Install official packages ===
PKGFILE="$LATEST_BACKUP_DIR/packages/pkglist.txt"
if [[ -f "$PKGFILE" ]]; then
  echo -e "\e[34mInstalling official repository packages...\e[0m"
  sudo pacman -Syu --needed - < "$PKGFILE"
else
  echo -e "\e[33mNo official package list found at $PKGFILE\e[0m"
fi

# === Install AUR packages ===
AURFILE="$LATEST_BACKUP_DIR/packages/aurlist.txt"
if [[ -f "$AURFILE" ]]; then
  echo -e "\e[34mInstalling AUR packages...\e[0m"
  # Using paru; change to yay if needed
  paru -S --needed - < "$AURFILE"
else
  echo -e "\e[33mNo AUR package list found at $AURFILE\e[0m"
fi

# === Restore configs and dotfiles using rsync ===
echo -e "\e[34mRestoring system and config files...\e[0m"
sudo rsync -avh --progress "$LATEST_BACKUP_DIR"/ /

echo -e "\e[32m✔ Restore complete!\e[0m"

# === Optional post-restore actions ===
echo
read -rp "Would you like to reboot now to apply all changes? (y/n) " reboot_ans
if [[ "$reboot_ans" =~ ^[Yy]$ ]]; then
  sudo reboot
else
  echo -e "\e[33mReboot later to apply all settings.\e[0m"
fi
