# mpvSockets
By default this script will create one socket per mpv instance (with the
instance's process **ID** (PID), (**unique**)), instead of one socket for the
last started instance.

Dangling sockets for crashed or killed instances is an issue, not sure if this
script should handle/remove them or the clients/users, or both.

## Adding flexibility
Having one socket per instance is very convenient, especially if you use
something like these [mpv-socket](https://github.com/johndovern/mpv-sockets)
scripts to communicate with a given instances of mpv. However, sometimes it is
even better to have a socket or two that are dedicated to one thing.

[umpv](https://github.com/mpv-player/mpv/blob/master/TOOLS/umpv) is an example
of when having a dedicated socket can be very useful. You can read more about
it's advantages [here](umpv). Previously mpvSockets was totally
incompatible with umpv. This is no longer the case.

Another example is a headless mpv socket for music or podcasts. Having a
dedicated socket for music allows for easy communication and adding additional
songs or podcasts to the running socket. This is also possible with this
version of mpvSockets.

## What's the same?
This is a fork of wis/mpvSockets so lets cover what is the same. At face value
everything. This script does not change the default behavior of wis' original
script. I only wish to add a bit of flexibility for users who are interested.

## What's different?
The primary difference is the addition of script options and scanning for
environment variables. Script options allow users to easily change the behavior
of this script when launching mpv or to change it's default behavior outright.

Depending on the given option mpvSockets can run in 4 ways:

  1. Create unique sockets for every instance (default)
  2. Create a socket for umpv
  3. Create a socket for music
  4. Do nothing

By using `mpvSockets`.conf (placed in `~/.config/mpv/script-opts` or
equivalent) you can configure the default behavior using the following
settings.

### Script-opts
Supported script options and their default value
```
enabled=yes
pid=yes
umpv=no
music=no
```

#### `enabled`
Use `--script-opts=mpvSockets-enabled=no` to disable this script. You can set `enabled=no` in mpvSockets.conf to disable this script by default. If you do this you must pass `--script-opts=mpvSockets-enabled=yes,mpvSockets-umpv=yes` to enable the script and then to tell the script to create a umpv socket.

#### `pid`
If your mpvSockets.conf is set to the default values you can use
`--script-opts=mpvSockets-pid=no` to disable this script and create no
socket for an instance of mpv. Setting `pid=no` in mpvSockets.conf is
akin to setting `enabled=no` but without the hassle of passing two
script-opts arguments when you want to enable this script. For that
reason you should probably leave `enabled=yes` and only set `pid=no` if
you want to disable this script by default.

#### `umpv`
Use `--script-opts=mpvSockets-umpv=yes` to create a socket at `$MPV_UMPV_SOCKET`
by default or at `$SocketDir/mpvSockets/umpv_socket`. Read more about
[environment variables](#environment-variables) below.

#### `music`
Use `--script-opts=mpvSockets-music=yes` to create a socket at
`$MPV_MUSIC_SOCKET` by default or at `$SocketDir/mpvSockets/music_socket`.
Read more about [environment variables](#environment-variables) below.

#### Note for changing default behavior
As far as I am aware mpv does not natively support single instance mode.
For this reason it is not advisable to set either `music` or `umpv` to
`yes` in mpvSockets.conf. You should only change `pid` or `enabled` from
`yes` to `no` if you only want this script to take effect when explicitly
enabled from the command line.

### Environment-Variables
I have updated this script to make use of the following environment variables

#### `$MPV_SOCKET_DIR`
This should be set to some directory that you have permission to write
to. If it is not found it will be set to `$SocketDir/mpvSockets` where
`$SocketDir` is the output of the function `get_temp_path`. On my system
that is /tmp but it may be different on yours.

#### `$MPV_UMPV_SOCKET` & `$MPV_MUSIC_SOCKET`
These should be set as a full path to the desired socket. Something like:

  `/home/name/.tmp/umpv_socket`

or

  `/home/name/.tmp/music_socket`

The parent directory of the socket should actually exists and you need to
have read and write access to the directory.

If this variable is set the script will not necessarily create the parent
directory for you. For best compatibility the parent directory should be set to
the same thing as `$MPV_SOCKET_DIR` or it's default. This will ensure that the
directory is created and available as this script always creates a default
socket directory.

If the necessary environment variable is not set the default location
will be set to

  `$MPV_SOCKET_DIR/umpv_socket`

or

  `$MPV_SOCKET_DIR/music_socket`

Refer to the entry above if `$MPV_SOCKET_DIR` is unset.

## Usage with umpv
If you are unfamiliar with umpv you can check out the original or an
alternative at one of these locations:

  - [the original version](https://github.com/mpv-player/mpv/blob/master/TOOLS/umpv)
  - [modified original](umpv/python/umpv) compatible with mpvSockets
  - [one written in sh](umpv/sh/umpv) compatible with mpvSockets

I think the original explains what umpv does best:

```
This script emulates "unique application" functionality on Linux. When
starting playback with this script, it will try to reuse an already
running instance of mpv (but only if that was started with umpv). Other
mpv instances (not started by umpv) are ignored, and the script doesn't
know about them.
```

This is something that is totally incompatible with the original version
of mpvSockets. However, with the added script-opts umpv and mpvSockets
can work together very nicely.

### umpv tl;dr
You should be able to use the modified version of the original located
[here](umpv/python/umpv). Please see the installation instructions
[here](umpv/README.md#Installation) if you need them. Unless you have
`$MPV_UMPV_SOCKET` set as an environment variable this should just work
with mpvSockets out of the box.

If you have any issues please read the [README.md](umpv#readme) in the umpv directory as
it covers a lot of information about necessary changes made to the original
umpv script; as well as, information on an alternative written in sh.

## Usage with mpv-music
mpv-music as an idea is basically everything that umpv is but
__**without**__ a window/terminal. Headless mpv essentially. Couple that
with [some bash scripts](https://github.com/johndovern/mpv-sockets) and
you've got a nice little music player.

The [mpv-music](mpv-music) directory provides two scripts the same way
that the umpv directory does. One written in python and one written in
sh. Please refer to the [README.md](mpv-music#readme) there for more
information as well as usage.

# Installation
## Linux
Download mpvSockets.lua and place it in $HOME/.config/mpv/scripts

``` bash
$mpv_scripts="$HOME/.config/mpv/scripts"
curl -JL "https://github.com/johndovern/mpvSockets/raw/master/mpvSockets.lua" --create-dirs -o "$mpv_scripts/mpvSockets.lua"
```

Refer to the above for usage with with umpv etc.

## Note - this is not meant for windows
Windows and pipes don't go together so unless there is some workaround that I
am unaware of most of the added functionality and flexibility that this script
provides does nothing for windows users.

Please correct me if this changes.

# Usage, with Mpv's [JSON IPC](https://github.com/mpv-player/mpv/blob/master/DOCS/man/ipc.rst)
## Linux / unixes (unix sockets):
a script that pauses all running mpv instances:
bash:
``` bash
#!/bin/bash
for i in $(ls /tmp/mpvSockets/*); do
	echo '{ "command": ["set_property", "pause", true] }' | socat - "$i";
done
# Socat is a command line based utility that establishes two bidirec-tional
# byte streams and transfers data between them.
# available on Linux and FreeBSD, propably most unixes. you can also use
```
