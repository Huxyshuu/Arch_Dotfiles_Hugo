#!/bin/bash

# .config folders
CONFIG_FOLDERS=(
    "$HOME/.config/fastfetch"
    "$HOME/.config/hypr"
    "$HOME/.config/kitty"
    "$HOME/.config/rofi"
    "$HOME/.config/waybar"
    "$HOME/.config/wlogout"
    "$HOME/.config/eww"
)
CONFIG_TARGET="./.config"

mkdir -p "$CONFIG_TARGET"

for SRC in "${CONFIG_FOLDERS[@]}"; do
  if [[ -e "$SRC" ]]; then
    echo -e "\e[32mCopying $SRC to $CONFIG_TARGET\e[0m"
    if [[ -d "$SRC" ]]; then
      cp -r "$SRC" "$CONFIG_TARGET/"
    else
      cp "$SRC" "$CONFIG_TARGET/"
    fi
  else
    echo -e "\e[31mSkipping $SRC — folder/file does not exist.\e[0m"
  fi
done

# home files/folders
HOME_ITEMS=(
    "$HOME/.bashrc"
)
TARGET="."

mkdir -p "$TARGET"

for SRC in "${HOME_ITEMS[@]}"; do
  if [[ -e "$SRC" ]]; then
    echo -e "\e[32mCopying $SRC to $TARGET\e[0m"
    if [[ -d "$SRC" ]]; then
      cp -r "$SRC" "$TARGET/"
    else
      cp "$SRC" "$TARGET/"
    fi
  else
    echo -e "\e[31mSkipping $SRC — folder/file does not exist.\e[0m"
  fi
done

echo -e "\e[34mDone copying!\e[0m"

# Ask user if they want to commit and push to git
read -rp "Do you want to commit and push changes to Git? (y/n) " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  read -rp "Enter your commit message: " commit_msg

  # Add all changes
  git add .

  # Commit with the message
  git commit -m "$commit_msg"

  # Push to the current branch
  git push
  PUSH_EXIT_CODE=$?

  if [[ $PUSH_EXIT_CODE -eq 0 ]]; then
    echo -e "\e[32mChanges pushed to Git successfully.\e[0m"
  else
    echo -e "\e[31mGit push failed! You might need to pull and merge first.\e[0m"
    echo -e "\e[33mTry running: git pull --rebase and resolve conflicts before pushing again.\e[0m"
  fi
else
  echo -e "\e[33mSkipping git commit and push.\e[0m"
fi
