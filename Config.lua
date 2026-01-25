-- Config.lua - Configuration Management for MinimalistCooldownEdge

local addonName, addon = ...
addon.Config = {}

-- Default configuration
addon.Defaults = {
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 18,
    fontStyle = "OUTLINE",
    textColor = { r = 1, g = 0.8, b = 0, a = 1 },
    
    edgeEnabled = true,
    edgeScale = 1.2,
    
    hideCountdownNumbers = false,
}

-- Initialize SavedVariables
function addon.Config:Initialize()
    if not MinimalistCooldownEdgeDB then
        MinimalistCooldownEdgeDB = {}
    end
    
    -- Deep copy defaults for any missing values
    for key, value in pairs(addon.Defaults) do
        if MinimalistCooldownEdgeDB[key] == nil then
            if type(value) == "table" then
                MinimalistCooldownEdgeDB[key] = {}
                for k, v in pairs(value) do
                    MinimalistCooldownEdgeDB[key][k] = v
                end
            else
                MinimalistCooldownEdgeDB[key] = value
            end
        end
    end
end

-- Get a config value
function addon.Config:Get(key)
    if MinimalistCooldownEdgeDB and MinimalistCooldownEdgeDB[key] ~= nil then
        return MinimalistCooldownEdgeDB[key]
    end
    return addon.Defaults[key]
end

-- Set a config value
function addon.Config:Set(key, value)
    if not MinimalistCooldownEdgeDB then
        MinimalistCooldownEdgeDB = {}
    end
    MinimalistCooldownEdgeDB[key] = value
end

-- Reset to defaults
function addon.Config:Reset()
    MinimalistCooldownEdgeDB = {}
    self:Initialize()
end
