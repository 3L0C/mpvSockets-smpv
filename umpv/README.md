# umpv
[umpv](https://github.com/mpv-player/mpv/blob/master/TOOLS/umpv) is a python script that exists in the official mpv repo.

## What does it do?
Quoting from the original script

```
This script emulates "unique application" functionality on Linux. When starting
playback with this script, it will try to reuse an already running instance of
mpv (but only if that was started with umpv). Other mpv instances (not started
by umpv) are ignored, and the script doesn't know about them.
```

Essentialy if an instance of mpv is started with this script your file will
be opened in an instance of mpv that was started using umpv. If no such instance
exists a new one will be created along with a socket that umpv will make use of.

## Why use it?
The main advantage of umpv is that new instances of mpv are not spawned
whenever you give it a file. Instead files get added to the playlist of a umpv
instance. If you use an extension like
[Open With](https://github.com/darktrojan/openwith) or
[open-with-mpv](https://github.com/slothspot/open-with-mpv) or even
[tridactly](https://github.com/tridactyl/tridactyl) you can easily open or add
files to an instance of mpv attached to the umpv_socket.

There are some other benefits as well that mostly come into play if you use something similar to [these](https://github.com/johndovern/mpv-sockets) bash scripts to interact with mpv via it's socket.

## mpvSockets compatibility with original umpv
This version of mpvSockets is not compatible with the original version of
umpv. If you are using the original version found in the official mpv repo
you will either need to make the following changes yourself or use the modified
version found in [here](umpv).

## umpv written in python
### Changing the original
These are the necessary changes made to the original.

```python
--- umpv-original       2022-04-24 18:49:01.254653000 -0700
+++ umpv-modified       2022-04-24 19:38:14.888874800 -0700
@@ -32,6 +32,7 @@
 import errno
 import subprocess
 import string
+import tempfile

 files = sys.argv[1:]

@@ -52,7 +53,9 @@
     return filename
 files = (make_abs(f) for f in files)

-SOCK = os.path.join(os.getenv("HOME"), ".umpv_socket")
+# SOCK = os.getenv("MPV_UMPV_SOCKET")
+SOCK = os.path.join(tempfile.gettempdir(), "mpvSockets/umpv_socket")
+# SOCK = "/tmp/mpvSockets/umpv_socket"

 sock = None
 try:
```

The original umpv script sets the default socket to `$HOME/.umpv_socket` which
is not the default for mpvSockets. However, we can get your temp dir with the
tempfile module and join that with the default path `mpvSockets/umpv_socket`.
This should be the same location that mpvSockets uses if you do not have
`$MPV_SOCKET_DIR` or `$MPV_UMPV_SOCKET` set. If this is not the case please
open an issue as I would like to see what's going wrong.

If you have the `$MPV_UMPV_SOCKET` environment variable set you can set SOCK to
that value. This is the most compatible option between umpv and mpvSockets. If
Neither of these settings is working, then just hard code SOCK to the same
location that mpvSockets is trying to use.

```python
@@ -79,7 +82,8 @@
     # Let mpv recreate socket if it doesn't already exist.

     opts = (os.getenv("MPV") or "mpv").split()
-    opts.extend(["--no-terminal", "--force-window", "--input-ipc-server=" + SOCK,
+    opts.extend(["--script-opts=mpvSockets-umpv=yes", "--no-terminal", "--force-window",
+    # opts.extend(["--script-opts=mpvSockets-enabled=no", "--no-terminal", "--force-window", "--input-ipc-server=" + SOCK,
                  "--"])
     opts.extend(files)
```

The original umpv script created an input-ipc-server for us. However, this is
not necessary when passing `--script-opts=mpvSockets-umpv=yes` as mpvSockets
will create this socket. If you prefer to have umpv create the socket you can
use the commented out command which creates a socket and tells mpvSockets to
ignore this instance.

There is a modified version of umpv in this repo which is configured with the
changes shown above. It also includes the commented out alternative ways of
using this script in order of greatest compatibility between umpv and
mpvSockets.

## umpv written in sh
### Added feature
I often leave my umpv instance floating around after a file has finished
playing. Using the python version if I were to add a file to this open instance
I would have to manually go and unpause mpv to get it to play the next file. A
minor grievance I know, but the sh version checks for this and takes care of
it for me. If umpv is open and has reached the end of the last file in the
playlist it will add the given files(s) to the playlist and then check if the
end of the current file has been reached. If it has it will send a signal to
mpv to go to the next file and also unpause mpv.

### Some notes
While both scripts are designed to work with mpvSockets there are some points
to note.

- You can only pass files and urls as arguments to both versions of umpv found
here. Both versions take multiple files or urls as arguments.

- Neither version creates a socket. That job is left to mpvSockets. However, to
add files to an instance of mpv we must know what socket it is connected to.
The sh version defaults to using all the same environment variables that
mpvSockets also attempts to use. If you have these unset the assumed location
for umpv's socket will be in `/tmp/mpvSockets/umpv_socket` . You can either edit the
SOCKET variable within the script, or export your desired location via the
`$MPV_UMPV_SOCKET` variable by adding it to your `.zprofile` or `.bashrc` or
whatever you use.

- I'm not certain but I believe the python version is 100% independent of
external programs. That is not the case for the sh version. The sh version
requires you to have [socat](http://www.dest-unreach.org/socat/) installed. It
should be in your distro's repo.

- The arguments passed to mpv by the sh version are not the same as the python
version. These are the arguments passed by both scripts

```
# Python version
--no-terminal --force-window

# Bash version
--idle=yes --loop-playlist=no --keep-open=yes
```

I decided to only change what was absolutely necessary in the python version.
Both scripts pass the script-opts flag required to make them compatible with
mpvSockets but that is where the similarities end. The options passed in the
sh script are simply the options that I like for how I use umpv. Feel free to
change these in either script to your liking.

# Installation
## umpv in python

```bash
curl -LJO "https://github.com/johndovern/mpvSockets/raw/master/umpv/python/umpv" && chmod a+x umpv
echo "$PATH"
# Place in desired directory
```

## umpv in sh

```bash
curl -LJO "https://github.com/johndovern/mpvSockets/raw/master/umpv/sh/umpv" && chmod a+x umpv
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
umpv "video.mkv" "url" "img.png" ...
```

umpv will either start mpv and set the socket to `/tmp/mpvSockets/umpv_socket`
(the default if no environment variables are set) or if an instance is open and
attached to this socket, it will add the given files to that instance of mpv's
playlist.
