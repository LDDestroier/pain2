-- Pencil tool

local tool = {}

function tool:new(obj)
    obj = obj or {
        name = "Pencil",
        description = "A simple drawing tool.",

    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function tool:HandleEvents(eventName, button, mx, my)
    local state, config = self.state, self.config
    if eventName == "surface_click" or eventName == "surface_drag" then
        local surface
        for i = 1, #self.state.selected_surfaces do
            surface = self.state.selected_surfaces[i]
            if button == 1 then
                surface:Draw(mx, my, "a", "0", "0")
                self.state.do_render = true
            
            elseif button == 2 then
                surface:Erase(mx, my)
                self.state.do_render = true
            end
        end
    end
end

local function LOAD(state, config, flag)
    local output = tool:new()
    output.state = state
    output.config = config
    
    flag.mouse_drag_on_scroll = true

    return output
end

return LOAD