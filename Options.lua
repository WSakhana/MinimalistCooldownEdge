local addonName, addon = ...
local MCE = LibStub("AceAddon-3.0"):GetAddon("MinimalistCooldownEdge")

-- Retrieve Version dynamically from TOC
local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or "Dev"

-- Shared Font Options
local fontOptions = {
    ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata",
    ["Fonts\\FRIZQT___CYR.TTF"] = "Friz Quadrata (Cyrillic)",
    ["Fonts\\ARIALN.TTF"] = "Arial Narrow",
    ["Fonts\\MORPHEUS.TTF"] = "Morpheus",
    ["Fonts\\skurri.ttf"] = "Skurri",
    ["Fonts\\2002.TTF"] = "2002",
    ["Interface\\AddOns\\MinimalistCooldownEdge\\expressway.ttf"] = "Expressway",
}

-- === DEFAULTS ===
local function GetCategoryDefaults(enabled, fontSize)
    return {
        enabled = enabled,
        font = "Interface\\AddOns\\MinimalistCooldownEdge\\expressway.ttf",
        fontSize = fontSize or 18,
        fontStyle = "OUTLINE",
        textColor = { r = 1, g = 0.8, b = 0, a = 1 },
        edgeEnabled = true,
        edgeScale = 1.0,
        hideCountdownNumbers = false,
        -- Stack Defaults
        stackEnabled = false,
        stackFont = "Interface\\AddOns\\MinimalistCooldownEdge\\expressway.ttf",
        stackSize = 14,
        stackStyle = "OUTLINE",
        stackColor = { r = 1, g = 1, b = 1, a = 1 },
        stackAnchor = "BOTTOMRIGHT",
        stackOffsetX = -2,
        stackOffsetY = 2,
    }
end

MCE.defaults = {
    profile = {
        scanDepth = 10, -- Global Setting
        categories = {
            actionbar = GetCategoryDefaults(true, 18),
            nameplate = GetCategoryDefaults(false, 12),
            unitframe = GetCategoryDefaults(false, 12),
            global    = GetCategoryDefaults(false, 18),
        }
    }
}

