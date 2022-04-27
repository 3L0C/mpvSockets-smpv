# mpv-music
The important differences between umpv and mpv-music is the script-opts
command, and the socket that is being used. While these scripts will run mpv in
a headless state, simply removing the `--no-terminal` flag will give you a
window to click on and a way to interact with mpv graphically.

If you wish to run mpv-music without a window your best means of interacting
with mpv will be the collection of scripts linked above. They provide a
`--music` flag which allows you to run `mpv-toggle --music` and pause
mpv-music. Please see the [README.md]() in mpv-music directory of this repo for
more information.
