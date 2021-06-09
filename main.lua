--[[

888      8888888 888b     d888 888b    888
888        888   8888b   d8888 8888b   888
888        888   88888b.d88888 88888b  888
888        888   888Y88888P888 888Y88b 888
888        888   888 Y888P 888 888 Y88b888
888        888   888  Y8P  888 888  Y88888
888        888   888   "   888 888   Y8888
88888888 8888888 888       888 888    Y888

                  リ ー ム

               by LDDestroier

Mondo WIP

To-do:
    + make a menu system that doesn't suck balls
    + 

Features:
    + dynamically resizable canvas
    + supports every known CC image type
    + modular tool system
    + optional toolbar in separate window

]]

keys.ctrl = 256
keys.alt = 257
keys.shift = 258

local PaintSurface = require "lib.PaintSurface"
local Config = require "lib.Config"
local ToolLoader = require "lib.ToolLoader"

local scr_x, scr_y = term.getSize()

local state = {}
do
    state = {
        -- Table of PaintSurfaces.
        surfaces = {},

        -- List of PaintSurfaces in state.surfaces that will be manipulated by tools.
        selected_surfaces = {},

        -- If true, quit the program.
        user_quit = false,

        -- Tools.
        sel_tool = "n/a",
        tool_list = {},
        tool = nil,

        -- If true, render the screen and change to false.
        do_render = true,

        -- Tables of all currently pressed keys and mouse buttons.
        keys_down = {},
        mice_down = {}, -- amount of time each key has been pressed for
        keys_time = {},
        mice_time = {}, -- tick number that each mouse button had last been pressed

        -- Internal timers for various things.
        timers = {},
        tick_num = 0,

        -- Internal events for various things (namely timers)
        events = {},
        
        -- Scroll
        scroll_x = 0,
        scroll_y = 0,
        
        -- Selected color
        sel_char = " ",
        sel_txcol = 1,      -- In 16 color mode, ranges from 1 to 16.
        sel_bgcol = 16,     -- Otherwise, ranges from 1 to 256.

        -- Tool flags.
        tool_flag = {
            mouse_drag_on_scroll = true,
            -- something else
        }
    }

    -- Initialize keys_down.
    for i = 1, 258 do
        state.keys_down[i] = false
        state.keys_time[i] = 0
    end

    -- Initialize mice_down.
    for i = 1, 5 do
        -- 1 = left click
        -- 2 = right click
        -- 3 = middle click
        -- 4 = mouse back button (it's cool that CraftOS-PC supports this)
        -- 5 = mouse forward button
        state.mice_down[i] = {false, 1, 1, ""}  -- mice_down[i][4] is the last event queued by that mouse press (either "mouse_click" or "mouse_drag")
        state.mice_time[i] = 0
    end
end

local function tryRender(state)
    if state.do_render then
        if Config.do_set_visible then
            term.current().setVisible(false)
        end
        for i = 1, #state.surfaces do
            state.surfaces[i]:Render(1, 1, scr_x, scr_y, state.scroll_x, state.scroll_y, true)
        end
        if Config.do_set_visible then
            term.current().setVisible(true)
        end
        state.do_render = false
    end
end

local eventName, event_1, event_2, event_3, event_4, event_5
local timer_id = os.startTimer(0.05)

-- List of all events that are sent to tools.
local allowedToolEvents = {
    surface_click = true,
    surface_drag = true,
    surface_up = true
}

local startInternalTimer = function(tID, duration)
    state.timers[tID] = duration
end

local function main()

    -- Clear screen.
    term.clear()
    term.setCursorPos(1, 1)

    -- Make a demo surface
    state.surfaces[1] = PaintSurface:new()
    state.selected_surfaces[1] = state.surfaces[1]
    state.do_render = true

    -- Load tool.
    ToolLoader.Prime(state, config)
    state.tool_list = ToolLoader.GetTools()
    state.sel_tool = state.tool_list[1]
    state.tool = ToolLoader.LoadTool(state.sel_tool)

    -- Start some internal timers.
    startInternalTimer("purgeEmptyLines", 20)

    -- Adds variables to global scope for testing in lua interpreter.
    _G.t = {
        PaintSurface = PaintSurface,
        Config = Config,
        State = State
    }
    _G.ps = state.surfaces[1]
    _G.reload = function()
        shell.setDir("/pain2")
        shell.run("/pain2/main.lua", "--test")
    end

    -- Surface scroll movement over one tick
    local old_scroll_x, old_scroll_y = state.scroll_x, state.scroll_y

    while not state.user_quit do

        if #state.events == 0 then
            eventName, event_1, event_2, event_3, event_4, event_5 = os.pullEventRaw()

        else
            eventName, event_1, event_2, event_3, event_4, event_5 = table.unpack(state.events[1])
            table.remove(state.events, 1)
        end

        if eventName == "terminate" then
            state.user_quit = true
        
        elseif eventName == "term_resize" then
            scr_x, scr_y = term.getSize()
            state.do_render = true

        elseif eventName == "mouse_click" then
            state.mice_down[event_1][1] = true
            state.mice_down[event_1][2] = event_2
            state.mice_down[event_1][3] = event_3
            state.mice_down[event_1][4] = eventName
            state.mice_time[event_1] = state.tick_num
            -- check if clicking canvas and not UI element (will do later)
            if true then
                state.events[#state.events + 1] = {"surface_click", event_1, event_2 + state.scroll_x, event_3 + state.scroll_y}
            end
        
        elseif eventName == "mouse_drag" then
            -- check if clicking canvas and not UI element (will do later)
            state.mice_down[event_1][1] = true
            state.mice_down[event_1][2] = event_2
            state.mice_down[event_1][3] = event_3
            state.mice_down[event_1][4] = eventName
            state.mice_time[event_1] = state.tick_num
            if true then
                state.events[#state.events + 1] = {"surface_drag", event_1, event_2 + state.scroll_x, event_3 + state.scroll_y}
            end
        
        elseif eventName == "mouse_up" then
            state.mice_down[event_1][1] = false
            state.mice_down[event_1][2] = event_2
            state.mice_down[event_1][3] = event_3
            if true then
                state.events[#state.events + 1] = {"surface_up", event_1, event_2 + state.scroll_x, event_3 + state.scroll_y}
            end
        
        elseif eventName == "internal_timer" then
            if event_1 == "purgeEmptyLines" then
                startInternalTimer("purgeEmptyLines", 20)
                for i = 1, #state.surfaces do
                    state.surfaces[i]:PurgeEmptyLines()
                end
            end
        
        elseif eventName == "timer" then
            -- event_1 -> timer ID
            if event_1 == timer_id then
                timer_id = os.startTimer(0.05)
                state.tick_num = state.tick_num + 1
                old_scroll_x, old_scroll_y = state.scroll_x, state.scroll_y

                -- Run internal timers.
                for tID, tValue in pairs(state.timers) do
                    state.timers[tID] = state.timers[tID] -1
                    if state.timers[tID] <= 0 then
                        state.events[#state.events + 1] = {"internal_timer", tID}
                        state.timers[tID] = nil
                    end
                end

                -- Draw the screen.
                tryRender(state)

                -- Check controls.

                local singleScroll = Config.checkControl(state, "singleScroll")

                if Config.checkControl(state, "quit") then
                    state.user_quit = true
                    state.do_render = true
                end

                if Config.checkControl(state, "scrollUp", not singleScroll) then
                    state.scroll_y = state.scroll_y - 1
                end

                if Config.checkControl(state, "scrollDown", not singleScroll) then
                    state.scroll_y = state.scroll_y + 1
                end

                if Config.checkControl(state, "scrollLeft", not singleScroll) then
                    state.scroll_x = state.scroll_x - 1
                end

                if Config.checkControl(state, "scrollRight", not singleScroll) then
                    state.scroll_x = state.scroll_x + 1
                end

                if Config.checkControl(state, "resetScroll") then
                    state.scroll_x = 0
                    state.scroll_y = 0
                end

                if Config.checkControl(state, "purgeEmptyLines") then
                    for i = 1, #state.surfaces do
                        state.surfaces[i]:PurgeEmptyLines()
                    end
                end

                if Config.checkControl(state, "shiftDotsLeft", not singleScroll) then
                    for i = 1, #state.selected_surfaces do
                        state.surfaces[i]:Shift(-1, 0)
                    end
                    state.do_render = true
                end

                if Config.checkControl(state, "shiftDotsRight", not singleScroll) then
                    for i = 1, #state.selected_surfaces do
                        state.surfaces[i]:Shift(1, 0)
                    end
                    state.do_render = true
                end

                if Config.checkControl(state, "shiftDotsUp", not singleScroll) then
                    for i = 1, #state.selected_surfaces do
                        state.surfaces[i]:Shift(0, -1)
                    end
                    state.do_render = true
                end

                if Config.checkControl(state, "shiftDotsDown", not singleScroll) then
                    for i = 1, #state.selected_surfaces do
                        state.surfaces[i]:Shift(0, 1)
                    end
                    state.do_render = true
                end

                if old_scroll_x ~= state.scroll_x or old_scroll_y ~= state.scroll_y then
                    state.do_render = true
                end

                if state.tool_flag.mouse_drag_on_scroll then
                    for i = 1, 5 do
                        if state.mice_down[i][1] then
                            state.events[#state.events + 1] = {
                                "surface_drag",
                                i,
                                state.mice_down[i][2] + state.scroll_x,
                                state.mice_down[i][3] + state.scroll_y
                            }
                        end
                    end
                end

                -- Increment amount for held keys
                for i = 1, 258 do
                    if state.keys_down[i] then
                        state.keys_time[i] = state.keys_time[i] + 1
                    end
                end

                -- Tick down internal timers.
                for k, v in pairs(state.timers) do
                    state.timers[k] = v - 1
                    if state.timers[k] <= 0 then
                        state.timers[k] = nil
                    end
                end
            end
        
        elseif eventName == "key" and event_2 == false then
            -- event_1 -> key ID
            -- event_2 -> key repeat
            state.keys_time[event_1] = 1
            state.keys_down[event_1] = true
            
            state.keys_down[keys.ctrl]  = state.keys_down[keys.leftCtrl]  or state.keys_down[keys.rightCtrl]
            state.keys_down[keys.shift] = state.keys_down[keys.leftShift] or state.keys_down[keys.rightShift]
            state.keys_down[keys.alt]   = state.keys_down[keys.leftAlt]   or state.keys_down[keys.rightAlt]

            if state.keys_down[keys.ctrl] then
                state.keys_time[keys.ctrl] = math.max(1, state.keys_time[keys.ctrl])
            end

            if state.keys_down[keys.shift] then
                state.keys_time[keys.shift] = math.max(1, state.keys_time[keys.shift])
            end

            if state.keys_down[keys.alt] then
                state.keys_time[keys.alt] = math.max(1, state.keys_time[keys.alt])
            end
        
        elseif eventName == "key_up" then
            state.keys_time[event_1] = 0
            state.keys_down[event_1] = false

            state.keys_down[keys.ctrl]  = state.keys_down[keys.leftCtrl]  or state.keys_down[keys.rightCtrl]
            state.keys_down[keys.shift] = state.keys_down[keys.leftShift] or state.keys_down[keys.rightShift]
            state.keys_down[keys.alt]   = state.keys_down[keys.leftAlt]   or state.keys_down[keys.rightAlt]

            if not state.keys_down[keys.ctrl] then
                state.keys_time[keys.ctrl] = 0
            end

            if not state.keys_down[keys.shift] then
                state.keys_time[keys.shift] = 0
            end

            if not state.keys_down[keys.alt] then
                state.keys_time[keys.alt] = 0
            end
        end

        -- Handle tools babyyy

        if allowedToolEvents[ eventName ] then
            state.tool:HandleEvents(eventName, event_1, event_2, event_3, event_4, event_5)
        end

    end

end

local function interpretArgs(tInput, tArgs)
	local output = {}
	local errors = {}
	local usedEntries = {}
	for aName, aType in pairs(tArgs) do
		output[aName] = false
		for i = 1, #tInput do
			if not usedEntries[i] then
				if tInput[i] == aName and not output[aName] then
					if aType then
						usedEntries[i] = true
						if type(tInput[i+1]) == aType or type(tonumber(tInput[i+1])) == aType then
							usedEntries[i+1] = true
							if aType == "number" then
								output[aName] = tonumber(tInput[i+1])
							else
								output[aName] = tInput[i+1]
							end
						else
							output[aName] = nil
							errors[1] = errors[1] and (errors[1] + 1) or 1
							errors[aName] = "expected " .. aType .. ", got " .. type(tInput[i+1])
						end
					else
						usedEntries[i] = true
						output[aName] = true
					end
				end
			end
		end
	end
	for i = 1, #tInput do
		if not usedEntries[i] then
			output[#output+1] = tInput[i]
		end
	end
	return output, errors
end

local tArgs, tArgErrors = interpretArgs({...},{
    ["--test"] = false
})

if #tArgErrors > 0 then
	local errList = ""
	for k,v in pairs(tArgErrors) do
		if k ~= 1 then
			errList = errList .. "\"" .. k .. "\": " .. v .. "; "
		end
		error(errList:sub(1, -2))
	end

else
    if tArgs["--test"] then
        -- do nothing

    else
        local result, message = pcall( main )
        if not result then
            if Config.do_set_visible then
                term.current().setVisible(true)
            end
            term.setCursorPos(1, 1)
            printError(message)
        end
    end
end

-- Eat any extra key events
sleep(0.05)