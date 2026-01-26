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
    
    -- 1. Edge style
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
    
    -- Custom Font/Color Application
    local font = config:Get("font")
    local fontSize = config:Get("fontSize")
    local fontStyle = config:Get("fontStyle")
    local textColor = config:Get("textColor")

    local regions = {self:GetRegions()}
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" then
            region:SetFont(font, fontSize, fontStyle)
            if textColor then
                region:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
            end
        end
    end
end

local function SetupHooks()
    -- 1. GLOBAL HOOK: Catches Nameplates, Buffs, UnitFrames
    hooksecurefunc("CooldownFrame_Set", function(self)
        ApplyCustomStyle(self)
    end)
    
    if CooldownFrame_SetTimer then 
         hooksecurefunc("CooldownFrame_SetTimer", function(self)
            ApplyCustomStyle(self)
        end)
    end

    -- 2. ACTION BAR SPECIFIC HOOK: Mandatory for Blizzard Action Bars
    hooksecurefunc("ActionButton_UpdateCooldown", function(self)
        if self.cooldown then
            ApplyCustomStyle(self.cooldown)
        end
    end)

    -- 3. BARTENDER / LIBACTIONBUTTON COMPATIBILITY
    -- Bartender4 uses LibActionButton-1.0. We register a callback 
    -- to style buttons whenever the library updates them.
    if LibStub then
        local LAB = LibStub("LibActionButton-1.0", true)
        if LAB then
            LAB:RegisterCallback("OnButtonUpdate", function(_, button)
                if button.cooldown then
                    ApplyCustomStyle(button.cooldown)
                end
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
        
        -- Force a update on login for visible bars
        if ActionBarController_UpdateAll then
            ActionBarController_UpdateAll()
        end
    end
end)