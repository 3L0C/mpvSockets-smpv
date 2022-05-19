# mpv-music
The important differences between umpv and mpv-music is the script-opts
command, and the socket that is being used. While these scripts will run mpv in
a headless state, simply removing the `--no-terminal` flag will give you a
window to click on and a way to interact with mpv graphically.

If you wish to run mpv-music without a window [this](https://github.com/johndovern/mpv-sockets) collection of bash scripts make interaction with the mpv_music socket much easier. See the README.md of the linked repo for more information.

# Installation
## mpv-music in python

```bash
curl -LJO "https://github.com/johndovern/mpvSockets/raw/master/mpv-music/python/mpv-music" && chmod a+x mpv-music
echo "$PATH"
# Place in desired directory
```

## mpv-music in sh

```bash
curl -LJO "https://github.com/johndovern/mpvSockets/raw/master/mpv-music/sh/mpv-music" && chmod a+x mpv-music
echo "$PATH"
# Place in desired directory
```

You will also need [socat](http://www.dest-unreach.org/socat/) installed.

```
# For Arch
sudo pacman -Sy socat

# For Ubuntu and Debian
sudo apt-get install -y socat
```

## Usage

```bash
mpv-music "song.ogg" "url playlist" ...
```
