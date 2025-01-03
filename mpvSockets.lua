-- mpvSockets, one socket per instance, removes socket on exit
local mp = require 'mp'
local options = require 'mp.options'
local utils = require 'mp.utils'

local o = {
  enabled = "yes",
  socket  = "pid",
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

    TheSocket = join_paths(SocketDir, os.time(os.date("!*t")))
    if o.socket ~= "pid" then
        TheSocket = TheSocket .. "_" .. o.socket
    end
end

local function create_socket()
    if o.enabled == "no" then return end
    set_vars()
    os.execute("mkdir " .. SocketDir .. " 2>/dev/null")
    os.execute("chmod 700 " .. SocketDir .. " 2>/dev/null")
    mp.set_property("options/input-ipc-server", TheSocket)
end

local function shutdown_handler()
    if o.enabled == "no" then return end
    os.remove(TheSocket)
end

create_socket()

mp.register_event("shutdown", shutdown_handler)
