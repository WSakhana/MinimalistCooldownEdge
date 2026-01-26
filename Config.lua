-- Config.lua - Multi-Category Configuration Management

local addonName, addon = ...
addon.Config = {}

-- Definition of supported categories
addon.Categories = {
    "actionbar", -- Action Bars (Spells)
    "nameplate", -- Enemy Nameplates
    "unitframe", -- Unit Frames (Player/Target/Group)
    "global"     -- Everything else (Auras, Buffs, Bags, Items, etc.)
}

-- Default Style
local defaultStyle = {
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 18,
    fontStyle = "OUTLINE",
    textColor = { r = 1, g = 0.8, b = 0, a = 1 },
    edgeEnabled = true,
    edgeScale = 1.0,
    hideCountdownNumbers = false,
    scanDepth = 10, -- Performance setting (Global)
}

-- Utility function accessible globally
function addon.CopyTable(src, dest)
    if not dest then dest = {} end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = addon.CopyTable(v, dest[k])
        else
            dest[k] = v
        end
    end
    return dest
end

-- Function to retrieve defaults (used by GUI for resets)
function addon.Config:GetDefaultStyle()
    return defaultStyle
end

function addon.Config:Initialize()
    if not MinimalistCooldownEdgeDB then
        MinimalistCooldownEdgeDB = {}
    end
    
    for _, cat in ipairs(addon.Categories) do
        if not MinimalistCooldownEdgeDB[cat] then
            MinimalistCooldownEdgeDB[cat] = addon.CopyTable(defaultStyle)
            -- Specific default for nameplates to be smaller
            if cat == "nameplate" then MinimalistCooldownEdgeDB[cat].fontSize = 12 end
            if cat == "unitframe" then MinimalistCooldownEdgeDB[cat].fontSize = 12 end
        else
            -- Inject missing keys if config version changed
            for k, v in pairs(defaultStyle) do
                if MinimalistCooldownEdgeDB[cat][k] == nil then
                    MinimalistCooldownEdgeDB[cat][k] = v
                end
            end
        end
    end
end

function addon.Config:Get(key, category)
    category = category or "global"
    if not MinimalistCooldownEdgeDB[category] then category = "global" end
    
    if MinimalistCooldownEdgeDB and MinimalistCooldownEdgeDB[category] then
        return MinimalistCooldownEdgeDB[category][key]
    end
    return defaultStyle[key]
end

function addon.Config:Set(key, value, category)
    if not MinimalistCooldownEdgeDB then MinimalistCooldownEdgeDB = {} end
    category = category or "global"
    
    if not MinimalistCooldownEdgeDB[category] then
        MinimalistCooldownEdgeDB[category] = addon.CopyTable(defaultStyle)
    end
    
    MinimalistCooldownEdgeDB[category][key] = value
end

function addon.Config:Reset()
    MinimalistCooldownEdgeDB = {}
    self:Initialize()
end