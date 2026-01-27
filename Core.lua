-- Core.lua - Main functionality and Detection Logic

local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon

-- === HARDCODED BLACKLIST ===
-- Add partial or full names of frames/addons to ignore here.
local hardcodedBlacklist = {
    "Glider",
    -- "RipWeakAuras", -- Example: Add this if you wanted to ignore WeakAuras
}

-- === OPTIMIZATION: CATEGORY CACHE ===
-- Weak keys allow the Garbage Collector to clean up frames that no longer exist
local categoryCache = setmetatable({}, { __mode = "k" })

-- === DETECTION LOGIC ===
local function GetCooldownCategory(cooldownFrame)
    -- 1. CACHE CHECK: If we already know this frame, return immediately (O(1))
    if categoryCache[cooldownFrame] then
        return categoryCache[cooldownFrame]
    end

    local current = cooldownFrame:GetParent()
    local depth = 0
    
    -- Retrieve max depth from Global config (default to 10 if not ready)
    local maxDepth = 10
    if addon.Config then
        maxDepth = addon.Config:Get("scanDepth", "global") or 10
    end
    
    -- CPU OPTIMIZATION: Fast Check for Standard Buttons
    local parentName = current and current:GetName() or ""
    if string.find(parentName, "BuffButton") or string.find(parentName, "DebuffButton") or string.find(parentName, "TempEnchant") then
        categoryCache[cooldownFrame] = "global" -- Store in cache
        return "global" 
    end
    
    local result = "global" -- Default fallback

    while current and current ~= UIParent and depth < maxDepth do
        local name = current:GetName() or ""
        local objType = current:GetObjectType()
        
        -- 0. BLACKLIST CHECK (New Priority)
        for _, blockedKey in ipairs(hardcodedBlacklist) do
            if string.find(name, blockedKey) then
                categoryCache[cooldownFrame] = "blacklist"
                return "blacklist"
            end
        end

        -- 1. NAMEPLATES
        if objType == "NamePlate" 
           or string.find(name, "NamePlate") 
           or string.find(name, "Plater") 
           or string.find(name, "Kui") 
           or (current.unit and string.find(current.unit, "nameplate")) then
            result = "nameplate"
            break
        end
        
        -- 2. UNIT FRAMES
        if string.find(name, "PlayerFrame") 
           or string.find(name, "TargetFrame") 
           or string.find(name, "FocusFrame") 
           or string.find(name, "Party") 
           or string.find(name, "CompactUnit") 
           or string.find(name, "ElvUF") 
           or string.find(name, "VuhDo") 
           or string.find(name, "SUF") 
           or string.find(name, "Grid") then
            result = "unitframe"
            break
        end
        
        -- 3. ACTION BARS
        if (current.action and type(current.action) == "number") 
           or (current.GetAttribute and current:GetAttribute("type")) 
           or string.find(name, "Action") 
           or string.find(name, "MultiBar") 
           or string.find(name, "BT4") 
           or string.find(name, "Dominos") then
             if not string.find(name, "Aura") then
                result = "actionbar"
                break
             end
        end
        
        current = current:GetParent()
        depth = depth + 1
    end

    -- Save result to cache before returning
    categoryCache[cooldownFrame] = result
    return result
end

-- === STYLE APPLICATION ===
function addon:ApplyCustomStyle(self)
    if not self or self:IsForbidden() then return end

    local config = addon.Config
    if not config then return end
    
    local category = GetCooldownCategory(self)

    -- [NEW] BLACKLIST CHECK
    if category == "blacklist" then
        return -- Do absolutely nothing for blacklisted frames
    end
    
    -- [NEW] GATEKEEPER: Check if category is enabled
    local isEnabled = config:Get("enabled", category)
    
    if not isEnabled then
        -- If disabled, ensure we clean up the edge and exit
        if self.SetDrawEdge then 
            pcall(function() self:SetDrawEdge(false) end) 
        end
        return 
    end
    
    -- Logic below only runs if Category is ENABLED
    local edgeEnabled = config:Get("edgeEnabled", category)
    local edgeScale = config:Get("edgeScale", category)
    local hideCountdown = config:Get("hideCountdownNumbers", category)
    
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
    
    if self.GetRegions then
        local font = config:Get("font", category)
        local fontSize = config:Get("fontSize", category)
        local fontStyle = config:Get("fontStyle", category)
        local textColor = config:Get("textColor", category)

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

function addon:ForceUpdateAll()
    local frame = EnumerateFrames()
    while frame do
        if frame.IsForbidden and not frame:IsForbidden() then
            if frame:IsObjectType("Cooldown") then
                addon:ApplyCustomStyle(frame)
            elseif frame.cooldown and frame.cooldown.IsForbidden and not frame.cooldown:IsForbidden() then
                addon:ApplyCustomStyle(frame.cooldown)
            end
        end
        frame = EnumerateFrames(frame)
    end
end

local function SetupHooks()
    hooksecurefunc("CooldownFrame_Set", function(self)
        if self and not self:IsForbidden() then
            C_Timer.After(0, function()
                if self and not self:IsForbidden() then addon:ApplyCustomStyle(self) end
            end)
        end
    end)
    
    if CooldownFrame_SetTimer then 
         hooksecurefunc("CooldownFrame_SetTimer", function(self)
            if self and not self:IsForbidden() then
                C_Timer.After(0, function()
                    if self and not self:IsForbidden() then addon:ApplyCustomStyle(self) end
                end)
            end
        end)
    end

    if LibStub then
        local LAB = LibStub("LibActionButton-1.0", true)
        if LAB then
            LAB:RegisterCallback("OnButtonUpdate", function(_, button)
                C_Timer.After(0, function()
                    if button and button.cooldown then addon:ApplyCustomStyle(button.cooldown) end
                end)
            end)
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        if addon.Config then addon.Config:Initialize() end
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        SetupHooks()
        C_Timer.After(2, function() addon:ForceUpdateAll() end)
    end
end)