-- === OPTIONS BUILDER ===
local function CreateCategoryOptions(order, name, key)
    -- Helper to hide elements if the category is disabled
    local function IsDisabled()
        return not MCE.db.profile.categories[key].enabled
    end

    return {
        type = "group",
        name = name,
        order = order,
        args = {
            enabled = {
                type = "toggle",
                name = "Enable Category",
                order = 1,
                width = "full",
                get = function(info) return MCE.db.profile.categories[key].enabled end,
                set = function(info, val) 
                    MCE.db.profile.categories[key].enabled = val
                    MCE:ForceUpdateAll()
                end,
            },
            headerSettings = { 
                type = "header", 
                name = "Font & Style", 
                order = 10,
                hidden = IsDisabled 
            },
            font = {
                type = "select",
                name = "Font Face",
                order = 11,
                values = fontOptions,
                get = function(info) return MCE.db.profile.categories[key].font end,
                set = function(info, val) MCE.db.profile.categories[key].font = val; MCE:ForceUpdateAll() end,
                hidden = IsDisabled
            },
            fontSize = {
                type = "range",
                name = "Font Size",
                order = 12,
                min = 8, max = 36, step = 1,
                get = function(info) return MCE.db.profile.categories[key].fontSize end,
                set = function(info, val) MCE.db.profile.categories[key].fontSize = val; MCE:ForceUpdateAll() end,
                hidden = IsDisabled
            },
            fontStyle = {
                type = "select",
                name = "Outline",
                order = 13,
                values = { ["NONE"] = "None", ["OUTLINE"] = "Outline", ["THICKOUTLINE"] = "Thick", ["MONOCHROME"] = "Monochrome" },
                get = function(info) return MCE.db.profile.categories[key].fontStyle end,
                set = function(info, val) MCE.db.profile.categories[key].fontStyle = val; MCE:ForceUpdateAll() end,
                hidden = IsDisabled
            },
            textColor = {
                type = "color",
                name = "Text Color",
                order = 14,
                hasAlpha = true,
                get = function(info) 
                    local c = MCE.db.profile.categories[key].textColor
                    return c.r, c.g, c.b, c.a
                end,
                set = function(info, r, g, b, a)
                    local c = MCE.db.profile.categories[key].textColor
                    c.r, c.g, c.b, c.a = r, g, b, a
                    MCE:ForceUpdateAll()
                end,
                hidden = IsDisabled
            },
            headerEdge = { 
                type = "header", 
                name = "Swipe Edge", 
                order = 20,
                hidden = IsDisabled
            },
            edgeEnabled = {
                type = "toggle",
                name = "Enable Edge",
                order = 21,
                get = function(info) return MCE.db.profile.categories[key].edgeEnabled end,
                set = function(info, val) MCE.db.profile.categories[key].edgeEnabled = val; MCE:ForceUpdateAll() end,
                hidden = IsDisabled
            },
            edgeScale = {
                type = "range",
                name = "Edge Scale",
                desc = "Controls the thickness of the moving swipe edge.",
                order = 22,
                min = 0.5, max = 2.0, step = 0.1,
                get = function(info) return MCE.db.profile.categories[key].edgeScale end,
                set = function(info, val) MCE.db.profile.categories[key].edgeScale = val; MCE:ForceUpdateAll() end,
                hidden = IsDisabled
            },
            edgeScaleLegend = {
                type = "description",
                name = "|cff999999( < 1.0 = Thin | 1.0 = Default | > 1.0 = Thick )|r",
                order = 23,
                fontSize = "small",
                hidden = IsDisabled
            },
            stackGroup = (key == "actionbar") and {
                type = "group",
                name = "Stack Counts (Charges)",
                inline = true,
                order = 30,
                hidden = IsDisabled,
                args = {
                    stackEnabled = {
                        type = "toggle",
                        name = "Customize Stack Text",
                        order = 1,
                        get = function(info) return MCE.db.profile.categories[key].stackEnabled end,
                        set = function(info, val) MCE.db.profile.categories[key].stackEnabled = val; MCE:ForceUpdateAll() end,
                    },
                    stackFont = {
                        type = "select",
                        name = "Stack Font",
                        order = 2,
                        values = fontOptions,
                        get = function(info) return MCE.db.profile.categories[key].stackFont end,
                        set = function(info, val) MCE.db.profile.categories[key].stackFont = val; MCE:ForceUpdateAll() end,
                        hidden = function() return not MCE.db.profile.categories[key].stackEnabled end,
                    },
                    stackSize = {
                        type = "range",
                        name = "Stack Size",
                        order = 3,
                        min = 8, max = 36, step = 1,
                        get = function(info) return MCE.db.profile.categories[key].stackSize end,
                        set = function(info, val) MCE.db.profile.categories[key].stackSize = val; MCE:ForceUpdateAll() end,
                        hidden = function() return not MCE.db.profile.categories[key].stackEnabled end,
                    },
                    stackColor = {
                        type = "color",
                        name = "Stack Color",
                        order = 4,
                        hasAlpha = true,
                        get = function(info) 
                            local c = MCE.db.profile.categories[key].stackColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(info, r, g, b, a)
                            local c = MCE.db.profile.categories[key].stackColor
                            c.r, c.g, c.b, c.a = r, g, b, a
                            MCE:ForceUpdateAll()
                        end,
                        hidden = function() return not MCE.db.profile.categories[key].stackEnabled end,
                    },
                    stackAnchor = {
                        type = "select",
                        name = "Anchor",
                        order = 5,
                        values = {["BOTTOMRIGHT"]="Bottom Right", ["BOTTOMLEFT"]="Bottom Left", ["TOPRIGHT"]="Top Right", ["TOPLEFT"]="Top Left", ["CENTER"]="Center"},
                        get = function(info) return MCE.db.profile.categories[key].stackAnchor end,
                        set = function(info, val) MCE.db.profile.categories[key].stackAnchor = val; MCE:ForceUpdateAll() end,
                        hidden = function() return not MCE.db.profile.categories[key].stackEnabled end,
                    },
                    stackOffsetX = {
                        type = "range",
                        name = "Offset X",
                        order = 6,
                        min = -20, max = 20, step = 1,
                        get = function(info) return MCE.db.profile.categories[key].stackOffsetX end,
                        set = function(info, val) MCE.db.profile.categories[key].stackOffsetX = val; MCE:ForceUpdateAll() end,
                        hidden = function() return not MCE.db.profile.categories[key].stackEnabled end,
                    },
                    stackOffsetY = {
                        type = "range",
                        name = "Offset Y",
                        order = 7,
                        min = -20, max = 20, step = 1,
                        get = function(info) return MCE.db.profile.categories[key].stackOffsetY end,
                        set = function(info, val) MCE.db.profile.categories[key].stackOffsetY = val; MCE:ForceUpdateAll() end,
                        hidden = function() return not MCE.db.profile.categories[key].stackEnabled end,
                    },
                }
            } or nil,
            
            -- === RESET CATEGORY BUTTON ===
            -- Removed "Maintenance" Header
            -- Added Spacer for padding
            spacerReset = {
                type = "description",
                name = " ",
                fontSize = "medium",
                order = 90,
            },
            resetCategory = {
                type = "execute",
                name = "Reset Category", -- Renamed to "Reset Category"
                desc = "Reset settings for this category only.",
                order = 91,
                width = "full", -- Full width for better look
                confirm = true,
                func = function()
                    -- Deep copy from defaults to avoid reference issues
                    MCE.db.profile.categories[key] = CopyTable(MCE.defaults.profile.categories[key])
                    MCE:ForceUpdateAll()
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("MinimalistCooldownEdge")
                    print("|cff00ccffMCE:|r " .. name .. " settings reset.")
                end,
            },
        }
    }
