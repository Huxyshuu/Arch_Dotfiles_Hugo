#!/bin/bash

if [[ "$1" == "click" ]]; then
  # Toggle input method on click
  fcitx5-remote -t
  exit 0
fi

# Explicitly using full path
if /usr/bin/fcitx5-remote | grep -q 2; then
    echo "JP"
else
    echo "FI"
fi
