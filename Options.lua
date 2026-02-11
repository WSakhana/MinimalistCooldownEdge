local addonName, addon = ...
local MCE = LibStub("AceAddon-3.0"):GetAddon("MinimalistCooldownEdge")
local L = LibStub("AceLocale-3.0"):GetLocale("MinimalistCooldownEdge")

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
        -- Typography Defaults
        font = "Interface\\AddOns\\MinimalistCooldownEdge\\expressway.ttf",
        fontSize = fontSize or 18,
        fontStyle = "OUTLINE",
        textColor = { r = 1, g = 0.8, b = 0, a = 1 },
        textAnchor = "CENTER",    -- NEW: Default Anchor
        textOffsetX = 0,          -- NEW: Default X
        textOffsetY = 0,          -- NEW: Default Y
        hideCountdownNumbers = false,
        
        -- Edge Defaults
        edgeEnabled = true,
        edgeScale = 1.4,
        
        -- Stack Defaults
        stackEnabled = true,
        stackFont = "Interface\\AddOns\\MinimalistCooldownEdge\\expressway.ttf",
        stackSize = 16,
        stackStyle = "OUTLINE",
        stackColor = { r = 1, g = 1, b = 1, a = 1 },
        stackAnchor = "BOTTOMRIGHT",
        stackOffsetX = -3,
        stackOffsetY = 3,
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

-- === HELPERS ===
local function IsCatDisabled(key)
    return not MCE.db.profile.categories[key].enabled
end

