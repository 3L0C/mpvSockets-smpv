-- mpvSockets, one socket per instance, removes socket on exit
local mp = require 'mp'
local options = require 'mp.options'
local utils = require 'mp.utils'

local o = {
  enabled = "yes",
  pid     = "yes",
  music   = "no",
  umpv    = "no",
}
options.read_options(o, "mpvSockets")

local function get_temp_path()
    local directory_seperator = package.config:match("([^\n]*)\n?")
    local example_temp_file_path = os.tmpname()

    pcall(os.remove, example_temp_file_path)

    local seperator_idx = example_temp_file_path:reverse():find(directory_seperator)
    local temp_path_length = #example_temp_file_path - seperator_idx

    return example_temp_file_path:sub(1, temp_path_length)
end

local function join_paths(...)
    local arg={...}
    local path = ""
    for i,v in ipairs(arg) do
        path = utils.join_path(path, tostring(v))
    end
    return path;
end

local function set_vars()
    SocketDir = os.getenv("MPV_SOCKET_DIR")

    if not SocketDir then
        SocketDir = join_paths(get_temp_path(), "mpvSockets")
    end

    if o.umpv == "yes" then
        TheSocket = os.getenv("MPV_UMPV_SOCKET")
        if not TheSocket then
            TheSocket = join_paths(SocketDir, "umpv_socket")
        end
    elseif o.music == "yes" then
        TheSocket = os.getenv("MPV_MUSIC_SOCKET")
        if not TheSocket then
            TheSocket = join_paths(SocketDir, "music_socket")
        end
    elseif o.pid == "yes" then
        local ppid = utils.getpid()
        TheSocket = join_paths(SocketDir, string.format("%010d", ppid))
    end
end

local function create_socket()
    if o.enabled == "no" then return end
    set_vars()
    os.execute("mkdir " .. SocketDir .. " 2>/dev/null")
    mp.set_property("options/input-ipc-server", TheSocket)
end

local function shutdown_handler()
    if o.enabled == "no" then return end
    os.remove(TheSocket)
end

create_socket()

mp.register_event("shutdown", shutdown_handler)
