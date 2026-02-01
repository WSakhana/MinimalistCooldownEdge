-- Core.lua - Main functionality and Detection Logic

local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon

-- === HARDCODED BLACKLIST ===
local hardcodedBlacklist = {
    "Glider",
    "Party",        -- Ignore Party Frames
    "Compact",      -- Ignore Blizzard Raid Frames
    "Raid",         -- Ignore General Raid Frames
    "VuhDo",        -- Ignore VuhDo Raid Frames
    "Grid",         -- Ignore Grid Raid Frames
}

-- === OPTIMIZATION: CATEGORY CACHE ===
local categoryCache = setmetatable({}, { __mode = "k" })

-- === DETECTION LOGIC ===
local function GetCooldownCategory(cooldownFrame)
    -- 1. CACHE CHECK: If we already know this frame, return immediately (O(1))
    if categoryCache[cooldownFrame] then
        return categoryCache[cooldownFrame]
    end

    local current = cooldownFrame:GetParent()
    local depth = 0
    
    local maxDepth = 10
    if addon.Config then
        maxDepth = addon.Config:Get("scanDepth", "global") or 10
    end
    
    -- CPU OPTIMIZATION: Fast Check for Standard Buttons
    local parentName = current and current:GetName() or ""
    if string.find(parentName, "BuffButton") or string.find(parentName, "DebuffButton") or string.find(parentName, "TempEnchant") then
        categoryCache[cooldownFrame] = "global" 
        return "global" 
    end
    
    local result = "global" -- Default fallback

    while current and current ~= UIParent and depth < maxDepth do
        local name = current:GetName() or ""
        local objType = current:GetObjectType()
        
        -- 0. BLACKLIST CHECK
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

    categoryCache[cooldownFrame] = result
    return result
end

-- === STACK COUNT STYLING ===
local function StyleStackCount(cooldownFrame, config, category)
    -- [RESTORED] Only apply to Action Bars to prevent crashes on other frames
    if category ~= "actionbar" or not config:Get("stackEnabled", category) then return end

    local parent = cooldownFrame:GetParent()
    if not parent then return end

    -- [SAFETY] Check name to avoid nil concatenation errors
    local parentName = parent.GetName and parent:GetName()

    -- Try to find the Count region
    local countRegion = parent.Count or (parentName and _G[parentName.."Count"])

    if countRegion and countRegion.GetObjectType and countRegion:GetObjectType() == "FontString" then
        local safe, isForbidden = pcall(function() return countRegion:IsForbidden() end)
        if safe and not isForbidden then
            
            local font = config:Get("stackFont", category)
            local size = config:Get("stackSize", category)
            local style = config:Get("stackStyle", category)
            local color = config:Get("stackColor", category)
            
            local anchor = config:Get("stackAnchor", category) or "BOTTOMRIGHT"
            local x = config:Get("stackOffsetX", category) or 0
            local y = config:Get("stackOffsetY", category) or 0

            -- Apply Font & Style
            countRegion:SetFont(font, size, style)
            
            -- Apply Color
            if color then
                countRegion:SetTextColor(color.r, color.g, color.b, color.a)
            end

            -- Apply Position
            countRegion:ClearAllPoints()
            countRegion:SetPoint(anchor, parent, anchor, x, y)
            
            -- Ensure visibility over swipe
            if countRegion.GetDrawLayer then
                countRegion:SetDrawLayer("OVERLAY", 7) 
            end
        end
    end
end

-- === STYLE APPLICATION ===
function addon:ApplyCustomStyle(self)
    local safe, isForbidden = pcall(function() return not self or self:IsForbidden() end)
    if not safe or isForbidden then return end

    local config = addon.Config
    if not config then return end
    
    local category = GetCooldownCategory(self)

    if category == "blacklist" then return end
    
    local isEnabled = config:Get("enabled", category)
    if not isEnabled then
        if self.SetDrawEdge then pcall(function() self:SetDrawEdge(false) end) end
        return 
    end
    
    -- [RESTORED] Apply Stack Count Styles (Action Bar Only inside the function)
    StyleStackCount(self, config, category)

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
        local safe, isForbidden = pcall(function() return frame:IsForbidden() end)
        
        if safe and not isForbidden then
            if frame:IsObjectType("Cooldown") then
                addon:ApplyCustomStyle(frame)
            elseif frame.cooldown and type(frame.cooldown) == "table" then
                local safeCD, isForbiddenCD = pcall(function() return frame.cooldown:IsForbidden() end)
                if safeCD and not isForbiddenCD then
                    addon:ApplyCustomStyle(frame.cooldown)
                end
            end
        end
        frame = EnumerateFrames(frame)
    end
end

local function SetupHooks()
    hooksecurefunc("CooldownFrame_Set", function(self)
        local safe, isForbidden = pcall(function() return self:IsForbidden() end)
        if safe and not isForbidden then
            C_Timer.After(0, function()
                local safeT, isForbiddenT = pcall(function() return self:IsForbidden() end)
                if safeT and not isForbiddenT then addon:ApplyCustomStyle(self) end
            end)
        end
    end)
    
    if CooldownFrame_SetTimer then 
         hooksecurefunc("CooldownFrame_SetTimer", function(self)
            local safe, isForbidden = pcall(function() return self:IsForbidden() end)
            if safe and not isForbidden then
                C_Timer.After(0, function()
                    local safeT, isForbiddenT = pcall(function() return self:IsForbidden() end)
                    if safeT and not isForbiddenT then addon:ApplyCustomStyle(self) end
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