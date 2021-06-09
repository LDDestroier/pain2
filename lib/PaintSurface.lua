-- PaintSurface

local PaintSurface = {}

local Config = require "lib.Config"

local help = {}

local grid = {
    normal = {
        "$$..%%..%%..%%..",
        "$$..%%..%%..%%..",
        "$$..%%..%%..%%..",
        "..$$..%%..%%..$$",
        "..$$..%%..%%..$$",
        "..$$..%%..%%..$$",
        "%%..$$..%%..$$..",
        "%%..$$..%%..$$..",
        "%%..$$..%%..$$..",
        "..%%..$$..$$..%%",
        "..%%..$$..$$..%%",
        "..%%..$$..$$..%%",
        "%%..%%..$$..%%..",
        "%%..%%..$$..%%..",
        "%%..%%..$$..%%..",
        "..%%..$$..$$..%%",
        "..%%..$$..$$..%%",
        "..%%..$$..$$..%%",
        "%%..$$..%%..$$..",
        "%%..$$..%%..$$..",
        "%%..$$..%%..$$..",
        "..$$..%%..%%..$$",
        "..$$..%%..%%..$$",
        "..$$..%%..%%..$$",
    },
    left = {
        "GO#RIGHT#",
        "#---\16####",
        "##---\16###",
        "###---\16##",
        "####---\16#",
        "###---\16##",
        "##---\16###",
        "#---\16####",
    },
    top = {
        "#GO##DOWN#",
        "#|#######|",
        "#||#####||",
        "#\31||###||\31",
        "##\31||#||\31#",
        "###\31|||\31##",
        "####\31|\31###",
        "#####\31####",
        "##########",
    },
    topleft = {
        "\\##\\",
        "\\\\##",
        "#\\\\#",
        "##\\\\",
    }
}

local mathmax, mathmin = math.max, math.min

