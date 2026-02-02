-- Core.lua - Main functionality using Ace3

-- Initialize AceAddon
local addonName, addon = ...
local MCE = LibStub("AceAddon-3.0"):NewAddon(addon, "MinimalistCooldownEdge", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

-- === HARDCODED BLACKLIST ===
local hardcodedBlacklist = { "Glider", "Party", "Compact", "Raid", "VuhDo", "Grid" }

-- === OPTIMIZATION: CATEGORY CACHE ===
local categoryCache = setmetatable({}, { __mode = "k" })

-- === ACE ADDON LIFECYCLE ===
function MCE:OnInitialize()
    -- Use the V2 database
    self.db = LibStub("AceDB-3.0"):New("MinimalistCooldownEdgeDB_v2", self.defaults, true)

    -- Register Options Table
    LibStub("AceConfig-3.0"):RegisterOptionsTable("MinimalistCooldownEdge", self.GetOptions)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MinimalistCooldownEdge", "MinimalistCooldownEdge")

    -- Register Chat Command
    self:RegisterChatCommand("mce", "SlashCommand")
    self:RegisterChatCommand("minice", "SlashCommand")
    self:RegisterChatCommand("minimalistcooldownedge", "SlashCommand")
end

function MCE:OnEnable()
    self:SetupHooks()
    -- Delay initial update slightly to ensure UI is loaded
    C_Timer.After(2, function() self:ForceUpdateAll() end)
end

function MCE:SlashCommand(input)
    if InCombatLockdown() then
        self:Print("Cannot open options in combat.")
        return
    end
    LibStub("AceConfigDialog-3.0"):Open("MinimalistCooldownEdge")
end

-- === DETECTION LOGIC ===
function MCE:GetCooldownCategory(cooldownFrame)
    if categoryCache[cooldownFrame] then return categoryCache[cooldownFrame] end

    local current = cooldownFrame:GetParent()
    local depth = 0
    
    -- SAFELY retrieve scanDepth, defaulting to 10 if DB isn't ready
    local maxDepth = 10
    if self.db and self.db.profile then 
        maxDepth = self.db.profile.scanDepth 
    end

    -- CPU OPTIMIZATION: Fast Check
    local parentName = current and current:GetName() or ""
    if string.find(parentName, "BuffButton") or string.find(parentName, "DebuffButton") or string.find(parentName, "TempEnchant") then
        categoryCache[cooldownFrame] = "global" 
        return "global" 
    end
    
    local result = "global" 

    while current and current ~= UIParent and depth < maxDepth do
        local name = current:GetName() or ""
        local objType = current:GetObjectType()
        
        for _, blockedKey in ipairs(hardcodedBlacklist) do
            if string.find(name, blockedKey) then
                categoryCache[cooldownFrame] = "blacklist"
                return "blacklist"
            end
        end

        if objType == "NamePlate" or string.find(name, "NamePlate") or string.find(name, "Plater") or string.find(name, "Kui") or (current.unit and string.find(current.unit, "nameplate")) then
            result = "nameplate"; break
        end
        
        if string.find(name, "PlayerFrame") or string.find(name, "TargetFrame") or string.find(name, "FocusFrame") or string.find(name, "ElvUF") or string.find(name, "SUF") then
            result = "unitframe"; break
        end
        
        if (current.action and type(current.action) == "number") or (current.GetAttribute and current:GetAttribute("type")) or string.find(name, "Action") or string.find(name, "MultiBar") or string.find(name, "BT4") or string.find(name, "Dominos") then
             if not string.find(name, "Aura") then result = "actionbar"; break end
        end
        
        current = current:GetParent()
        depth = depth + 1
    end

    categoryCache[cooldownFrame] = result
    return result
end

-- === STACK COUNT STYLING ===
function MCE:StyleStackCount(cooldownFrame, config, category)
    if category ~= "actionbar" or not config.stackEnabled then return end

    local parent = cooldownFrame:GetParent()
    if not parent then return end
    local parentName = parent.GetName and parent:GetName()
    local countRegion = parent.Count or (parentName and _G[parentName.."Count"])

    if countRegion and countRegion.GetObjectType and countRegion:GetObjectType() == "FontString" then
        local safe, isForbidden = pcall(function() return countRegion:IsForbidden() end)
        if safe and not isForbidden then
            countRegion:SetFont(config.stackFont, config.stackSize, config.stackStyle)
            countRegion:SetTextColor(config.stackColor.r, config.stackColor.g, config.stackColor.b, config.stackColor.a)
            countRegion:ClearAllPoints()
            countRegion:SetPoint(config.stackAnchor, parent, config.stackAnchor, config.stackOffsetX, config.stackOffsetY)
            if countRegion.GetDrawLayer then countRegion:SetDrawLayer("OVERLAY", 7) end
        end
    end
end

-- === STYLE APPLICATION ===
function MCE:ApplyCustomStyle(self_frame)
    local safe, isForbidden = pcall(function() return not self_frame or self_frame:IsForbidden() end)
    if not safe or isForbidden then return end

    -- [CRITICAL FIX] GUARD CLAUSE
    if not self.db or not self.db.profile or not self.db.profile.categories then
        return
    end

    local category = self:GetCooldownCategory(self_frame)
    if category == "blacklist" then return end

    -- Retrieve settings from AceDB
    local config = self.db.profile.categories[category]
    
    -- [SAFETY] Ensure config exists for this category before proceeding
    if not config or not config.enabled then
        if self_frame.SetDrawEdge then pcall(function() self_frame:SetDrawEdge(false) end) end
        return 
    end
    
    self:StyleStackCount(self_frame, config, category)

    if self_frame.SetDrawEdge then
        pcall(function()
            if config.edgeEnabled then
                self_frame:SetDrawEdge(true)
                self_frame:SetEdgeScale(config.edgeScale)
            else
                self_frame:SetDrawEdge(false)
            end
        end)
    end
    
    if self_frame.SetHideCountdownNumbers then
        pcall(function() self_frame:SetHideCountdownNumbers(config.hideCountdownNumbers) end)
    end
    
    -- === FONT STRING STYLING & POSITIONING ===
    if self_frame.GetRegions then
        local regions = {self_frame:GetRegions()}
        for _, region in ipairs(regions) do
            if region:GetObjectType() == "FontString" and not region:IsForbidden() then
                -- 1. Apply Typography
                region:SetFont(config.font, config.fontSize, config.fontStyle)
                if config.textColor then
                    region:SetTextColor(config.textColor.r, config.textColor.g, config.textColor.b, config.textColor.a)
                end
                
                -- 2. Apply Positioning (New Feature)
                if config.textAnchor then
                    region:ClearAllPoints()
                    region:SetPoint(config.textAnchor, self_frame, config.textAnchor, config.textOffsetX, config.textOffsetY)
                end
            end
        end
    end
end

function MCE:ForceUpdateAll()
    local frame = EnumerateFrames()
    while frame do
        local safe, isForbidden = pcall(function() return frame:IsForbidden() end)
        if safe and not isForbidden then
            if frame:IsObjectType("Cooldown") then
                self:ApplyCustomStyle(frame)
            elseif frame.cooldown and type(frame.cooldown) == "table" then
                local safeCD, isForbiddenCD = pcall(function() return frame.cooldown:IsForbidden() end)
                if safeCD and not isForbiddenCD then
                    self:ApplyCustomStyle(frame.cooldown)
                end
            end
        end
        frame = EnumerateFrames(frame)
    end
end

function MCE:SetupHooks()
    hooksecurefunc("CooldownFrame_Set", function(f)
        C_Timer.After(0, function() MCE:ApplyCustomStyle(f) end)
    end)
    
    if CooldownFrame_SetTimer then 
         hooksecurefunc("CooldownFrame_SetTimer", function(f)
            C_Timer.After(0, function() MCE:ApplyCustomStyle(f) end)
        end)
    end

    if LibStub then
        local LAB = LibStub("LibActionButton-1.0", true)
        if LAB then
            LAB:RegisterCallback("OnButtonUpdate", function(_, button)
                C_Timer.After(0, function()
                    if button and button.cooldown then MCE:ApplyCustomStyle(button.cooldown) end
                end)
            end)
        end
    end
end