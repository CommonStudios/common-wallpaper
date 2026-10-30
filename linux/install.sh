#!/bin/sh
# Install the wallpaper to ~/.local/share/common-wallpaper, start it now, and at every login.
set -e
cd "$(dirname "$0")"
dir="$HOME/.local/share/common-wallpaper"
autostart="${XDG_CONFIG_HOME:-$HOME/.config}/autostart/common-wallpaper.desktop"

if ! python3 -c 'import cairo, gi; gi.require_version("Gtk", "3.0"); gi.require_version("WebKit2", "4.1")' 2>/dev/null; then
    echo "Needs Python GTK 3 and WebKitGTK. Install them first, e.g.:"
    echo "  Debian/Ubuntu: sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-webkit2-4.1 gir1.2-gtklayershell-0.1"
    echo "  Fedora:        sudo dnf install python3-gobject python3-cairo gtk3 webkit2gtk4.1 gtk-layer-shell"
    echo "  Arch:          sudo pacman -S python-gobject python-cairo gtk3 webkit2gtk-4.1 gtk-layer-shell"
    exit 1
fi

pkill -f common-wallpaper/wallpaper.py || true
mkdir -p "$dir" "$(dirname "$autostart")"
cp wallpaper.py ../wallpaper.html "$dir/"
cat > "$autostart" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Common Wallpaper
Comment=The commonstudios.dk cloud sea as a live wallpaper
Exec=python3 $dir/wallpaper.py
X-GNOME-Autostart-enabled=true
NoDisplay=true
DESKTOP
nohup python3 "$dir/wallpaper.py" >/dev/null 2>&1 &
echo "Installed to $dir and started it; it will also start at login."