-- === OPTIONS BUILDER ===
local function CreateCategoryOptions(order, name, key)
    return {
        type = "group",
        name = name,
        order = order,
        args = {
            -- 1. Main Toggle
            enableGroup = {
                type = "group",
                name = L["State"],
                inline = true,
                order = 1,
                args = {
                    enabled = {
                        type = "toggle",
                        name = string.format(L["Enable %s"], name),
                        desc = L["Toggle styling for this category."],
                        width = "full",
                        order = 1,
                        get = function(info) return MCE.db.profile.categories[key].enabled end,
                        set = function(info, val) 
                            MCE.db.profile.categories[key].enabled = val
                            MCE:ForceUpdateAll()
                        end,
                    },
                },
            },

            -- 2. Typography Group (Inline for visual grouping)
            typography = {
                type = "group",
                name = L["Typography (Cooldown Numbers)"],
                inline = true,
                order = 10,
                disabled = function() return IsCatDisabled(key) end,
                args = {
                    font = {
                        type = "select",
                        name = L["Font Face"],
                        order = 1,
                        width = 1.5,
                        values = fontOptions,
                        get = function(info) return MCE.db.profile.categories[key].font end,
                        set = function(info, val) MCE.db.profile.categories[key].font = val; MCE:ForceUpdateAll() end,
                    },
                    fontSize = {
                        type = "range",
                        name = L["Size"],
                        order = 2,
                        width = 0.7,
                        min = 8, max = 36, step = 1,
                        get = function(info) return MCE.db.profile.categories[key].fontSize end,
                        set = function(info, val) MCE.db.profile.categories[key].fontSize = val; MCE:ForceUpdateAll() end,
                    },
                    fontStyle = {
                        type = "select",
                        name = L["Outline"],
                        order = 3,
                        width = 0.8,
                        values = { ["NONE"] = L["None"], ["OUTLINE"] = L["Outline"], ["THICKOUTLINE"] = L["Thick"], ["MONOCHROME"] = L["Mono"] },
                        get = function(info) return MCE.db.profile.categories[key].fontStyle end,
                        set = function(info, val) MCE.db.profile.categories[key].fontStyle = val; MCE:ForceUpdateAll() end,
                    },
                    textColor = {
                        type = "color",
                        name = L["Color"],
                        order = 4,
                        width = "half",
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
                    hideCountdownNumbers = {
                        type = "toggle",
                        name = L["Hide Numbers"],
                        desc = L["Hide the text entirely (useful if you only want the swipe edge or stacks)."],
                        order = 5,
                        width = "full",
                        get = function(info) return MCE.db.profile.categories[key].hideCountdownNumbers end,
                        set = function(info, val) MCE.db.profile.categories[key].hideCountdownNumbers = val; MCE:ForceUpdateAll() end,
                    },
                    -- NEW: Positioning Sub-Section
                    posHeader = { type = "header", name = L["Positioning"], order = 6 },
                    textAnchor = {
                        type = "select",
                        name = L["Anchor Point"],
                        order = 7,
                        values = {["BOTTOMRIGHT"]=L["Bottom Right"], ["BOTTOMLEFT"]=L["Bottom Left"], ["TOPRIGHT"]=L["Top Right"], ["TOPLEFT"]=L["Top Left"], ["CENTER"]=L["Center"]},
                        get = function(info) return MCE.db.profile.categories[key].textAnchor or "CENTER" end,
                        set = function(info, val) MCE.db.profile.categories[key].textAnchor = val; MCE:ForceUpdateAll() end,
                    },
                    textOffsetX = {
                        type = "range",
                        name = L["Offset X"],
                        order = 8,
                        width = "half",
                        min = -30, max = 30, step = 1,
                        get = function(info) return MCE.db.profile.categories[key].textOffsetX or 0 end,
                        set = function(info, val) MCE.db.profile.categories[key].textOffsetX = val; MCE:ForceUpdateAll() end,
                    },
                    textOffsetY = {
                        type = "range",
                        name = L["Offset Y"],
                        order = 9,
                        width = "half",
                        min = -30, max = 30, step = 1,
                        get = function(info) return MCE.db.profile.categories[key].textOffsetY or 0 end,
                        set = function(info, val) MCE.db.profile.categories[key].textOffsetY = val; MCE:ForceUpdateAll() end,
                    },
                }
            },

            -- 3. Swipe Edge Group
            swipeEdge = {
                type = "group",
                name = L["Swipe Animation"],
                inline = true,
                order = 20,
                disabled = function() return IsCatDisabled(key) end,
                args = {
                    edgeEnabled = {
                        type = "toggle",
                        name = L["Show Swipe Edge"],
                        desc = L["Shows the white line indicating cooldown progress."],
                        order = 1,
                        width = "normal",
                        get = function(info) return MCE.db.profile.categories[key].edgeEnabled end,
                        set = function(info, val) MCE.db.profile.categories[key].edgeEnabled = val; MCE:ForceUpdateAll() end,
                    },
                    edgeScale = {
                        type = "range",
                        name = L["Edge Thickness"],
                        desc = L["Scale of the swipe line (1.0 = Default)."],
                        order = 2,
                        min = 0.5, max = 2.0, step = 0.1,
                        get = function(info) return MCE.db.profile.categories[key].edgeScale end,
                        set = function(info, val) MCE.db.profile.categories[key].edgeScale = val; MCE:ForceUpdateAll() end,
                    },
                }
            },

            -- 4. Stack Counts (Conditional)
            stackGroup = (key == "actionbar") and {
                type = "group",
                name = L["Stack Counters / Charges"],
                inline = true,
                order = 30,
                disabled = function() return IsCatDisabled(key) end,
                args = {
                    stackEnabled = {
                        type = "toggle",
                        name = L["Customize Stack Text"],
                        desc = L["Take control over the charge counter (e.g., 2 stacks of Conflagrate)."],
                        order = 1,
                        width = "full",
                        get = function(info) return MCE.db.profile.categories[key].stackEnabled end,
                        set = function(info, val) MCE.db.profile.categories[key].stackEnabled = val; MCE:ForceUpdateAll() end,
                    },
                    -- Sub-section: Style
                    headerStyle = { type = "header", name = L["Style"], order = 10, hidden = function() return not MCE.db.profile.categories[key].stackEnabled end },
                    stackFont = {
                        type = "select",
                        name = L["Font"],
                        order = 11,
                        width = 1.5,
                        values = fontOptions,
                        get = function(info) return MCE.db.profile.categories[key].stackFont end,
                        set = function(info, val) MCE.db.profile.categories[key].stackFont = val; MCE:ForceUpdateAll() end,
                        hidden = function() return not MCE.db.profile.categories[key].stackEnabled end,
                    },
                    stackSize = {
                        type = "range",
                        name = L["Size"],
                        order = 12,
                        width = 0.7,
                        min = 8, max = 36, step = 1,
                        get = function(info) return MCE.db.profile.categories[key].stackSize end,
                        set = function(info, val) MCE.db.profile.categories[key].stackSize = val; MCE:ForceUpdateAll() end,
                        hidden = function() return not MCE.db.profile.categories[key].stackEnabled end,
                    },
                    stackColor = {
                        type = "color",
                        name = L["Color"],
                        order = 13,
                        width = 0.8,
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
                    -- Sub-section: Position
                    headerPos = { type = "header", name = L["Positioning"], order = 20, hidden = function() return not MCE.db.profile.categories[key].stackEnabled end },
                    stackAnchor = {
                        type = "select",
                        name = L["Anchor Point"],
                        order = 21,
                        values = {["BOTTOMRIGHT"]=L["Bottom Right"], ["BOTTOMLEFT"]=L["Bottom Left"], ["TOPRIGHT"]=L["Top Right"], ["TOPLEFT"]=L["Top Left"], ["CENTER"]=L["Center"]},
                        get = function(info) return MCE.db.profile.categories[key].stackAnchor end,
                        set = function(info, val) MCE.db.profile.categories[key].stackAnchor = val; MCE:ForceUpdateAll() end,
                        hidden = function() return not MCE.db.profile.categories[key].stackEnabled end,
                    },
                    stackOffsetX = {
                        type = "range",
                        name = L["Offset X"],
                        order = 22,
                        width = "half",
                        min = -20, max = 20, step = 1,
                        get = function(info) return MCE.db.profile.categories[key].stackOffsetX end,
                        set = function(info, val) MCE.db.profile.categories[key].stackOffsetX = val; MCE:ForceUpdateAll() end,
                        hidden = function() return not MCE.db.profile.categories[key].stackEnabled end,
                    },
                    stackOffsetY = {
                        type = "range",
                        name = L["Offset Y"],
                        order = 23,
                        width = "half",
                        min = -20, max = 20, step = 1,
                        get = function(info) return MCE.db.profile.categories[key].stackOffsetY end,
                        set = function(info, val) MCE.db.profile.categories[key].stackOffsetY = val; MCE:ForceUpdateAll() end,
                        hidden = function() return not MCE.db.profile.categories[key].stackEnabled end,
                    },
                }
            } or nil,
            
            -- 5. Maintenance (Reset)
            maintenance = {
                type = "group",
                name = L["Maintenance"],
                inline = true,
                order = 100,
                args = {
                    resetCategory = {
                        type = "execute",
                        name = string.format(L["Reset %s"], name), 
                        desc = L["Revert this category to default settings."],
                        order = 1,
                        width = "full", 
                        confirm = true,
                        func = function()
                            MCE.db.profile.categories[key] = CopyTable(MCE.defaults.profile.categories[key])
                            MCE:ForceUpdateAll()
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("MinimalistCooldownEdge")
                            print("|cff00ccffMCE:|r " .. string.format(L["%s settings reset."], name))
                        end,
                    },
                }
            }
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
                name = L["General"],
                order = 1,
                args = {
                    banner = {
                        type = "description",
                        name = "|cff00ccff" .. addonName .. "|r |cffffd100v" .. addonVersion .. "|r\n" ..
                               L["BANNER_DESC"],
                        fontSize = "medium",
                        image = "Interface\\AddOns\\MinimalistCooldownEdge\\MinimalistCooldownEdge",
                        imageWidth = 32, imageHeight = 32,
                        order = 1,
                    },
                    
                    -- Performance Section (Inline Group)
                    perfGroup = {
                        type = "group",
                        name = L["Performance & Detection"],
                        inline = true,
                        order = 2,
                        args = {
                            scanDepth = {
                                type = "range",
                                name = L["Scan Depth"],
                                desc = L["How deep the addon looks into UI frames to find cooldowns."],
                                min = 1, max = 20, step = 1,
                                order = 1,
                                width = "double",
                                get = function(info) return MCE.db.profile.scanDepth end,
                                set = function(info, val) 
                                    MCE.db.profile.scanDepth = val
                                    print("|cff00ff00MCE:|r " .. L["Global Scan Depth changed. A /reload is recommended."])
                                end,
                            },
                            helpText = {
                                type = "description",
                                name = L["SCAN_DEPTH_HELP"],
                                order = 2,
                                width = "full"
                            },
                        }
                    },

                    -- Reset Section
                    resetGroup = {
                        type = "group",
                        name = L["Danger Zone"],
                        inline = true,
                        order = 3,
                        args = {
                            resetAll = {
                                type = "execute",
                                name = L["Factory Reset (All)"],
                                desc = L["Resets the entire profile to default values and reloads the UI."],
                                order = 1,
                                width = "full",
                                confirm = true,
                                func = function() 
                                    MCE.db:ResetProfile()
                                    print("|cff00ccffMCE:|r " .. L["Profile reset. Reloading UI..."])
                                    ReloadUI()
                                end,
                            },
                        }
                    }
                }
            },
            actionbar = CreateCategoryOptions(2, L["Action Bars"], "actionbar"),
            nameplate = CreateCategoryOptions(3, L["Nameplates"], "nameplate"),
            unitframe = CreateCategoryOptions(4, L["Unit Frames"], "unitframe"),
            global    = CreateCategoryOptions(5, L["CD Manager & Others"], "global"),
            
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(MCE.db),
        }
    }
end