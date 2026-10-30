#!/bin/zsh
# Build the wallpaper, install it to ~/Applications, and start it now and at every login.
set -e
cd "${0:A:h}"
app=~/Applications/CommonWallpaper.app
agent=~/Library/LaunchAgents/local.common.wallpaper.plist

swiftc -O Wallpaper.swift -o CommonWallpaper
launchctl bootout gui/$(id -u)/local.common.wallpaper 2>/dev/null || true
pkill -x CommonWallpaper || true
rm -rf $app
mkdir -p $app/Contents/MacOS ~/Library/LaunchAgents
cp Info.plist $app/Contents/
mv CommonWallpaper $app/Contents/MacOS/

cat > $agent <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>local.common.wallpaper</string>
  <key>ProgramArguments</key><array><string>$app/Contents/MacOS/CommonWallpaper</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>Crashed</key><true/></dict>
  <key>ProcessType</key><string>Interactive</string>
</dict></plist>
PLIST
launchctl bootstrap gui/$(id -u) $agent
echo "Installed $app and started it; it will also start at login."
