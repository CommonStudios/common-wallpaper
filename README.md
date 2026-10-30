# Common Wallpaper

The animated *cloud sea* artwork from [commonstudios.dk](https://commonstudios.dk) as a live macOS desktop wallpaper.

A small Swift app puts a borderless window behind the desktop icons on every display and draws the piece in it with WebGL at 15 fps.
It refits itself when displays are added or removed, or change resolution or pixel density.

## Install

```sh
./install.sh
```

This builds the app (needs the Xcode command line tools for `swiftc`), installs it to `~/Applications/CommonWallpaper.app`, and registers a launch agent so it starts at every login.
Run `./install.sh` again after changing the source.

To remove it:

```sh
./uninstall.sh
```

## How it works

The artwork itself is the `cloud-sea` piece from [ascii.rest](https://ascii.rest), loaded at startup from `https://ascii.rest/pieces/cloud-sea.js`, so the app needs a network connection when it starts.
Each frame the piece computes a 200×100 grid of dots and colours; the app uploads that grid as a small texture and draws it in a single WebGL pass, with the edge fade done in the shader.
This uses about half the CPU of the stock canvas renderer, which issues one draw call per cell.

`./measure.sh` restarts the wallpaper and reports its average CPU and memory over 30 seconds.

## Credits

The cloud sea piece and the ascii.rest library are by [bas3line](https://github.com/bas3line), MIT licensed.
