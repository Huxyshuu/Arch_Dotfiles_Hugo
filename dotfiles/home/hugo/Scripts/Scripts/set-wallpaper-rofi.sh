#!/bin/bash

# Directory containing wallpapers
wallpaper_dir="$HOME/Wallpapers"

# List all image files (jpg/png) in wallpaper_dir
wallpapers=$(find "$wallpaper_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" \) | sort)

# Use rofi to pick one
image=$(echo "$wallpapers" | rofi -dmenu -i -p "Select wallpaper:")

# If nothing selected, exit
[ -z "$image" ] && exit 1

# Write hyprpaper config
cat <<EOF > "$HOME/.config/hypr/hyprpaper.conf"
preload = $image
wallpaper = ,$image
EOF

# Restart hyprpaper to apply new wallpaper
killall hyprpaper
sleep 0.1
hyprpaper &

echo "Wallpaper set to $image"
