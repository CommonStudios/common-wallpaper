# Common Wallpaper

The animated *cloud sea* artwork from [commonstudios.dk](https://commonstudios.dk) as a live desktop wallpaper for macOS, Windows and Linux.

On every platform a small app puts a window behind the desktop icons on each display and shows [`wallpaper.html`](wallpaper.html) in it, which draws the piece with WebGL at 15 fps.
The windows refit themselves when displays are added or removed, or change resolution or scaling.
Each installer also makes the wallpaper start at login.

## macOS

Needs the Xcode command line tools (`xcode-select --install`).

```sh
./macos/install.sh     # builds, installs to ~/Applications, starts it now and at login
./macos/uninstall.sh
```

`./macos/measure.sh` restarts the wallpaper and reports its average CPU and memory over 30 seconds.

## Windows

Needs the [.NET 8 SDK](https://dotnet.microsoft.com/download) (`winget install Microsoft.DotNet.SDK.8`) to build, and the WebView2 runtime, which Windows 10 and 11 include. In PowerShell:

```powershell
.\windows\install.ps1     # builds, installs to %LOCALAPPDATA%\CommonWallpaper, starts it now and at login
.\windows\uninstall.ps1
```

If PowerShell refuses to run scripts, run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` first.

## Linux

Needs Python GTK 3 and WebKitGTK:

```sh
sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-webkit2-4.1 gir1.2-gtklayershell-0.1   # Debian, Ubuntu
sudo dnf install python3-gobject python3-cairo gtk3 webkit2gtk4.1 gtk-layer-shell                      # Fedora
sudo pacman -S python-gobject python-cairo gtk3 webkit2gtk-4.1 gtk-layer-shell                         # Arch

./linux/install.sh     # installs to ~/.local/share/common-wallpaper, starts it now and at login
./linux/uninstall.sh
```

- **X11:** works with any desktop that respects desktop-type windows.
- **Wayland on KDE Plasma, Sway, Hyprland and other wlroots compositors:** uses the layer-shell protocol (`gtk-layer-shell`) to sit in the background layer.
- **Wayland on GNOME:** GNOME gives apps no way to draw the desktop, so the wallpaper runs through XWayland as a desktop window instead.
  Whether it then stays behind your windows and icons depends on the GNOME version and extensions; if it doesn't, log in to a GNOME on Xorg session.

## How it works

The artwork itself is the `cloud-sea` piece from [ascii.rest](https://ascii.rest), loaded at startup from `https://ascii.rest/pieces/cloud-sea.js`, so the wallpaper needs a network connection when it starts.
Each frame the piece computes a 200×100 grid of dots and colours; `wallpaper.html` uploads that grid as a small texture and draws it in a single WebGL pass, with the edge fade done in the shader.
This uses about half the CPU of the stock canvas renderer, which issues one draw call per cell.

| Platform | App | Behind the icons by |
| --- | --- | --- |
| macOS | Swift, WKWebView ([`macos/Wallpaper.swift`](macos/Wallpaper.swift)) | a window at the desktop window level |
| Windows | C#, WebView2 ([`windows/Program.cs`](windows/Program.cs)) | parenting into Explorer's WorkerW, or Progman on Windows 11 24H2 and later |
| Linux | Python, WebKitGTK ([`linux/wallpaper.py`](linux/wallpaper.py)) | a desktop-type window on X11, the background layer on Wayland |

## Credits

The cloud sea piece and the ascii.rest library are by [bas3line](https://github.com/bas3line), MIT licensed.
