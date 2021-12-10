-- mpvSockets, one socket per instance, removes socket on exit

local utils = require 'mp.utils'

local function get_temp_path()
    local directory_seperator = package.config:match("([^\n]*)\n?")
    local example_temp_file_path = os.tmpname()

    -- remove generated temp file
    pcall(os.remove, example_temp_file_path)

    local seperator_idx = example_temp_file_path:reverse():find(directory_seperator)
    local temp_path_length = #example_temp_file_path - seperator_idx

    return example_temp_file_path:sub(1, temp_path_length)
end

tempDir = get_temp_path()

function join_paths(...)
    local arg={...}
    path = ""
    for i,v in ipairs(arg) do
        path = utils.join_path(path, tostring(v))
    end
    return path;
end

ppid = utils.getpid()

function socket_later()
    if os.execute("xdotool search -pid '"..ppid.."' | xargs -I '{}' xprop -id '{}' | grep umpv") then
        --nothing to do if true, as umpv has already created the socket
	--comment out next line if you don't want confirmation
        mp.osd_message("umpv detected")
    else
        mp.set_property("options/input-ipc-server", join_paths(tempDir, "mpvSockets", ppid))
        os.execute("mkdir " .. join_paths(tempDir, "mpvSockets") .. " 2>/dev/null")
    end
end

mp.register_event("file-loaded", socket_later)

function shutdown_handler()
    if os.execute("xdotool search -pid '"..ppid.."' | xargs -I '{}' xprop -id '{}' | grep umpv") then
        os.remove(join_paths(tempDir, "mpvSockets/umpv_socket"))
    else
        os.remove(join_paths(tempDir, "mpvSockets", ppid))
    end
end

mp.register_event("shutdown", shutdown_handler)
