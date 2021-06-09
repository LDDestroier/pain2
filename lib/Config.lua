local Config = {}

-- If true, runs setVisible(false) before rendering, then setVisible(true) after.
-- Reduces flickering and probably decreases render time.
Config.do_set_visible = true

Config.whitespace = {
    ["\009"] = true,
    ["\010"] = true,
    ["\013"] = true,
    ["\032"] = true,
    ["\128"] = true
}
Config.control_hold_check = {}	-- used to check if an input has just been used or not

-- All keyboard controls for program
Config.control = {
    quit = {
        key = keys.q,
        holdDown = false,
        modifiers = {
            [keys.ctrl] = true
        },
    },
    scrollUp = {
        key = keys.up,
        holdDown = true,
        modifiers = {},
    },
    scrollDown = {
        key = keys.down,
        holdDown = true,
        modifiers = {},
    },
    scrollLeft = {
        key = keys.left,
        holdDown = true,
        modifiers = {},
    },
    scrollRight = {
        key = keys.right,
        holdDown = true,
        modifiers = {},
    },
    singleScroll = {
        key = keys.tab,
        holdDown = true,
        modifiers = {},
        ignoreExtraModifiers = true
    },
    resetScroll = {
        key = keys.a,
        holdDown = false,
        modifiers = {},
    },
    purgeEmptyLines = { -- this will probably be done automatically later
        key = keys.space,
        holdDown = false,
        modifiers = {},
    },
    nextTextColor = {
        key = keys.rightBracket,
        holdDown = false,
        modifiers = {
            [keys.shift] = true
        },
    },
    prevTextColor = {
        key = keys.leftBracket,
        holdDown = false,
        modifiers = {
            [keys.shift] = true
        },
    },
    nextBackColor = {
        key = keys.rightBracket,
        holdDown = false,
        modifiers = {},
    },
    prevBackColor = {
        key = keys.leftBracket,
        holdDown = false,
        modifiers = {},
    },
    shiftDotsRight = {
        key = keys.right,
        holdDown = true,
        modifiers = {
            [keys.shift] = true
        }
    },
    shiftDotsLeft = {
        key = keys.left,
        holdDown = true,
        modifiers = {
            [keys.shift] = true
        }
    },
    shiftDotsUp = {
        key = keys.up,
        holdDown = true,
        modifiers = {
            [keys.shift] = true
        }
    },
    shiftDotsDown = {
        key = keys.down,
        holdDown = true,
        modifiers = {
            [keys.shift] = true
        }
    },
    toggleLayerMenu = {
        key = keys.l,
        holdDown = false,
        modifiers = {}
    }
}

Config.native_pallete = {
    [ 1 ] = {
        0.94117647409439,
        0.94117647409439,
        0.94117647409439,
    },
    [ 2 ] = {
        0.94901961088181,
        0.69803923368454,
        0.20000000298023,
    },
    [ 4 ] = {
        0.89803922176361,
        0.49803921580315,
        0.84705883264542,
    },
    [ 8 ] = {
        0.60000002384186,
        0.69803923368454,
        0.94901961088181,
    },
    [ 16 ] = {
        0.87058824300766,
        0.87058824300766,
        0.42352941632271,
    },
    [ 32 ] = {
        0.49803921580315,
        0.80000001192093,
        0.098039217293262,
    },
    [ 64 ] = {
        0.94901961088181,
        0.69803923368454,
        0.80000001192093,
    },
    [ 128 ] = {
        0.29803922772408,
        0.29803922772408,
        0.29803922772408,
    },
    [ 256 ] = {
        0.60000002384186,
        0.60000002384186,
        0.60000002384186,
    },
    [ 512 ] = {
        0.29803922772408,
        0.60000002384186,
        0.69803923368454,
    },
    [ 1024 ] = {
        0.69803923368454,
        0.40000000596046,
        0.89803922176361,
    },
    [ 2048 ] = {
        0.20000000298023,
        0.40000000596046,
        0.80000001192093,
    },
    [ 4096 ] = {
        0.49803921580315,
        0.40000000596046,
        0.29803922772408,
    },
    [ 8192 ] = {
        0.34117648005486,
        0.65098041296005,
        0.30588236451149,
    },
    [ 16384 ] = {
        0.80000001192093,
        0.29803922772408,
        0.29803922772408,
    },
    [ 32768 ] = {
        0.066666670143604,
        0.066666670143604,
        0.066666670143604,
    }
}

Config.checkControl = function(state, name, forceHoldDown)
    local modlist = {
        keys.ctrl,
        keys.shift,
        keys.alt,
    }
    for i = 1, #modlist do
        if Config.control[name].modifiers[modlist[i]] then
            if not state.keys_down[modlist[i]] then
                return false
            end
        else
            if state.keys_down[modlist[i]] and not Config.control[name].ignoreExtraModifiers then
                return false
            end
        end
    end
    if Config.control[name].key then
        if state.keys_down[Config.control[name].key] then
            local holdDown = Config.control[name].holdDown
            if forceHoldDown ~= nil then
                holdDown = forceHoldDown
            end
            if holdDown then
                return true
            else
                if not Config.control_hold_check[name] then
                    Config.control_hold_check[name] = true
                    return true
                end
            end
        else
            Config.control_hold_check[name] = false
            return false
        end
    end
end

return Config