local getGridFromPos = function(x, y)
	local g, xx
	if (x >= 0 and y >= 0) then
		g = grid.normal
	else
		if (x < 0 and y >= 0) then
			-- too far to the left, but not too far up
			g = grid.left
		elseif (x >= 0 and y < 0) then
			-- too far up, but not too far to the left
			g = grid.top
		else
			g = grid.topleft
		end
	end
	xx = (x % #g[1]) + 1
	return g[(y % #g) + 1]:sub(xx, xx)
end

local function makeScreen(width, height, character)
    local output = {}
    for y = 1, height do
        output[y] = {count = width}
        for x = 1, width do
            output[y][x] = character and character:sub(1, 1) or nil
        end
    end
    return output
end

local function stringWrite(str, pos, input)
    if not input then
        return str
        
    elseif pos > #str or pos < -#input + 2 then
        return str

    else
        if pos < 1 then
            input = input:sub(-pos + 2)
            pos = 1
        end
        return str:sub(1, pos - 1) .. input:sub(1, #str - pos + 1) .. str:sub(pos + #input)
    end
end

local _swt_output = ""
local function stringWriteTransparent(str, pos, input)
    if not input then
        return str

    elseif pos > #str or pos < -#input + 2 then
        return str

    else
        if pos < 1 then
            input = input:sub(-pos + 2)
            pos = 1
        end

        _swt_output = str:sub(1, mathmax(0, pos - 1))
        for i = 1, #input do
            _swt_output = _swt_output .. (
                Config.whitespace[input:sub(i, i)] and
                    str:sub(mathmax(0, i + pos - 1), mathmax(0, i + pos - 1))
                or
                    input:sub(i, i)
            )
            if i + pos > #str then
                break
            end
        end
        return _swt_output .. str:sub(pos + #input)
    end
end
    

_G.stringWrite = stringWrite
_G.stringWriteTransparent = stringWriteTransparent
_G.ws = Config.whitespace

function PaintSurface:new(obj)
    obj = obj or {
        width = 1,
        height = 1,
        minX = 1,
        minY = 1,
        mode = "text",  -- CraftOS-PC supports three modes:
                        -- 16 color terminal, 16 color hi-res, and 256 color hi-res.
                        -- 'mode' can be "text", "hires16", or "hires256".
                        -- This will take a while to implement, if I bother at all...
        resize_char = " ",
        resize_txcol = " ",
        resize_bgcol = " ",
        resize_mask = " ",
        board_char = makeScreen(0, 0),
        board_txcol = makeScreen(0, 0),
        board_bgcol = makeScreen(0, 0),
        board_mask = makeScreen(0, 0),
        grid_txcol = "7",
        grid_bgcol = "f",
        flag = {
            mask_type = "Normal",
            visible = true,
            name = "Layer"
        }
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

help["GetSize"] = "GetSize(); return width, height \nReturns the size of the Surface."
function PaintSurface:GetSize()
    return self.width, self.height
end

help["Resize"] = "Resize(new_width, new_height); return nil \nResizes the Surface."
function PaintSurface:Resize(new_width, new_height, new_minX, new_minY)
    -- Resizes a PaintSurface.
    new_width = new_width or self.width
    new_height = new_height or self.height
    new_minX = new_minX or self.minX
    new_minY = new_minY or self.minY
    
    for y = math.min(new_minY, self.minY), math.max(new_height, self.height) do
        self.board_char[y] = self.board_char[y] or {count = 0}
        self.board_txcol[y] = self.board_txcol[y] or {count = 0}
        self.board_bgcol[y] = self.board_bgcol[y] or {count = 0}
        self.board_mask[y] = self.board_mask[y] or {count = 0}
        --[[
        for x = math.min(new_minX, self.minX), math.max(new_width, self.width) do
            self.board_char[y][x] = self.board_char[y][x] or self.resize_char
            self.board_txcol[y][x] = self.board_txcol[y][x] or self.resize_txcol
            self.board_bgcol[y][x] = self.board_bgcol[y][x] or self.resize_bgcol
            self.board_mask[y][x] = self.board_mask[y][x] or self.resize_mask
        end
        --]]
    end

    self.width = new_width
    self.height = new_height
    self.minX = new_minX
    self.minY = new_minY
end

local mask_types = {
    ["Normal"] = 1,
    ["Subtract"] = 2,
    ["Add"] = 3
}

help["Shift"] = "Shift(x, y); return nil \nShifts content of the surface by (x, y)."
function PaintSurface:Shift(x, y)
    -- Shift dots horizontally, first.
    self:Touch(self.width + x, self.height + y, self.minX + x, self.minY + y)
    for iy = self.minY, self.height do
        if self.board_char[iy].count ~= 0 then
            if x < 0 then
                for ix = self.minX, self.width + 1 do
                    self.board_char[iy][ix + x] = self.board_char[iy][ix]
                    self.board_txcol[iy][ix + x] = self.board_txcol[iy][ix]
                    self.board_bgcol[iy][ix + x] = self.board_bgcol[iy][ix]
                    self.board_mask[iy][ix + x] = self.board_mask[iy][ix]
                end

            elseif x > 0 then
                for ix = self.width, self.minX - 1, -1 do
                    self.board_char[iy][ix + x] = self.board_char[iy][ix]
                    self.board_txcol[iy][ix + x] = self.board_txcol[iy][ix]
                    self.board_bgcol[iy][ix + x] = self.board_bgcol[iy][ix]
                    self.board_mask[iy][ix + x] = self.board_mask[iy][ix]
                end
            end
        end
    end
    -- Then, shift dots vertically.
    if y < 0 then
        for iy = self.minY, self.height + 1 do
            self.board_char[iy + y] = self.board_char[iy]
            self.board_txcol[iy + y] = self.board_txcol[iy]
            self.board_bgcol[iy + y] = self.board_bgcol[iy]
            self.board_mask[iy + y] = self.board_mask[iy]
        end

    elseif y > 0 then
        for iy = self.height, self.minY, -1 do
            self.board_char[iy + y] = self.board_char[iy]
            self.board_txcol[iy + y] = self.board_txcol[iy]
            self.board_bgcol[iy + y] = self.board_bgcol[iy]
            self.board_mask[iy + y] = self.board_mask[iy]
        end
    end
    self.width = self.width + x
    self.height = self.height + y
    self.minX = self.minX + x
    self.minY = self.minY + y
end

help["Touch"] = "Touch(x, y); return nil \nEnsures that (x, y) is a valid space to draw onto."
function PaintSurface:Touch(x, y, minX, minY)
    self:Resize(
        x > self.width and x,
        y > self.height and y,
        minX and (minX < self.minX and minX),
        minY and (minY < self.minY and minY)
    )
end

help["SetMask"] = "SetMask(maskType); return nil \nSet's the mask type of the Surface. Unimplemented."
function PaintSurface:SetMask(maskType)
    if mask_types[maskType] then
        self.flag.mask_type = maskType
    end
end

help["Draw"] = "Draw(x, y, char, txcol, bgcol, mask); return nil \nDraws onto the Surface at (x, y) using char, txcol, bgcol, and mask as the inputs for each layer. If a transparent character is written to txcol, bgcol, or mask, then it does not overwrite that part of the respective layer."
function PaintSurface:Draw(x, y, char, txcol, bgcol, mask)
    char = char or ""
    txcol = txcol or ""
    bgcol = bgcol or ""
    mask = mask or ""
    local len = math.max(#char, #txcol, #bgcol, #mask)
    local ix
    if len == 0 then
        return
    end
    self:Touch(x + len - 1, y, x, y)
    for i = 1, len do
        ix = i + x - 1
        -- increase count value for each layer, then write to surface
        if not self.board_char[y][ix]  then self.board_char[y].count  = self.board_char[y].count  + 1 end
        if not self.board_txcol[y][ix] then self.board_txcol[y].count = self.board_txcol[y].count + 1 end
        if not self.board_bgcol[y][ix] then self.board_bgcol[y].count = self.board_bgcol[y].count + 1 end
        if not self.board_mask[y][ix]  then self.board_mask[y].count  = self.board_mask[y].count  + 1 end
        self.board_char[y][ix]  = (i <= #char)  and char:sub(i, i)  or self.board_char[y][ix]
        self.board_txcol[y][ix] = (i <= #txcol) and txcol:sub(i, i) or self.board_txcol[y][ix]
        self.board_bgcol[y][ix] = (i <= #bgcol) and bgcol:sub(i, i) or self.board_bgcol[y][ix]
        self.board_mask[y][ix]  = (i <= #mask)  and mask:sub(i, i)  or self.board_mask[y][ix]
    end
end

help["Erase"] = "Erase(x, y, char, txcol, bgcol, mask); return nil \nDraws empty characters for every character in char, txcol, bgcol, and mask. Default parameter for mask is \"\", and \" \" for the other three."
function PaintSurface:Erase(x, y, char, txcol, bgcol, mask)
    self:Touch(x, y, x, y)
    char = char or " "
    txcol = txcol or " "
    bgcol = bgcol or " "
    mask = mask or ""   -- intentional
    for ix = x, x + #char - 1 do
        if self.board_char[y][ix] then
            self.board_char[y].count = self.board_char[y].count - 1
        end
        self.board_char[y][ix] = nil
    end
    for ix = x, x + #txcol - 1 do
        if self.board_txcol[y][ix] then
            self.board_txcol[y].count = self.board_txcol[y].count - 1
        end
        self.board_txcol[y][ix] = nil
    end
    for ix = x, x + #bgcol - 1 do
        if self.board_bgcol[y][ix] then
            self.board_bgcol[y].count = self.board_bgcol[y].count - 1
        end
        self.board_bgcol[y][ix] = nil
    end
    for ix = x, x + #mask - 1 do
        if self.board_mask[y][ix] then
            self.board_mask[y].count = self.board_mask[y].count - 1
        end
        self.board_mask[y][ix] = nil
    end
end

help["EraseMask"] = "EraseMask(x, y, mask); return nil \nSame as Erase(), but only acts on the mask. Default parameter is \" \", as opposed to \"\" in Erase()."
function PaintSurface:EraseMask(x, y, mask)
    return self:Erase(x, y, "", "", "", mask or " ")
end

function PaintSurface:GetDot(x, y)
    if self.board_char[y] then
        return self.board_char[y][x], self.board_txcol[y][x], self.board_bgcol[y][x], self.board_mask[y][x]
    else
        return nil
    end
end

function PaintSurface:PurgeEmptyLines()
    local newMinY, newMaxY = 0, 0
    for y = self.minY, 0 do
        if self.board_char[y] then
            if self.board_char[y].count <= 0 then
                self.board_char[y] = nil
                self.board_txcol[y] = nil
                self.board_bgcol[y] = nil
                self.board_mask[y] = nil
                if y == self.minY then
                    self.minY = self.minY + 1
                end
            end
        end
    end
    for y = self.height, 2, -1 do
        if self.board_char[y] then
            if self.board_char[y].count <= 0 then
                self.board_char[y] = nil
                self.board_txcol[y] = nil
                self.board_bgcol[y] = nil
                self.board_mask[y] = nil
                if y == self.height then
                    self.height = self.height - 1
                end
            end
        end
    end
end

help["Render"] = "Render(x, y, width, height, scroll_x, scroll_y, include_grid); return nil \nRenders the Surface onto the terminal at (x, y) with the specified width/height. Unimplemented."
function PaintSurface:Render(hx, hy, width, height, scroll_x, scroll_y, include_grid)
    if self.flag.visible then
        local line_char, line_txcol, line_bgcol
        local dot_char, dot_txcol, dot_bgcol, dot_mask
        for y = 1, height do
            line_char, line_txcol, line_bgcol = "", "", ""
            for x = 1, width do
                dot_char, dot_txcol, dot_bgcol, dot_mask = self:GetDot(x + hx + scroll_x - 1, y + hy + scroll_y - 1)
                line_char  = line_char  .. (dot_char  or (include_grid and getGridFromPos(x + scroll_x - hx, y + scroll_y - hx) or " "))
                line_txcol = line_txcol .. (dot_txcol or (include_grid and self.grid_txcol) or "0")
                line_bgcol = line_bgcol .. (dot_bgcol or (include_grid and self.grid_bgcol) or "f")
            end
            term.setCursorPos(hx, hy + y - 1)
            term.blit(line_char, line_txcol, line_bgcol)
        end
    end
end

function PaintSurface:Help(name)
    if help[name] then
        print(help[name])
    else
        print("No such method.")
    end
end

return PaintSurface