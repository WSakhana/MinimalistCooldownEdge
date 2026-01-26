-- Core.lua - Main functionality for MinimalistCooldownEdge

local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon

-- Apply custom style to a cooldown frame
local function ApplyCustomStyle(self)
    if not self or self:IsForbidden() then return end

    local config = addon.Config
    if not config then return end
    
    -- Get settings
    local edgeEnabled = config:Get("edgeEnabled")
    local edgeScale = config:Get("edgeScale")
    local hideCountdown = config:Get("hideCountdownNumbers")
    local font = config:Get("font")
    local fontSize = config:Get("fontSize")
    local fontStyle = config:Get("fontStyle")
    local textColor = config:Get("textColor")

    -- 1. Edge style
    -- Check if the method exists to be safe on all frame types
    if self.SetDrawEdge then
        if edgeEnabled then
            self:SetDrawEdge(true)
            self:SetEdgeScale(edgeScale)
        else
            self:SetDrawEdge(false)
        end
    end
    
    -- 2. Cooldown Timer Text Style
    if self.SetHideCountdownNumbers then
        self:SetHideCountdownNumbers(hideCountdown)
    end
    
    -- Iterate regions to find the timer text (works for both ActionBars and WA)
    local regions = {self:GetRegions()}
    for _, region in ipairs(regions) do
        if region:IsObjectType("FontString") then
            region:SetFont(font, fontSize, fontStyle)
            if textColor then
                region:SetTextColor(textColor.r or textColor[1], textColor.g or textColor[2], textColor.b or textColor[3], textColor.a or textColor[4])
            end
        end
    end
end

-- Hook into updates
local function SetupHooks()
    -- 1. GLOBAL HOOK: Catches WeakAuras, Nameplates, Buffs, UnitFrames
    hooksecurefunc("CooldownFrame_Set", function(self)
        ApplyCustomStyle(self)
    end)
    
    if CooldownFrame_SetTimer then 
         hooksecurefunc("CooldownFrame_SetTimer", function(self)
            ApplyCustomStyle(self)
        end)
    end

    -- 2. ACTION BAR SPECIFIC HOOK: Mandatory for Blizzard Action Bars
    -- Action Bars use a specific update function that sometimes bypasses the global setter visually
    hooksecurefunc("ActionButton_UpdateCooldown", function(self)
        if self.cooldown then
            ApplyCustomStyle(self.cooldown)
        end
    end)
end

-- Initialize addon
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        if addon.Config then
            addon.Config:Initialize()
        end
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        SetupHooks()
        
        -- Force a one-time update on visible Action Bars on login
        -- This fixes buttons that are already on CD when you log in
        if ActionBarController_UpdateAll then
            ActionBarController_UpdateAll()
        end

        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)