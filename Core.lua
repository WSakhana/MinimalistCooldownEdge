-- Core.lua - Main functionality for MinimalistCooldownEdge

local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon

-- Apply custom style to a cooldown frame
local function ApplyCustomStyle(self)
    if not self then return end

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
    if edgeEnabled then
        self:SetDrawEdge(true)
        self:SetEdgeScale(edgeScale)
    else
        self:SetDrawEdge(false)
    end
    
    -- 2. Cooldown Timer Text Style
    self:SetHideCountdownNumbers(hideCountdown)
    
    local text = self:GetRegions() 
    if text and text:IsObjectType("FontString") then
        text:SetFont(font, fontSize, fontStyle)
        text:SetTextColor(textColor.r or textColor[1], textColor.g or textColor[2], textColor.b or textColor[3], textColor.a or textColor[4])
    end
end

-- Apply style to all visible cooldowns
function addon:ApplyAllCooldowns()
    -- Apply to action buttons
    for i = 1, 120 do
        local button = _G["ActionButton"..i]
        if button and button.cooldown then
            ApplyCustomStyle(button.cooldown)
        end
        
        -- MultiBar buttons
        button = _G["MultiBarBottomLeftButton"..i]
        if button and button.cooldown then
            ApplyCustomStyle(button.cooldown)
        end
        
        button = _G["MultiBarBottomRightButton"..i]
        if button and button.cooldown then
            ApplyCustomStyle(button.cooldown)
        end
        
        button = _G["MultiBarRightButton"..i]
        if button and button.cooldown then
            ApplyCustomStyle(button.cooldown)
        end
        
        button = _G["MultiBarLeftButton"..i]
        if button and button.cooldown then
            ApplyCustomStyle(button.cooldown)
        end
        
        button = _G["MultiBar5Button"..i]
        if button and button.cooldown then
            ApplyCustomStyle(button.cooldown)
        end
        
        button = _G["MultiBar6Button"..i]
        if button and button.cooldown then
            ApplyCustomStyle(button.cooldown)
        end
        
        button = _G["MultiBar7Button"..i]
        if button and button.cooldown then
            ApplyCustomStyle(button.cooldown)
        end
    end
end

-- Hook into action button updates
local function SetupHooks()
    -- Apply style as soon as cooldown is updated
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
        addon.Config:Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        SetupHooks()
        C_Timer.After(1, function()
            addon:ApplyAllCooldowns()
        end)
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)