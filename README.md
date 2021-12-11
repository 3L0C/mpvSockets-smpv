# mpvSockets
create one sockets per mpv instance (with the instance's process **ID** (PID), (**unique**)), instead of one socket for the last started instance

dangling sockets for crashed or killed instances is an issue,
not sure if this script should handle/remove them or the clients/users, or both.

# -umpv
as described above mpvSockets was designed to create a socket for each unique instance of mpv
which is great...if you don't use [umpv](https://github.com/mpv-player/mpv/blob/master/TOOLS/umpv)
## The Issue
1. umpv starts and creates a socket at $HOME/.umpv_socket which it tells mpv to use
2. mpv is then started by umpv
3. all lua scripts get loaded
4. mpvSockets.lua says "lol no" and makes makes it so umpv is useless

*or at least it used to*
## tl;dr
[mpvSockets.lua now tests to see if umpv was used to launch mpv through a single if statement before it tries to create a new socket](https://github.com/johndovern/mpvSockets-umpv#installation)
## The solution
### [umpv](https://github.com/mpv-player/mpv/blob/master/TOOLS/umpv)
**forked and licensed under LGPLv2.1 (correct me if i am wrong) is a part of the offical mpv repo**

i have made slight modifications shown here
```bash
--- umpv-old    2021-12-10 13:40:14.554428588 -0800
+++ umpv-new    2021-12-10 13:41:35.881098073 -0800
@@ -52,7 +52,7 @@
     return filename
 files = (make_abs(f) for f in files)

-SOCK = os.path.join(os.getenv("HOME"), ".umpv_socket")
+SOCK = "/tmp/mpvSockets/umpv_socket"

 sock = None
 try:
@@ -79,7 +79,7 @@
     # Let mpv recreate socket if it doesn't already exist.

     opts = (os.getenv("MPV") or "mpv").split()
-    opts.extend(["--no-terminal", "--force-window", "--input-ipc-server=" + SOCK,
+    opts.extend(["--no-terminal", "--force-window", "--input-ipc-server=", "--x11-name=umpv" + SOCK,
                  "--"])
     opts.extend(files)
```
the first change makes [other scripts](https://github.com/johndovern/mpvSockets-umpv#usage-with-mpvs-json-ipc) compatible. there may be a better solution than setting this as a hardcoded path but i don't know python or programming in general so please suggest a better way that gets the same result if you have one

the second change is actually what enables us to solve this issue.

`"--x11-name=umpv"`

will set the WM_CLASS value of the opened window to:

`WM_CLASS(STRING) = "umpv", "mpv"`

without this the changes made in mpvSockets.lua will not work. **either make this change to umpv yourself or replace your old version with the one in this repo.**
### mpvSockets.lua
mpvSockets.lua has been modified as follows
```bash
--- mpvSockets-old.lua      2021-12-10 13:35:18.571085019 -0800
+++ mpvSockets-new.lua 2021-12-10 13:35:34.534418903 -0800
@@ -27,10 +27,26 @@
 end

 ppid = utils.getpid()
-os.execute("mkdir " .. join_paths(tempDir, "mpvSockets") .. " 2>/dev/null")
-mp.set_property("options/input-ipc-server", join_paths(tempDir, "mpvSockets", ppid))
+
+function socket_later()
+    if os.execute("xdotool search -pid '"..ppid.."' | xargs -I '{}' xprop -id '{}' | grep umpv") then
+        --nothing to do if true, as umpv has already created the socket
+       --comment out next line if you don't want confirmation
+        mp.osd_message("umpv detected")
+    else
+        mp.set_property("options/input-ipc-server", join_paths(tempDir, "mpvSockets", ppid))
+        os.execute("mkdir " .. join_paths(tempDir, "mpvSockets") .. " 2>/dev/null")
+    end
+end
+
+mp.register_event("file-loaded", socket_later)

 function shutdown_handler()
+    if os.execute("xdotool search -pid '"..ppid.."' | xargs -I '{}' xprop -id '{}' | grep umpv") then
+        os.remove(join_paths(tempDir, "mpvSockets/umpv_socket"))
+    else
         os.remove(join_paths(tempDir, "mpvSockets", ppid))
+    end
 end
+
 mp.register_event("shutdown", shutdown_handler)
```
there are two important changes
1. mpvSockets.lua checks to see if umpv was used to launch mpv
2. mpvSockets.lua does not do anything until your file is loaded
#### umpv checking
```bash
+    if os.execute("xdotool search -pid '"..ppid.."' | xargs -I '{}' xprop -id '{}' | grep umpv") then
```
**this command uses [xdotool](https://github.com/jordansissel/xdotool), if you do not have it installed this script will be useless**
```bash
xdotool search -pid '"..pid.."'
```
the first part uses xdotool's search function and returns the window id of the ppid entered
```bash
| xargs -I '{}' xprop -id '{}'
```
that window id is piped, effectively, to xprop. xprop does not take stdout so it has to be run through xargs first and then given to xprop. xprop gives us a lot of useful info
```bash
| grep umpv
```
finally grep searches through all that info for what we care about, the WM_CLASS value. if mpv was launched through umpv, this value will look like this
```bash
WM_CLASS(STRING) = "umpv", "mpv"
```
if not, it will fail and mpvSockets.lua will work as it normally does and create a unique socket for that ppid.
#### Waiting for file to load
the above if statement will not work if it is run at launch. this is because mpv does not have a window id yet as it is only running as a process and needs time to create a window (espceially with umpv, idk why it take so long for the window to actually open...). this causes `xdotool search -pid $ppid` to fail no matter what. the if statement will always return false and it effectively becomes garbage. however, we can solve this by putting these commands in a fucntion and running that function when the file is loaded, like so:
```bash
+mp.register_event("file-loaded", socket_later)
```
the if statement will not be run until the file is loaded. if the file is loaded we most certainly have a window id which solves the aforementioned problem and everything [just werks](https://github.com/johndovern/mpvSockets-umpv#umpv)
#### Niceties
i've also added the following
```bash
 function shutdown_handler()
+    if os.execute("xdotool search -pid '"..ppid.."' | xargs -I '{}' xprop -id '{}' | grep umpv") then
+        os.remove(join_paths(tempDir, "mpvSockets/umpv_socket"))
+    else
         os.remove(join_paths(tempDir, "mpvSockets", ppid))
+    end
 end
```
this basically does the same thing as before, checks to see if the window was created by umpv or mpv. if it was umpv then we remove /tmp/mpv/Sockets/umpv_socket. sometimes having that socket lying around has caused issues for me. if i have no umpv window open currently but did previously and that socket is still sitting there, then umpv will *sometimes* pipe that video to that socket which leads nowhere meaning no video ever opens. however, if we remove that socket each time we close a umpv window this problem disapears. this part removes either umpv_socket or the ppid socket depending on the WM_CLASS value.
```bash
+        mp.osd_message("umpv detected")
```
this line was useful for debugging. i am including it as i think it is the easiest way to let a user know of this script is working or not. if you launch a video through umpv but don't see this message when the file loads then something went wrong. if this script is broken for you please open an issue, i would like to make this as fool proof as possible. if you don't want this message popping up feel free to delete line 35 and you'll no longer see this message.
# Installation
## Linux
1. download mpvSockets.lua and place it in $HOME/.config/mpv/scripts
``` bash
curl "https://raw.githubusercontent.com/johndovern/mpvSockets/master/mpvSockets.lua" --create-dirs -o "$Your_Mpv_Scripts_Directory_Location/mpvSockets.lua"
```
if you're on Linux, most likely the location is `~/.config/mpv/scripts`, so run this before:
``` bash
$Your_Mpv_Scripts_Directory_Location=$HOME/config/mpv/scripts
```
2. install [xdotool](https://github.com/jordansissel/xdotool) if you do not have it installed already
3. download umpv from this repo and place it in your $PATH [*or modify your existing version*](https://github.com/johndovern/mpvSockets-umpv#umpv)
```bash
curl -O "https://raw.githubusercontent.com/johndovern/mpvSockets-umpv/master/umpv"
```
and that's it...[kinda]( https://github.com/johndovern/mpvSockets-umpv#umpv)
## Note - this is not meant for windows

but then again windows users can't even use umpv so that sort of goes without saying
## disclaimers
* right now if the directory `/tmp/mpvSockets` does not exist then videos launched through umpv, will not have a socket, full stop. if mpv is launched on it's own then this script will create that directory, but (at least in my testing) no socket will actually be created, only the directory, which is somewhat odd to me. so as long as you launch mpv at least once then everything will work fine after that. as far as i can tell this is the only major issue currently present due to my modifications.
* as i mentioned above i do not think that hardcoding umpv to use `/tmp/mpvSockets/umpv_socket` is standard or the best way to do this. any better suggestions are happliy welcome.
* i am not a programer, i just found a way to have my cake and eat it to. if you have a better way of solving this issue then please share it with me.
# Usage, with Mpv's [JSON IPC](https://github.com/mpv-player/mpv/blob/master/DOCS/man/ipc.rst)
## Linux / unixes (unix sockets):
a script that pauses all running mpv instances:
bash:
``` bash
#!/bin/bash
for i in $(ls /tmp/mpvSockets/*); do
	echo '{ "command": ["set_property", "pause", true] }' | socat - "$i";
done
# Socat  is  a  command  line based utility that establishes two bidirec-tional byte streams  and	 transfers  data  between  them.
# available on Linux and FreeBSD, propably most unixes. you can also use
```
