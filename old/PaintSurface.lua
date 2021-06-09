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
	return g[(y % #g) + 1]:sub(xx, xx), "7", "f"
end

local function makeScreen(width, height, character)
    local output = {}
    for y = 1, height do
        output[y] = (character:rep(width)):sub(1, width)
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
        startX = 1,
        startY = 1,
        mode = "text",  -- CraftOS-PC supports three modes:
                        -- 16 color terminal, 16 color hi-res, and 256 color hi-res.
                        -- 'mode' can be "text", "hires16", or "hires256".
                        -- This will take a while to implement, if I bother at all...
        resize_char = " ",
        resize_txcol = " ",
        resize_bgcol = " ",
        resize_mask = " ",
        board_char = makeScreen(1, 1, " "),
        board_txcol = makeScreen(1, 1, " "),
        board_bgcol = makeScreen(1, 1, " "),
        board_mask = makeScreen(1, 1, " "),
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
function PaintSurface:Resize(new_width, new_height, left_align, top_align)
    -- Resizes a PaintSurface.
    new_width = new_width or self.width
    new_height = new_height or self.height
    if new_height == self.height then
        if new_width == self.width then
            -- Stop wasting my CPU time!
            return

        elseif new_width > self.width then
            for y = 1, new_height do
                self.board_char[y]  = self.board_char[y]  .. self.resize_char:rep(new_width - self.width)
                self.board_txcol[y] = self.board_txcol[y] .. self.resize_txcol:rep(new_width - self.width)
                self.board_bgcol[y] = self.board_bgcol[y] .. self.resize_bgcol:rep(new_width - self.width)
                self.board_mask[y]  = self.board_mask[y]  .. self.resize_mask:rep(new_width - self.width)
            end
        
        elseif new_width < self.width then
            for y = 1, new_height do
                self.board_char[y]  = self.board_char[y]:sub(1, new_width)
                self.board_txcol[y] = self.board_txcol[y]:sub(1, new_width)
                self.board_bgcol[y] = self.board_bgcol[y]:sub(1, new_width)
                self.board_mask[y]  = self.board_mask[y]:sub(1, new_width)
            end
        end

    elseif new_height < self.height then
        if new_width == self.width then
            for y = new_height + 1, self.height do
                self.board_char[y] = nil
                self.board_txcol[y] = nil
                self.board_bgcol[y] = nil
                self.board_mask[y] = nil
            end
            
        elseif new_width > self.width then
            for y = 1, self.height do
                if y > new_height then
                    self.board_char[y]  = nil
                    self.board_txcol[y] = nil
                    self.board_bgcol[y] = nil
                    self.board_mask[y]  = nil

                else
                    self.board_char[y]  = self.board_char[y]  .. self.resize_char:rep(new_width - self.width)
                    self.board_txcol[y] = self.board_txcol[y] .. self.resize_txcol:rep(new_width - self.width)
                    self.board_bgcol[y] = self.board_bgcol[y] .. self.resize_bgcol:rep(new_width - self.width)
                    self.board_mask[y]  = self.board_mask[y]  .. self.resize_mask:rep(new_width - self.width)
                end
            end

        elseif new_width < self.width then
            for y = 1, self.height do
                if y > new_height then
                    self.board_char[y] = nil
                    self.board_txcol[y] = nil
                    self.board_bgcol[y] = nil
                    self.board_mask[y] = nil

                else
                    self.board_char[y]  = self.board_char[y]:sub(1, new_width)
                    self.board_txcol[y] = self.board_txcol[y]:sub(1, new_width)
                    self.board_bgcol[y] = self.board_bgcol[y]:sub(1, new_width)
                    self.board_mask[y]  = self.board_mask[y]:sub(1, new_width)
                end
            end

        end

    elseif new_height > self.height then
        if new_width == self.width then
            for y = self.height + 1, new_height do
                self.board_char[y]  = self.resize_char:rep(new_width)
                self.board_txcol[y] = self.resize_txcol:rep(new_width)
                self.board_bgcol[y] = self.resize_bgcol:rep(new_width)
                self.board_mask[y]  = self.resize_mask:rep(new_width)
            end
        
        elseif new_width > self.width then
            for y = 1, new_height do
                if y > self.height then
                    self.board_char[y]  = self.resize_char:rep(new_width)
                    self.board_txcol[y] = self.resize_txcol:rep(new_width)
                    self.board_bgcol[y] = self.resize_bgcol:rep(new_width)
                    self.board_mask[y]  = self.resize_mask:rep(new_width)

                else
                    self.board_char[y]  = self.board_char[y]  .. self.resize_char:rep(new_width - self.width)
                    self.board_txcol[y] = self.board_txcol[y] .. self.resize_txcol:rep(new_width - self.width)
                    self.board_bgcol[y] = self.board_bgcol[y] .. self.resize_bgcol:rep(new_width - self.width)
                    self.board_mask[y]  = self.board_mask[y]  .. self.resize_mask:rep(new_width - self.width)
                end
            end

        elseif new_width < self.width then
            if y > new_height then
                self.board_char[y]  = self.resize_char:rep(new_width)
                self.board_txcol[y] = self.resize_txcol:rep(new_width)
                self.board_bgcol[y] = self.resize_bgcol:rep(new_width)
                self.board_mask[y]  = self.resize_mask:rep(new_width)

            else
                self.board_char[y]  = self.board_char[y]:sub(1, new_width)
                self.board_txcol[y] = self.board_txcol[y]:sub(1, new_width)
                self.board_bgcol[y] = self.board_bgcol[y]:sub(1, new_width)
                self.board_mask[y]  = self.board_mask[y]:sub(1, new_width)
            end
        end
    end

    self.width = new_width
    self.height = new_height
end

local mask_types = {
    ["Normal"] = 1,
    ["Subtract"] = 2,
    ["Add"] = 3
}

help["Touch"] = "Shift(x, y); return nil \nShifts content of the surface by (x, y)."
function PaintSurface:Shift(x, y)
    -- Shift dots horizontally, first.
    if x < 0 then

    elseif x > 0 then

    end
end

help["Touch"] = "Touch(x, y); return nil \nEnsures that (x, y) is a valid space to draw onto."
function PaintSurface:Touch(x, y)
    self:Resize(
        x > self.width and x,
        y > self.height and y
    )
    if x < self.startX or y < self.startY then
        self:Shift(x - self.startX, y - self.startY)
        self.startX = math.min(x, self.startX)
        self.startY = math.min(y, self.startY)
    end
end

help["SetMask"] = "SetMask(maskType); return nil \nSet's the mask type of the Surface. Unimplemented."
function PaintSurface:SetMask(maskType)
    if mask_types[maskType] then
        self.flag.mask_type = maskType
    end
end

help["Draw"] = "Draw(x, y, char, txcol, bgcol, mask); return nil \nDraws onto the Surface at (x, y) using char, txcol, bgcol, and mask as the inputs for each layer. If a transparent character is written to txcol, bgcol, or mask, then it does not overwrite that part of the respective layer."
function PaintSurface:Draw(x, y, char, txcol, bgcol, mask)
    local len = math.max(#(char or ""), #(txcol or ""), #(bgcol or ""), #(mask or ""))
    self:Touch(x + len - 1, y)
    x = x - (self.startX - 1)
    y = y - (self.startY - 1)
    self.board_char[y]  = stringWrite(           self.board_char[y],  x, char)
    self.board_txcol[y] = stringWriteTransparent(self.board_txcol[y], x, txcol)
    self.board_bgcol[y] = stringWriteTransparent(self.board_bgcol[y], x, bgcol)
    self.board_mask[y]  = stringWriteTransparent(self.board_mask[y],  x, mask)
end

help["Erase"] = "Erase(x, y, char, txcol, bgcol, mask); return nil \nDraws empty characters for every character in char, txcol, bgcol, and mask. Default parameter for mask is \"\", and \" \" for the other three."
function PaintSurface:Erase(x, y, char, txcol, bgcol, mask)
    self:Touch(x, y)
    x = x - (self.startX - 1)
    y = y - (self.startY - 1)
    self.board_char[y]  = stringWrite(self.board_char[y], x, char or " ")
    self.board_txcol[y] = stringWrite(self.board_txcol[y], x, txcol or " ")
    self.board_bgcol[y] = stringWrite(self.board_bgcol[y], x, bgcol or " ")
end

help["EraseMask"] = "EraseMask(x, y, mask); return nil \nSame as Erase(), but only acts on the mask. Default parameter is \" \", as opposed to \"\" in Erase()."
function PaintSurface:EraseMask(x, y, mask)
    self:Touch(x, y)
    x = x - (self.startX - 1)
    y = y - (self.startY - 1)
    return self:Erase(x, y, "", "", "", mask or " ")
end

help["Render"] = "Render(x, y, width, height, scroll_x, scroll_y, include_grid); return nil \nRenders the Surface onto the terminal at (x, y) with the specified width/height. Unimplemented."
function PaintSurface:Render(hx, hy, width, height, scroll_x, scroll_y, include_grid)
    --hx = hx - (self.startX - 1)
    --hy = hy - (self.startY - 1)
    if self.flag.visible then
        local line = {"","","",""}
        local gridLine = {"",self.grid_txcol:rep(width),self.grid_bgcol:rep(width)}
        for y = 1, height do
            line[1] = stringWrite(self.resize_char:rep(width), -scroll_x, self.board_char[y + scroll_y] or "")
            line[2] = stringWrite(self.resize_txcol:rep(width), -scroll_x, self.board_txcol[y + scroll_y] or "")
            line[3] = stringWrite(self.resize_bgcol:rep(width), -scroll_x, self.board_bgcol[y + scroll_y] or "")
            line[4] = stringWrite(self.resize_mask:rep(width), -scroll_x, self.board_mask[y + scroll_y] or "")
            if include_grid then
                gridLine[1] = ""
                for x = 1, width do
                    gridLine[1] = gridLine[1] .. getGridFromPos(x + scroll_x - hx, y + scroll_y - hy)
                end
                line[1] = stringWriteTransparent(gridLine[1], 1, line[1])
                line[2] = stringWriteTransparent(gridLine[2], 1, line[2])
                line[3] = stringWriteTransparent(gridLine[3], 1, line[3])
            end
            term.setCursorPos(hx, hy + y - 1)
            term.blit(line[1], line[2]:gsub(" ", "0"), line[3]:gsub(" ", "f"))
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