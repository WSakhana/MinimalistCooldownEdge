local addonName, addon = ...
local MCE = LibStub("AceAddon-3.0"):GetAddon("MinimalistCooldownEdge")

-- Shared Font Options
local fontOptions = {
    ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata",
    ["Fonts\\FRIZQT___CYR.TTF"] = "Friz Quadrata (Cyrillic)",
    ["Fonts\\ARIALN.TTF"] = "Arial Narrow",
    ["Fonts\\MORPHEUS.TTF"] = "Morpheus",
    ["Fonts\\skurri.ttf"] = "Skurri",
    ["Fonts\\2002.TTF"] = "2002",
}

-- === DEFAULTS ===
-- We define a template for a single category to reuse code
local function GetCategoryDefaults(enabled, fontSize)
    return {
        enabled = enabled,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = fontSize or 18,
        fontStyle = "OUTLINE",
        textColor = { r = 1, g = 0.8, b = 0, a = 1 },
        edgeEnabled = true,
        edgeScale = 1.0,
        hideCountdownNumbers = false,
        -- Stack Defaults
        stackEnabled = false,
        stackFont = "Fonts\\FRIZQT__.TTF",
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
-- Helper to generate the options table for a specific category
local function CreateCategoryOptions(order, name, key)
    return {
        type = "group",
        name = name,
        order = order,
        args = {
            enabled = {
                type = "toggle",
                name = "Enable Category",
                order = 1,
                get = function(info) return MCE.db.profile.categories[key].enabled end,
                set = function(info, val) 
                    MCE.db.profile.categories[key].enabled = val
                    MCE:ForceUpdateAll()
                end,
            },
            headerSettings = { type = "header", name = "Font & Style", order = 10 },
            font = {
                type = "select",
                name = "Font Face",
                order = 11,
                values = fontOptions,
                get = function(info) return MCE.db.profile.categories[key].font end,
                set = function(info, val) MCE.db.profile.categories[key].font = val; MCE:ForceUpdateAll() end,
            },
            fontSize = {
                type = "range",
                name = "Font Size",
                order = 12,
                min = 8, max = 36, step = 1,
                get = function(info) return MCE.db.profile.categories[key].fontSize end,
                set = function(info, val) MCE.db.profile.categories[key].fontSize = val; MCE:ForceUpdateAll() end,
            },
            fontStyle = {
                type = "select",
                name = "Outline",
                order = 13,
                values = { ["NONE"] = "None", ["OUTLINE"] = "Outline", ["THICKOUTLINE"] = "Thick", ["MONOCHROME"] = "Monochrome" },
                get = function(info) return MCE.db.profile.categories[key].fontStyle end,
                set = function(info, val) MCE.db.profile.categories[key].fontStyle = val; MCE:ForceUpdateAll() end,
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
            },
            headerEdge = { type = "header", name = "Swipe Edge", order = 20 },
            edgeEnabled = {
                type = "toggle",
                name = "Enable Edge",
                order = 21,
                get = function(info) return MCE.db.profile.categories[key].edgeEnabled end,
                set = function(info, val) MCE.db.profile.categories[key].edgeEnabled = val; MCE:ForceUpdateAll() end,
            },
            edgeScale = {
                type = "range",
                name = "Edge Scale",
                order = 22,
                min = 0.5, max = 2.0, step = 0.1,
                get = function(info) return MCE.db.profile.categories[key].edgeScale end,
                set = function(info, val) MCE.db.profile.categories[key].edgeScale = val; MCE:ForceUpdateAll() end,
            },
            -- Include Stack Counts ONLY for Action Bar
            stackGroup = (key == "actionbar") and {
                type = "group",
                name = "Stack Counts (Charges)",
                inline = true,
                order = 30,
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
            } or nil
        }
    }
end

function MCE:GetOptions()
    return {
        type = "group",
        name = "MinimalistCooldownEdge",
        args = {
            general = {
                type = "group",
                name = "General & Global",
                order = 1,
                args = {
                    info = {
                        type = "description",
                        name = "Global settings affect detection and performance.",
                        order = 1,
                    },
                    scanDepth = {
                        type = "range",
                        name = "Scan Depth (CPU)",
                        desc = "How deep the addon searches for parent frames. Higher values (15-20) needed for complex UIs like ElvUI/Plater.",
                        min = 1, max = 20, step = 1,
                        order = 2,
                        get = function(info) return MCE.db.profile.scanDepth end,
                        set = function(info, val) 
                            MCE.db.profile.scanDepth = val
                            print("|cff00ff00MCE:|r Global Scan Depth changed. A /reload is recommended.")
                        end,
                    },
                    globalCategory = CreateCategoryOptions(10, "Global/Items Styles", "global")
                }
            },
            actionbar = CreateCategoryOptions(2, "Action Bars", "actionbar"),
            nameplate = CreateCategoryOptions(3, "Nameplates", "nameplate"),
            unitframe = CreateCategoryOptions(4, "Unit Frames", "unitframe"),
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(MCE.db),
        }
    }
end