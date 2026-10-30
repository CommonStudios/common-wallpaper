#!/bin/sh
# Stop the wallpaper and remove it and its autostart entry.
pkill -f common-wallpaper/wallpaper.py
rm -rf "$HOME/.local/share/common-wallpaper" "${XDG_CONFIG_HOME:-$HOME/.config}/autostart/common-wallpaper.desktop"
echo "Removed."
