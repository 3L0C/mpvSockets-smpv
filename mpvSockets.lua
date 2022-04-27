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

function join_paths(...)
    local arg={...}
    path = ""
    for i,v in ipairs(arg) do
        path = utils.join_path(path, tostring(v))
    end
    return path;
end

function set_vars()
    socketDir = os.getenv("MPV_SOCKET_DIR")

    if not socketDir then
        socketDir = join_paths(get_temp_path(), "mpvSockets")
    end

    if o.umpv == "yes" then
        theSocket = os.getenv("MPV_UMPV_SOCKET")
        if not theSocket then
            theSocket = join_paths(socketDir, "umpv_socket")
        end
    elseif o.music == "yes" then
        theSocket = os.getenv("MPV_MUSIC_SOCKET")
        if not theSocket then
            theSocket = join_paths(socketDir, "music_socket")
        end
    elseif o.pid == "yes" then
        ppid = utils.getpid()
        theSocket = join_paths(socketDir, ppid)
    end
end

function create_socket()
    if o.enabled == "no" then return end
    set_vars()
    os.execute("mkdir " .. socketDir .. " 2>/dev/null")
    mp.set_property("options/input-ipc-server", theSocket)
end

function shutdown_handler()
    if o.enabled == "no" then return end
    os.remove(theSocket)
end

create_socket()

mp.register_event("shutdown", shutdown_handler)
