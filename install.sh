#!/bin/bash

########################
# This script restores system and configuration files 
# from the latest backup folder.
########################

set -e

# === Settings ===
REPO_DIR="$HOME/dotfiles"          # Path where your repo is cloned
BACKUP_PARENT="$REPO_DIR"          # Folder containing backups
BRANCH="main"                      # Git branch to pull
LATEST_BACKUP_DIR=""               # Will be set dynamically

# === Pull latest version ===
echo -e "\e[34mPulling latest dotfiles from GitHub...\e[0m"

if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo -e "\e[31mError: $REPO_DIR is not a git repository.\e[0m"
  echo "Please clone your dotfiles repo first, e.g.:"
  echo "  git clone <your_repo_url> \"$REPO_DIR\""
  exit 1
fi

cd "$REPO_DIR"
git fetch origin "$BRANCH"
git checkout "$BRANCH"
git pull origin "$BRANCH"

echo -e "\e[32m✔ Repo updated successfully.\e[0m"

# === Locate latest backup folder ===
LATEST_BACKUP_DIR=$(ls -dt "$BACKUP_PARENT"/backup_* 2>/dev/null | head -n 1)

if [[ -z "$LATEST_BACKUP_DIR" ]]; then
  echo -e "\e[31mError: No backup_* folders found in $BACKUP_PARENT.\e[0m"
  exit 1
fi

echo -e "\e[34mUsing latest backup folder: \e[0m$LATEST_BACKUP_DIR"

# === Confirm before proceeding ===
echo
read -rp "This will overwrite existing system and config files. Continue? (y/n) " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo -e "\e[33mRestore aborted.\e[0m"
  exit 0
fi

# === Restore using rsync ===
echo -e "\e[34mRestoring files... this may take a moment.\e[0m"
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
