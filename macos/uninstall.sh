#!/bin/zsh
# Stop the wallpaper and remove the app and its login item.
launchctl bootout gui/$(id -u)/local.common.wallpaper 2>/dev/null
pkill -x CommonWallpaper
rm -rf ~/Applications/CommonWallpaper.app ~/Library/LaunchAgents/local.common.wallpaper.plist
echo "Removed."