end

function MCE:GetOptions()
    return {
        type = "group",
        name = "MiniCE",
        args = {
            general = {
                type = "group",
                name = "General Settings",
                order = 1,
                args = {
                    -- Header
                    headerInfo = {
                        type = "description",
                        name = "|cff00ccff" .. addonName .. "|r |cffffd100v" .. addonVersion .. "|r\n\n" ..
                               "Thank you for using MiniCE! If you enjoy this addon, please leave a comment or report issues on CurseForge/GitHub.",
                        fontSize = "medium",
                        order = 1,
                    },
                    -- Spacer 1
                    spacer1 = {
                        type = "description",
                        name = " ",
                        fontSize = "large",
                        order = 1.5,
                    },
                    scanDepth = {
                        type = "range",
                        name = "Scan Depth (CPU)",
                        desc = "Adjust detection depth. See guide below.",
                        min = 1, max = 20, step = 1,
                        order = 2,
                        get = function(info) return MCE.db.profile.scanDepth end,
                        set = function(info, val) 
                            MCE.db.profile.scanDepth = val
                            print("|cff00ff00MCE:|r Global Scan Depth changed. A /reload is recommended.")
                        end,
                    },
                    -- Spacer 2
                    spacer2 = {
                        type = "description",
                        name = " ",
                        fontSize = "medium",
                        order = 2.5,
                    },
                    -- Legend
                    scanDepthLegend = {
                        type = "description",
                        name = "Performance Impact:\n" ..
                               "|cff00ff00• < 10 : Efficient (Blizzard UI)|r\n" ..
                               "|cfffff569• 10-15 : Moderate (Bartender, Dominos)|r\n" ..
                               "|cffffa500• > 15 : High CPU (ElvUI, Plater, VuhDo)|r",
                        order = 3,
                        fontSize = "medium",
                    },
                    -- === RESET GLOBAL BUTTON ===
                    -- Removed "Maintenance" Header
                    -- Added Spacer
                    spacerGlobalReset = {
                        type = "description",
                        name = " ",
                        fontSize = "medium",
                        order = 90,
                    },
                    resetAll = {
                        type = "execute",
                        name = "Reset ALL Settings & Reload",
                        desc = "Resets the entire profile to default values and immediately reloads the UI.",
                        order = 91,
                        width = "full", -- [CHANGE] Forces button to take full width
                        confirm = true,
                        func = function() 
                            MCE.db:ResetProfile()
                            print("|cff00ccffMCE:|r Profile reset. Reloading UI...")
                            ReloadUI()
                        end,
                    },
                }
            },
            actionbar = CreateCategoryOptions(2, "Action Bars", "actionbar"),
            global    = CreateCategoryOptions(3, "Global & CD Manager", "global"),
            nameplate = CreateCategoryOptions(4, "Nameplates", "nameplate"),
            unitframe = CreateCategoryOptions(5, "Unit Frames", "unitframe"),
            
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(MCE.db),
        }
    }
end