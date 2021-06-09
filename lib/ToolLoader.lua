local ToolLoader = {}

local state, config, flag

function ToolLoader.Prime(_state, _config)
    state = _state
    config = _config
    flag = state.tool_flag
end

function ToolLoader.GetTools()
    local output = {}
    local t
    for k, name in pairs( fs.list(fs.combine(fs.getDir(shell.getRunningProgram()), "tools")) ) do
        t = require("tools." .. name:sub(1, -5))
        if type(t) == "function" then
            output[#output + 1] = name:sub(1, -5)
        end
    end
    return output
end

function ToolLoader.LoadTool(name)
    local tLoad = require("tools." .. name)
    if tLoad then
        return tLoad(state, config, flag)
        
    else
        return false
    end
end

return ToolLoader