#!/usr/bin/env python3
"""The cloud sea wallpaper for Linux: wallpaper.html in a WebKitGTK window behind the desktop on every monitor.

On X11 each window is a _NET_WM_WINDOW_TYPE_DESKTOP window. On Wayland it needs gtk-layer-shell and a compositor
with the layer-shell protocol (KDE Plasma, Sway, Hyprland and other wlroots ones); GNOME on Wayland has no way for an
app to draw the desktop, so there it falls back to X11 through XWayland, where GNOME keeps desktop windows at the back.
"""
import os
import sys
from pathlib import Path

import cairo
import gi

# Pick the backend before Gtk is imported, which initialises it.
layer_shell = False
if os.environ.get("WAYLAND_DISPLAY") and "GNOME" not in os.environ.get("XDG_CURRENT_DESKTOP", "").upper():
    try:
        gi.require_version("GtkLayerShell", "0.1")
        layer_shell = True
    except ValueError:
        pass
if not layer_shell:
    # Without layer-shell a Wayland window can't sit behind the desktop, so run on XWayland instead.
    os.environ["GDK_BACKEND"] = "x11"

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
for version in ("4.1", "4.0"):
    try:
        gi.require_version("WebKit2", version)
        break
    except ValueError:
        continue
from gi.repository import Gdk, Gtk, WebKit2  # noqa: E402

GtkLayerShell = None
if layer_shell:
    from gi.repository import GtkLayerShell

HTML = (Path(__file__).resolve().parent / "wallpaper.html").read_text()
BASE = "https://commonstudios.dk/"
windows = []


def make_window(monitor):
    window = Gtk.Window()
    window.set_decorated(False)
    window.set_accept_focus(False)
    window.set_skip_taskbar_hint(True)
    window.set_skip_pager_hint(True)
    if GtkLayerShell:
        GtkLayerShell.init_for_window(window)
        GtkLayerShell.set_layer(window, GtkLayerShell.Layer.BACKGROUND)
        GtkLayerShell.set_monitor(window, monitor)
        GtkLayerShell.set_exclusive_zone(window, -1)
        GtkLayerShell.set_keyboard_interactivity(window, False)
        for edge in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM, GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT):
            GtkLayerShell.set_anchor(window, edge, True)
    else:
        window.set_type_hint(Gdk.WindowTypeHint.DESKTOP)
        window.set_keep_below(True)
        window.stick()
    settings = WebKit2.Settings(enable_webgl=True, hardware_acceleration_policy=WebKit2.HardwareAccelerationPolicy.ALWAYS)
    web = WebKit2.WebView(settings=settings)
    web.load_html(HTML, BASE)
    window.add(web)
    window.show_all()
    # Clicks go through to the desktop below.
    window.input_shape_combine_region(cairo.Region())
    return window


def fit(*_):
    """One window per monitor, each sized to its monitor; rerun whenever monitors change."""
    display = Gdk.Display.get_default()
    monitors = [display.get_monitor(i) for i in range(display.get_n_monitors())]
    while len(windows) > len(monitors):
        windows.pop().destroy()
    for i, monitor in enumerate(monitors):
        if i == len(windows):
            windows.append(make_window(monitor))
        window = windows[i]
        if GtkLayerShell:
            GtkLayerShell.set_monitor(window, monitor)
        else:
            area = monitor.get_geometry()
            window.move(area.x, area.y)
            window.resize(area.width, area.height)


def main():
    Gtk.init(sys.argv)
    display = Gdk.Display.get_default()
    display.connect("monitor-added", fit)
    display.connect("monitor-removed", fit)
    Gdk.Screen.get_default().connect("size-changed", fit)
    fit()
    Gtk.main()


if __name__ == "__main__":
    main()
