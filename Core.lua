-- Core.lua - Main functionality for MinimalistCooldownEdge

local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon

-- Apply custom style to a cooldown frame
function addon:ApplyCustomStyle(self)
    -- 1. SECURITY CHECK
    if not self or self:IsForbidden() then return end

    local config = addon.Config
    if not config then return end
    
    -- Get settings
    local edgeEnabled = config:Get("edgeEnabled")
    local edgeScale = config:Get("edgeScale")
    local hideCountdown = config:Get("hideCountdownNumbers")
    
    -- Use pcall for safety against transient protection
    if self.SetDrawEdge then
        pcall(function()
            if edgeEnabled then
                self:SetDrawEdge(true)
                self:SetEdgeScale(edgeScale)
            else
                self:SetDrawEdge(false)
            end
        end)
    end
    
    if self.SetHideCountdownNumbers then
        pcall(function() self:SetHideCountdownNumbers(hideCountdown) end)
    end
    
    -- Font/Color Application
    if self.GetRegions then
        local font = config:Get("font")
        local fontSize = config:Get("fontSize")
        local fontStyle = config:Get("fontStyle")
        local textColor = config:Get("textColor")

        local regions = {self:GetRegions()}
        for _, region in ipairs(regions) do
            if region:GetObjectType() == "FontString" and not region:IsForbidden() then
                region:SetFont(font, fontSize, fontStyle)
                if textColor then
                    region:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
                end
            end
        end
    end
end

-- Helper to safely refresh all visible cooldowns manually
-- This replaces ActionBarController_UpdateAll which causes Taint/Blocks
function addon:ForceUpdateAll()
    local frame = EnumerateFrames()
    while frame do
        if frame.IsForbidden and not frame:IsForbidden() then
            -- Check for Cooldown object directly
            if frame:IsObjectType("Cooldown") then
                addon:ApplyCustomStyle(frame)
            -- Check for buttons that have a .cooldown property
            elseif frame.cooldown and frame.cooldown.IsForbidden and not frame.cooldown:IsForbidden() then
                addon:ApplyCustomStyle(frame.cooldown)
            end
        end
        frame = EnumerateFrames(frame)
    end
end

local function SetupHooks()
    -- 1. GENERIC COOLDOWN HOOK (Safe)
    hooksecurefunc("CooldownFrame_Set", function(self)
        if self and not self:IsForbidden() then
            C_Timer.After(0, function()
                if self and not self:IsForbidden() then
                    addon:ApplyCustomStyle(self)
                end
            end)
        end
    end)
    
    -- 2. TIMER HOOK (Safe)
    if CooldownFrame_SetTimer then 
         hooksecurefunc("CooldownFrame_SetTimer", function(self)
            if self and not self:IsForbidden() then
                C_Timer.After(0, function()
                    if self and not self:IsForbidden() then
                        addon:ApplyCustomStyle(self)
                    end
                end)
            end
        end)
    end

    -- 3. BARTENDER / LIBACTIONBUTTON COMPATIBILITY
    if LibStub then
        local LAB = LibStub("LibActionButton-1.0", true)
        if LAB then
            LAB:RegisterCallback("OnButtonUpdate", function(_, button)
                C_Timer.After(0, function()
                    if button and button.cooldown then
                        addon:ApplyCustomStyle(button.cooldown)
                    end
                end)
            end)
        end
    end
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
        
        -- Force a visual refresh on login WITHOUT triggering StanceBar Taint
        C_Timer.After(2, function()
            addon:ForceUpdateAll()
        end)
    end
end)